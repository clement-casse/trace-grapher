include vars.mk

## CHECK IF REQUIRED EXECUTABLES ARE PRESENT ON THE MACHINE
#  Raise an error and stop make before executing rules
REQUIRED_EXECUTABLES := curl kubectl yq envsubst
CAN_RUN := $(foreach exec,$(REQUIRED_EXECUTABLES), \
	$(if $(shell which $(exec)), "$(exec) found", $(error "The tool $(exec) cannot be found in PATH")) \
)

.PHONY: configure-init install-operators install-components \
	get-nginxIngress init-nginxIngress remove-nginxIngress \
	get-strimzi init-strimzi remove-strimzi \
	get-ECK     init-ECK     remove-ECK setup-es-auth-secret \
	get-prometheus init-prometheus remove-prometheus \
	get-linkerd init-linkerd remove-linkerd \
	wipe purge


all: \
	install-operators \
	install-components


DOWNLOADED_OPERATORS :=
OPERATOR_INSTALL_TARGETS :=
OPERATOR_REMOVAL_TARGETS :=


## `configure-init` Lists actions to be done on a new Kubernetes Cluster
configure-init:
	@echo "Eventually creating Namespace: $(APPLICATION_NS)"
	@-kubectl create namespace $(APPLICATION_NS)


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
init-strimzi: _init/strimzi-operator configure-init
	@-kubectl create namespace $(STRIMZI_OPERATOR_NS)
	@echo "Changing namespace references in YAML files."
	@sed -i '' 's/namespace: .*/namespace: $(STRIMZI_OPERATOR_NS)/' $</install/cluster-operator/*RoleBinding*.yaml
	@yq delete --inplace \
		'$</install/cluster-operator/050-Deployment-strimzi-cluster-operator.yaml' \
		'spec.template.spec.containers[0].env[0].valueFrom'
	@yq write --inplace \
		'$</install/cluster-operator/050-Deployment-strimzi-cluster-operator.yaml' \
		'spec.template.spec.containers[0].env[0].value' $(APPLICATION_NS)
	@echo "Done !"
	@kubectl apply -f '$</install/cluster-operator/' -n $(STRIMZI_OPERATOR_NS)
	@kubectl apply -f '$</install/cluster-operator/020-RoleBinding-strimzi-cluster-operator.yaml' -n $(APPLICATION_NS)
	@kubectl apply -f '$</install/cluster-operator/032-RoleBinding-strimzi-cluster-operator-topic-operator-delegation.yaml' -n $(APPLICATION_NS)
	@kubectl apply -f '$</install/cluster-operator/031-RoleBinding-strimzi-cluster-operator-entity-operator-delegation.yaml' -n $(APPLICATION_NS)


## `remove-strimzi` Deletes the Cluster Operator Deployment, the strimzi CRD and RBAC
OPERATOR_REMOVAL_TARGETS += remove-strimzi
remove-strimzi: _init/strimzi-operator
	@-kubectl delete -f '$</install/cluster-operator'
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
OPERATOR_INSTALL_TARGETS += init-ECK
init-ECK: _init/ECK-operator
	@kubectl apply -f $</all-in-one.yaml


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
	@sed -i '' 's/namespace: .*/namespace: $(JAEGER_OPERATOR_NS)/' $@/service_account.yaml
	@sed -i '' 's/namespace: .*/namespace: $(JAEGER_OPERATOR_NS)/' $@/role.yaml
	@sed -i '' 's/namespace: .*/namespace: $(JAEGER_OPERATOR_NS)/' $@/role_binding.yaml
	@sed -i '' 's/namespace: .*/namespace: $(JAEGER_OPERATOR_NS)/' $@/operator.yaml
	@echo "Done !"


OPERATOR_INSTALL_TARGETS += init-jaeger
init-jaeger: _init/jaeger-operator configure-init
	@-kubectl create namespace $(JAEGER_OPERATOR_NS)
	@kubectl apply -f $</jaegertracing.io_jaegers_crd.yaml
	@kubectl apply -f $</service_account.yaml
	@kubectl apply -f $</role.yaml
	@kubectl apply -f $</role_binding.yaml
	@kubectl apply -f $</operator.yaml


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
	@sed -i '' 's/namespace: .*/namespace: $(PROM_OPERATOR_NS)/' $@/prometheus-operator-deployment.yaml
	@sed -i '' 's/namespace: .*/namespace: $(PROM_OPERATOR_NS)/' $@/prometheus-operator-cluster-role-binding.yaml
	@sed -i '' 's/namespace: .*/namespace: $(PROM_OPERATOR_NS)/' $@/prometheus-operator-service-account.yaml
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



get-istio: _init/istio-$(ISTIO_VERSION)/
DOWNLOADED_OPERATORS += _init/istio-$(ISTIO_VERSION)/
_init/istio-$(ISTIO_VERSION)/:
	@cd _init/ && ISTIO_VERSION="$(ISTIO_VERSION)" curl -L https://istio.io/downloadIstio | sh -

ISTIOCTL := $(shell cd _init/istio-$(ISTIO_VERSION)/bin/ && pwd)/istioctl


init-istio: _init/istio-manifest.yaml
OPERATOR_INSTALL_TARGETS += init-istio
_init/istio-manifest.yaml:
	$(ISTIOCTL) manifest apply --set profile=default
	$(ISTIOCTL) manifest generate --set profile=default > $@


OPERATOR_REMOVAL_TARGETS += remove-istio
remove-istio: _init/istio-manifest.yaml
	@-kubectl delete -f $<


## `elasticsearch-auth.yml` is the secret that hosts environment variables that will be used
##                          by Jaeger components to reach its backend storage. It is used to store
##                          ElasticSearch cluster authentication parametters.
##                          This Target does not pushes the secret to the ES cluster, see `setup-es-auth-secret`
elasticsearch-auth.yml: ES_USERNAME = elastic
elasticsearch-auth.yml: elasticsearch-auth.yml.tmpl
	@kubectl wait 'pod/jaeger-tracing-backend-es-default-0' \
		--for=condition=Ready --timeout=300s -n $(APPLICATION_NS)
	@ES_USERNAME_B64="$(shell printf '$(ES_USERNAME)' | base64)" \
	ES_PASSWORD_B64="$(shell kubectl -n $(APPLICATION_NS) get secret jaeger-tracing-backend-es-elastic-user -o go-template='{{.data.elastic}}')" \
	envsubst < $< > $@
	@printf 'ElasticSearch Cluster auth\nUser: %s\nPassword: %s\n----\n' "$(ES_USERNAME)" "$(shell kubectl -n $(APPLICATION_NS) get secret jaeger-tracing-backend-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')"


## `setup-es-auth-secret`: Applies the secret generated by `elasticsearch-auth.yml` to the k8s Cluster
setup-es-auth-secret: elasticsearch-auth.yml
	@kubectl apply -n $(APPLICATION_NS) -f $<


########------------------------------------------------------------------------------########

get-operators: $(DOWNLOADED_OPERATORS)


install-operators: $(OPERATOR_INSTALL_TARGETS)


install-components: configure-init
	@kubectl apply -k ./overlays/$(OVERLAY)
	make setup-es-auth-secret


gg: remove-components # Alias for fun ...
remove-components:
	@-kubectl delete -k ./overlays/$(OVERLAY)
	@-kubectl delete -f ./elasticsearch-auth.yml -n $(APPLICATION_NS)
	@-rm -rf ./elasticsearch-auth.yml
	@-kubectl delete namespace $(APPLICATION_NS)


wipe: remove-components $(OPERATOR_REMOVAL_TARGETS)

purge:
	@-rm -rf $(DOWNLOADED_OPERATORS)