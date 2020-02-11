include vars.mk

## CHECK IF REQUIRED EXECUTABLES ARE PRESENT ON THE MACHINE
#  Raise an error and stop make before executing rules
REQUIRED_EXECUTABLES := curl kubectl yq envsubst
CAN_RUN := $(foreach exec,$(REQUIRED_EXECUTABLES), \
	$(if $(shell which $(exec)), "$(exec) found", $(error "The tool $(exec) cannot be found in PATH")) \
)


OVERLAY ?= docker-desktop

.PHONY: \
	get-strimzi init-strimzi remove-strimzi \
	get-ECK     init-ECK     remove-ECK \
	get-jaeger  init-jaeger  remove-jaeger \
	get-prometheus init-prometheus remove-prometheus \
	get-istio   init-istio   remove-istio \
	get-operators install-operators configure-operators \
	wipe purge


all: \
	install-operators \
	configure-operators


DOWNLOADED_OPERATORS :=
OPERATOR_INSTALL_TARGETS :=
OPERATOR_REMOVAL_TARGETS :=


## `get-strimzi` Downloads Strimzy-Operator installation procedure for Kubernetes
##               these files are removed when the `purge` target is executed
get-strimzi: _init/strimzi-operator
DOWNLOADED_OPERATORS += _init/strimzi-operator
_init/strimzi-operator:
	@echo "Downloading Strimzi version $(STRIMZI_VERSION)"
	@mkdir -p ./$@
	@curl --silent --location \
		"https://github.com/strimzi/strimzi-kafka-operator/releases/download/$(STRIMZI_VERSION)/strimzi-$(STRIMZI_VERSION).tar.gz" \
	| tar --extract --gzip --directory="$@" --strip-components=1 --exclude=docs/
	@echo "Done !"


## `init-strimzi` Installs the Strimzi-Operator in the Target Kubernetes Cluster, as well as
##                strimzi CRDs and RBAC. It does not instanciate any Kafka broker nor zookeeper.
##                Operator, CRDs & RBAC are removed with `remove-strimzi`.
OPERATOR_INSTALL_TARGETS += init-strimzi
init-strimzi: _init/strimzi-operator
	@-kubectl create namespace $(STRIMZI_OPERATOR_NS)
	@echo "Changing namespace references in YAML files."
	@sed -i 's/namespace: .*/namespace: $(STRIMZI_OPERATOR_NS)/' $</install/cluster-operator/*RoleBinding*.yaml
	@yq delete --inplace \
		'$</install/cluster-operator/050-Deployment-strimzi-cluster-operator.yaml' \
		'spec.template.spec.containers[0].env[0].valueFrom'
	@yq write --inplace \
		'$</install/cluster-operator/050-Deployment-strimzi-cluster-operator.yaml' \
		'spec.template.spec.containers[0].env[0].value' "*"
	@echo "Done !"
	@kubectl apply -f '$</install/cluster-operator/' -n $(STRIMZI_OPERATOR_NS)
	@-kubectl create clusterrolebinding strimzi-cluster-operator-namespaced                 \
		--clusterrole=strimzi-cluster-operator-namespaced --serviceaccount $(STRIMZI_OPERATOR_NS):strimzi-cluster-operator
	@-kubectl create clusterrolebinding strimzi-cluster-operator-entity-operator-delegation \
		--clusterrole=strimzi-entity-operator --serviceaccount $(STRIMZI_OPERATOR_NS):strimzi-cluster-operator
	@-kubectl create clusterrolebinding strimzi-cluster-operator-topic-operator-delegation  \
		--clusterrole=strimzi-topic-operator --serviceaccount $(STRIMZI_OPERATOR_NS):strimzi-cluster-operator
	@kubectl wait 'deployment/strimzi-cluster-operator' --for=condition=available --timeout=300s -n $(STRIMZI_OPERATOR_NS)


## `remove-strimzi` Deletes the Cluster Operator Deployment, the strimzi CRD and RBAC
OPERATOR_REMOVAL_TARGETS += remove-strimzi
remove-strimzi: _init/strimzi-operator
	@-kubectl delete -f '$</install/cluster-operator/' -n $(STRIMZI_OPERATOR_NS)
	@-kubectl delete namespace $(STRIMZI_OPERATOR_NS)


## `get-ECK` Downloads the Elastic Cloud Kubernetes Operator into the ECK folder.
##           It does not instanciate any Elastic Operator nor Elasticsearch cluster.
get-ECK: _init/ECK-operator
DOWNLOADED_OPERATORS += _init/ECK-operator
_init/ECK-operator:
	@mkdir -p $@
	@echo "Downloading Elastic Cloud Kubernetes operator"
	@curl --silent \
		https://download.elastic.co/downloads/eck/$(ECK_VERSION)/all-in-one.yaml \
		> $@/all-in-one.yaml
	@echo "Done !"


## `init-ECK` Instanciate in the Kubernetes Cluster the Elastic Cloud Kubernetes Operator.
##            The Operator will be instanciated in its own namespace: "elastic-system"
##            operator need to communicate with ES API so adding it to the Data-Plane
##            Ref: https://github.com/elastic/cloud-on-k8s/issues/2064#issuecomment-547903913
OPERATOR_INSTALL_TARGETS += init-ECK
init-ECK: _init/ECK-operator
	@kubectl apply -f $</all-in-one.yaml
	@sleep 5
	@kubectl wait 'pod/elastic-operator-0' --for=condition=Ready --timeout=300s -n elastic-system


## `remove-ECK` Removes the Elasctic Cloud Kubernetes Operator frome the cluster,
##              However the ECK directory is not removed.
OPERATOR_REMOVAL_TARGETS += remove-ECK
remove-ECK: _init/ECK-operator
	@-kubectl delete -f $</all-in-one.yaml


## `get-jaeger` 
get-jaeger: _init/jaeger-operator
DOWNLOADED_OPERATORS += _init/jaeger-operator
_init/jaeger-operator:
	@mkdir -p $@
	@echo "Downloading Jaeger Operator"
	@curl --silent \
		https://raw.githubusercontent.com/jaegertracing/jaeger-operator/$(JAEGER_OPERATOR_VERSION)/deploy/crds/jaegertracing.io_jaegers_crd.yaml \
		> $@/jaegertracing.io_jaegers_crd.yaml
	@curl --silent \
		https://raw.githubusercontent.com/jaegertracing/jaeger-operator/$(JAEGER_OPERATOR_VERSION)/deploy/service_account.yaml \
		> $@/service_account.yaml
	@curl --silent \
		https://raw.githubusercontent.com/jaegertracing/jaeger-operator/$(JAEGER_OPERATOR_VERSION)/deploy/role.yaml \
		> $@/role.yaml
	@curl --silent \
		https://raw.githubusercontent.com/jaegertracing/jaeger-operator/$(JAEGER_OPERATOR_VERSION)/deploy/role_binding.yaml \
		> $@/role_binding.yaml
	@curl --silent \
		https://raw.githubusercontent.com/jaegertracing/jaeger-operator/$(JAEGER_OPERATOR_VERSION)/deploy/operator.yaml \
		> $@/operator.yaml
	@echo "Done !"
	@echo "Changing namespace references in YAML files."
	@sed -i 's/namespace: .*/namespace: $(JAEGER_OPERATOR_NS)/' $@/service_account.yaml
	@sed -i 's/namespace: .*/namespace: $(JAEGER_OPERATOR_NS)/' $@/role.yaml
	@sed -i 's/namespace: .*/namespace: $(JAEGER_OPERATOR_NS)/' $@/role_binding.yaml
	@sed -i 's/namespace: .*/namespace: $(JAEGER_OPERATOR_NS)/' $@/operator.yaml
	@echo "Done !"


OPERATOR_INSTALL_TARGETS += init-jaeger
init-jaeger: _init/jaeger-operator
	@-kubectl create namespace $(JAEGER_OPERATOR_NS)
	@kubectl apply -f $</jaegertracing.io_jaegers_crd.yaml
	@kubectl apply -f $</service_account.yaml
	@kubectl apply -f $</role.yaml
	@kubectl apply -f $</role_binding.yaml
	@kubectl apply -f $</operator.yaml
	@kubectl wait 'deployment/jaeger-operator' --for=condition=available --timeout=300s -n $(JAEGER_OPERATOR_NS)


OPERATOR_REMOVAL_TARGETS += remove-jaeger
remove-jaeger: _init/jaeger-operator
	@-kubectl delete -f $</operator.yaml
	@-kubectl delete -f $</role_binding.yaml
	@-kubectl delete -f $</role.yaml
	@-kubectl delete -f $</service_account.yaml
	@-kubectl delete -f $</jaegertracing.io_jaegers_crd.yaml
	@-kubectl delete namespace $(JAEGER_OPERATOR_NS)


get-prometheus: _init/prometheus-operator
DOWNLOADED_OPERATORS += _init/prometheus-operator
_init/prometheus-operator:
	@mkdir -p $@
	@echo "Downloading CoreOS Prometheus Operator"
	@curl --silent \
		https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/rbac/prometheus-operator/prometheus-operator-deployment.yaml \
		> $@/prometheus-operator-deployment.yaml
	@curl --silent \
		https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/rbac/prometheus-operator/prometheus-operator-cluster-role.yaml \
		> $@/prometheus-operator-cluster-role.yaml
	@curl --silent \
		https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/rbac/prometheus-operator/prometheus-operator-cluster-role-binding.yaml \
		> $@/prometheus-operator-cluster-role-binding.yaml
	@curl --silent \
		https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/rbac/prometheus-operator/prometheus-operator-service-account.yaml \
		> $@/prometheus-operator-service-account.yaml
	@echo "Done !"
	@echo "Changing namespace references in YAML files."
	@sed -i 's/namespace: .*/namespace: $(PROM_OPERATOR_NS)/' $@/prometheus-operator-deployment.yaml
	@sed -i 's/namespace: .*/namespace: $(PROM_OPERATOR_NS)/' $@/prometheus-operator-cluster-role-binding.yaml
	@sed -i 's/namespace: .*/namespace: $(PROM_OPERATOR_NS)/' $@/prometheus-operator-service-account.yaml
	@echo "Done !"


OPERATOR_INSTALL_TARGETS += init-prometheus
init-prometheus: _init/prometheus-operator
	@-kubectl create namespace $(PROM_OPERATOR_NS)
	@kubectl apply -f $</prometheus-operator-deployment.yaml
	@kubectl apply -f $</prometheus-operator-cluster-role.yaml
	@kubectl apply -f $</prometheus-operator-cluster-role-binding.yaml
	@kubectl apply -f $</prometheus-operator-service-account.yaml


OPERATOR_REMOVAL_TARGETS += remove-prometheus
remove-prometheus: _init/prometheus-operator
	@echo "Removing Prometheus Operator ..."
	@-kubectl delete -f $</prometheus-operator-service-account.yaml
	@-kubectl delete -f $</prometheus-operator-cluster-role-binding.yaml
	@-kubectl delete -f $</prometheus-operator-cluster-role.yaml
	@-kubectl delete -f $</prometheus-operator-deployment.yaml
	@-kubectl delete namespace $(PROM_OPERATOR_NS)
	@echo "Done !"


get-otel: _init/otel-operator
DOWNLOADED_OPERATORS += _init/otel-operator
_init/otel-operator:
	@mkdir -p "$@"
	@echo "Downloading OpenTelemetry Operator"
	@curl --silent \
		https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/master/deploy/crds/opentelemetry.io_opentelemetrycollectors_crd.yaml \
		> $@/opentelemetry.io_opentelemetrycollectors_crd.yaml
	@curl --silent \
		https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/master/deploy/service_account.yaml \
		> $@/service_account.yaml
	@curl --silent \
		https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/master/deploy/role.yaml \
		> $@/role.yaml
	@curl --silent \
		https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/master/deploy/role_binding.yaml \
		> $@/role_binding.yaml
	@curl --silent \
		https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/master/deploy/operator.yaml \
		> $@/operator.yaml
	@echo "Done !"


OPERATOR_INSTALL_TARGETS += init-otel
init-otel: _init/otel-operator
	@-kubectl create namespace monitoring-stack
	@kubectl apply -n monitoring-stack -f $</opentelemetry.io_opentelemetrycollectors_crd.yaml
	@kubectl apply -n monitoring-stack -f $</service_account.yaml
	@kubectl apply -n monitoring-stack -f $</role.yaml
	@kubectl apply -n monitoring-stack -f $</role_binding.yaml
	@kubectl apply -n monitoring-stack -f $</operator.yaml


OPERATOR_REMOVAL_TARGETS += remove-otel
remove-otel: _init/otel-operator
	@echo "Removing OpenTelemetry Operator ..."
	@-kubectl delete -n monitoring-stack -f $</opentelemetry.io_opentelemetrycollectors_crd.yaml
	@-kubectl delete -n monitoring-stack -f $</service_account.yaml
	@-kubectl delete -n monitoring-stack -f $</role.yaml
	@-kubectl delete -n monitoring-stack -f $</role_binding.yaml
	@-kubectl delete -n monitoring-stack -f $</operator.yaml
	@echo "Done !"


get-istio: _init/istio-$(ISTIO_VERSION)/
DOWNLOADED_OPERATORS += _init/istio-$(ISTIO_VERSION)/
_init/istio-$(ISTIO_VERSION)/:
	@cd _init/ && ISTIO_VERSION="$(ISTIO_VERSION)" curl -L https://istio.io/downloadIstio | sh -

ISTIOCTL := $(realpath _init)/istio-$(ISTIO_VERSION)/bin/istioctl


OPERATOR_INSTALL_TARGETS += init-istio
init-istio: controlplane.yml
	$(ISTIOCTL) manifest apply -f $<
	@echo "Waiting for istio components pilot and citadel to be ready"
	@kubectl wait 'deployment/istio-pilot'   --for=condition=available --timeout=300s -n istio-system
	@kubectl wait 'deployment/istio-citadel' --for=condition=available --timeout=300s -n istio-system
	@echo "Applying custom loadbalancer for the ingress gateway"
	@kubectl apply -n istio-system -f ingressgateway-lb.yml


OPERATOR_REMOVAL_TARGETS += remove-istio
remove-istio: controlplane.yml
	@-$(ISTIOCTL) manifest generate -f $< | kubectl delete -f -


########------------------------------------------------------------------------------########

get-operators: $(DOWNLOADED_OPERATORS)


install-operators: $(OPERATOR_INSTALL_TARGETS)


wipe: $(OPERATOR_REMOVAL_TARGETS)
	@-kubectl wait 'deployment/istio-policy'  --for=condition=terminated --timeout=300s -n istio-system
	@-kubectl wait 'deployment/istio-citadel' --for=condition=terminated --timeout=300s -n istio-system

purge:
	@-rm -rf $(DOWNLOADED_OPERATORS)
