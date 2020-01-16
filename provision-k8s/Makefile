include vars.mk

## CHECK IF REQUIRED EXECUTABLES ARE PRESENT ON THE MACHINE
#  Raise an error and stop make before executing rules
REQUIRED_EXECUTABLES := curl kubectl yq envsubst
CAN_RUN := $(foreach exec,$(REQUIRED_EXECUTABLES), \
	$(if $(shell which $(exec)), "$(exec) found", $(error "The tool $(exec) cannot be found in PATH")) \
)

.PHONY: configure-init \
	get-strimzi init-strimzi remove-strimzi \
	get-ECK     init-ECK     remove-ECK \
	get-jaeger  init-jaeger  remove-jaeger \
	get-istio   init-istio   remove-istio \
	wait-for-es setup-es-auth-secret \
	get-operators install-operators install-components remove-components \
	wipe purge


all: \
	install-operators \
	wait-for-es \
	setup-es-auth-secret \
	install-components


DOWNLOADED_OPERATORS :=
OPERATOR_INSTALL_TARGETS :=
OPERATOR_REMOVAL_TARGETS :=


## `configure-init` Lists actions to be done on a new Kubernetes Cluster
configure-init:
	@echo "Eventually creating Namespace: $(APPLICATION_NS) $(ELASTIC_STACK_NS) and $(JAEGER_STACK_NS)"
	@-kubectl create namespace "$(APPLICATION_NS)"
	@-kubectl create namespace "$(ELASTIC_STACK_NS)"
	@-kubectl create namespace "$(JAEGER_STACK_NS)"


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
init-jaeger: _init/jaeger-operator configure-init
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


get-istio: _init/istio-$(ISTIO_VERSION)/
DOWNLOADED_OPERATORS += _init/istio-$(ISTIO_VERSION)/
_init/istio-$(ISTIO_VERSION)/:
	@cd _init/ && ISTIO_VERSION="$(ISTIO_VERSION)" curl -L https://istio.io/downloadIstio | sh -

ISTIOCTL := $(realpath _init)/istio-$(ISTIO_VERSION)/bin/istioctl


bases/istio-system-custom/generated_manifest/istio-manifest.yaml: get-istio
	@rm -rf '$@'
	$(ISTIOCTL) manifest generate \
		--set profile=default \
		--set telemetry.enabled=false \
		--set values.gateways.istio-ingressgateway.enabled=true \
		--set values.global.tracer.zipkin.address="jaeger-streaming-collector.$(JAEGER_STACK_NS).svc.cluster.local:9411" \
		--set values.pilot.traceSampling=100 \
	> $@


OPERATOR_INSTALL_TARGETS += init-istio
init-istio: bases/istio-system-custom/generated_manifest/istio-manifest.yaml
	@kubectl apply -f $<
	@kubectl wait 'deployment/istio-pilot' --for=condition=available --timeout=300s -n istio-system


OPERATOR_REMOVAL_TARGETS += remove-istio
remove-istio: bases/istio-system-custom/generated_manifest/istio-manifest.yaml
	@-kubectl delete -f $<


wait-for-es: init-ECK
	@kubectl wait 'pod/jaeger-tracing-backend-es-default-0' \
		--for=condition=Ready --timeout=300s -n "$(JAEGER_STACK_NS)"


## `elasticsearch-auth.yml` is the secret that hosts environment variables that will be used
##                          by Jaeger components to reach its backend storage. It is used to store
##                          ElasticSearch cluster authentication parametters.
##                          This Target does not pushes the secret to the ES cluster, see `setup-es-auth-secret`
elasticsearch-auth.yml: ES_USERNAME = elastic
elasticsearch-auth.yml: elasticsearch-auth.yml.tmpl wait-for-es
	@ES_USERNAME_B64="$(shell printf '$(ES_USERNAME)' | base64)" \
	ES_PASSWORD_B64="$(shell kubectl -n "$(JAEGER_STACK_NS)" get secret jaeger-tracing-backend-es-elastic-user -o go-template='{{.data.elastic}}')" \
	envsubst < $< > $@
	@printf 'ElasticSearch Cluster auth\nUser: %s\nPassword: %s\n----\n' "$(ES_USERNAME)" "$(shell kubectl -n "$(JAEGER_STACK_NS)" get secret jaeger-tracing-backend-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')"


## `setup-es-auth-secret`: Applies the secret generated by `elasticsearch-auth.yml` to the k8s Cluster
setup-es-auth-secret: elasticsearch-auth.yml
	@kubectl apply -n "$(JAEGER_STACK_NS)" -f $<


########------------------------------------------------------------------------------########

get-operators: $(DOWNLOADED_OPERATORS)


install-operators: $(OPERATOR_INSTALL_TARGETS)


install-components: configure-init
	@kubectl apply -k ./overlays/$(OVERLAY)
	@make setup-es-auth-secret


gg: remove-components # Alias for fun ...
remove-components:
	@-kubectl delete -k ./overlays/$(OVERLAY)
	@-kubectl delete -f ./elasticsearch-auth.yml -n $(APPLICATION_NS)
	@-rm -rf ./elasticsearch-auth.yml
	@-kubectl delete namespace $(APPLICATION_NS)


wipe: remove-components $(OPERATOR_REMOVAL_TARGETS)
	kubectl wait 'deployment/istio-policy'  --for=condition=terminated --timeout=300s -n istio-system
	kubectl wait 'deployment/istio-citadel' --for=condition=terminated --timeout=300s -n istio-system

purge:
	@-rm -rf $(DOWNLOADED_OPERATORS)