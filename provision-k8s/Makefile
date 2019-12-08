include vars.mk

## CHECK IF REQUIRED EXECUTABLES ARE PRESENT ON THE MACHINE
#  Raise an error and stop make before executing rules
REQUIRED_EXECUTABLES := curl kubectl yq envsubst
CAN_RUN := $(foreach exec,$(REQUIRED_EXECUTABLES), \
	$(if $(shell which $(exec)), "$(exec) found", $(error "The tool $(exec) cannot be found in PATH")) \
)

.PHONY: configure-init install-operators install-components\
	setup-neo4j remove-neo4j \
	get-strimzi init-strimzi remove-strimzi setup-kafka-cluster   remove-kafka-cluster   setup-kafka-topic remove-kafka-topic setup-kafka-tools remove-kafka-tools \
	get-ECK     init-ECK     remove-ECK     setup-elastic-cluster remove-elastic-cluster setup-es-auth-secret \
	get-prometheus init-prometheus remove-prometheus \
	get-linkerd init-linkerd remove-linkerd \
	wipe purge


all: \
	install-operators \
	install-components


DOWNLOADED_OPERATORS :=
OPERATOR_INSTALL_TARGETS :=
OPERATOR_REMOVAL_TARGETS :=
COMPONENT_INSTALL_TARGETS :=
COMPONENT_REMOVAL_TARGETS :=


## `configure-init` Lists actions to be done on a new Kubernetes Cluster
configure-init:
	@echo "Eventually creating Namespace: $(APPLICATION_NS)"
	@-kubectl create namespace $(APPLICATION_NS)


COMPONENT_INSTALL_TARGETS += setup-neo4j
setup-neo4j: neo4j.yml configure-init
	@kubectl apply -f $< -n $(APPLICATION_NS)


COMPONENT_REMOVAL_TARGETS += remove-neo4j
remove-neo4j: neo4j.yml
	@-kubectl delete -f $< -n $(APPLICATION_NS)


## `get-strimzi` Downloads Strimzy-Operator installation procedure for Kubernetes
##               these files are removed when the `purge` target is executed
get-strimzi: operators/strimzi
DOWNLOADED_OPERATORS += operators/strimzi
operators/strimzi:
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
init-strimzi: operators/strimzi configure-init
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
remove-strimzi: operators/strimzi
	@-kubectl delete -f '$</install/cluster-operator'
	@-kubectl delete namespace $(STRIMZI_OPERATOR_NS)


## `setup-kafka-cluster`
COMPONENT_INSTALL_TARGETS += setup-kafka-cluster
setup-kafka-cluster: kafka-cluster.yml
	@kubectl apply -n $(APPLICATION_NS) -f $<


## `remove-kafka-cluster`
COMPONENT_REMOVAL_TARGETS += remove-kafka-cluster
remove-kafka-cluster: kafka-cluster.yml
	@-kubectl delete -n $(APPLICATION_NS) -f $<


## `setup-kafka-topic` Creates the Kafka Topics that will be used by the Application
setup-kafka-topic: kafka-topic.yml setup-kafka-cluster
	@kubectl wait 'kafka/$(shell yq read $< 'metadata.labels.['strimzi.io/cluster']')' \
		--for=condition=Ready --timeout=300s -n $(APPLICATION_NS)
	@kubectl apply -n $(APPLICATION_NS) -f $<


## `remove-kafka-topic`
remove-kafka-topic: kafka-topic.yml
	@-kubectl delete -n $(APPLICATION_NS) -f $<


## `setup-kafka-tools` deploy Tools to better inspect data hosted in the Tracing Kafka Cluster
COMPONENT_INSTALL_TARGETS += setup-kafka-tools
setup-kafka-tools: kafka-tools.yml setup-kafka-cluster
	@kubectl wait 'kafka/tracing-cluster' \
		--for=condition=Ready --timeout=300s -n $(APPLICATION_NS)
	@kubectl apply -n $(APPLICATION_NS) -f $<


## `remove-kafka-tools`
COMPONENT_REMOVAL_TARGETS += remove-kafka-tools
remove-kafka-tools: kafka-tools.yml
	@-kubectl delete -n $(APPLICATION_NS) -f $<


## `get-ECK` Downloads the Elastic Cloud Kubernetes Operator into the ECK folder.
##           It does not instanciate any Elastic Operator nor Elasticsearch cluster.
get-ECK: operators/ECK
DOWNLOADED_OPERATORS += operators/ECK
operators/ECK:
	@mkdir -p $@
	@echo "Downloading Elastic Cloud Kubernetes operator"
	@curl --silent \
		https://download.elastic.co/downloads/eck/$(ECK_VERSION)/all-in-one.yaml \
		> $@/all-in-one.yaml
	@echo "Done !"


## `init-ECK` Instanciate in the Kubernetes Cluster the Elastic Cloud Kubernetes Operator.
##            The Operator will be instanciated in its own namespace: "elastic-system"
OPERATOR_INSTALL_TARGETS += init-ECK
init-ECK: operators/ECK
	@kubectl apply -f $</all-in-one.yaml


## `remove-ECK` Removes the Elasctic Cloud Kubernetes Operator frome the cluster,
##              However the ECK directory is not removed.
OPERATOR_REMOVAL_TARGETS += remove-ECK
remove-ECK: operators/ECK
	@-kubectl delete -f $</all-in-one.yaml


## `setup-elastic-cluster` Use ECK to instanciate an Elasticsearch cluster that will
##                         be used by jaeger as storage backend.
COMPONENT_INSTALL_TARGETS += setup-elastic-cluster
setup-elastic-cluster: elasticsearch-cluster.yml configure-init
	@kubectl apply -f $< -n $(APPLICATION_NS)
	@sleep 30
	@kubectl wait 'pod/jaeger-tracing-backend-es-default-0' \
		--for=condition=Ready --timeout=300s -n $(APPLICATION_NS)


## `elasticsearch-auth.yml` is the secret that hosts environment variables that will be used
##                          by Jaeger components to reach its backend storage. It is used to store
##                          ElasticSearch cluster authentication parametters.
##                          This Target does not pushes the secret to the ES cluster, see `setup-es-auth-secret`
elasticsearch-auth.yml: ES_USERNAME = elastic
elasticsearch-auth.yml: elasticsearch-auth.yml.tmpl setup-elastic-cluster
	@ES_USERNAME_B64="$(shell printf '$(ES_USERNAME)' | base64)" \
	ES_PASSWORD_B64="$(shell kubectl -n $(APPLICATION_NS) get secret jaeger-tracing-backend-es-elastic-user -o go-template='{{.data.elastic}}')" \
	envsubst < $< > $@
	@printf 'ElasticSearch Cluster auth\nUser: %s\nPassword: %s\n----\n' "$(ES_USERNAME)" "$(shell kubectl -n $(APPLICATION_NS) get secret jaeger-tracing-backend-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')"


## `remove-elastic-cluster` Removes the Jaeger Backend Storage but still leaves the Operator
##                          Installed in the cluster.
COMPONENT_REMOVAL_TARGETS += remove-elastic-cluster
remove-elastic-cluster: elasticsearch-cluster.yml
	@-kubectl delete -f $< -n $(APPLICATION_NS)
	@rm -rf "elasticsearch-auth.yml"


## `setup-es-auth-secret`: Applies the secret generated by `elasticsearch-auth.yml` to the k8s Cluster
setup-es-auth-secret: elasticsearch-auth.yml
	@kubectl apply -n $(APPLICATION_NS) -f $<


## `get-jaeger` 
get-jaeger: operators/jaeger
DOWNLOADED_OPERATORS += operators/jaeger
operators/jaeger:
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
init-jaeger: operators/jaeger configure-init
	@-kubectl create namespace $(JAEGER_OPERATOR_NS)
	@kubectl apply -f $</jaegertracing.io_jaegers_crd.yaml
	@kubectl apply -f $</service_account.yaml
	@kubectl apply -f $</role.yaml
	@kubectl apply -f $</role_binding.yaml
	@kubectl apply -f $</operator.yaml


OPERATOR_REMOVAL_TARGETS += remove-jaeger
remove-jaeger: operators/jaeger
	@-kubectl delete -f $</operator.yaml
	@-kubectl delete -f $</role_binding.yaml
	@-kubectl delete -f $</role.yaml
	@-kubectl delete -f $</service_account.yaml
	@-kubectl delete -f $</jaegertracing.io_jaegers_crd.yaml
	@-kubectl delete namespace $(JAEGER_OPERATOR_NS)


COMPONENT_INSTALL_TARGETS += setup-jaeger-stack
setup-jaeger-stack: jaeger-streaming.yml setup-es-auth-secret setup-kafka-topic
	@kubectl apply -n $(APPLICATION_NS) -f $<


COMPONENT_REMOVAL_TARGETS += remove-jaeger-stack
remove-jaeger-stack: jaeger-streaming.yml
	@-kubectl delete -n $(APPLICATION_NS) -f $<


get-prometheus: operators/prometheus
DOWNLOADED_OPERATORS += operators/prometheus
operators/prometheus:
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
init-prometheus: operators/prometheus
	@-kubectl create namespace $(PROM_OPERATOR_NS)
	@kubectl apply -f $</prometheus-operator-deployment.yaml
	@kubectl apply -f $</prometheus-operator-cluster-role.yaml
	@kubectl apply -f $</prometheus-operator-cluster-role-binding.yaml
	@kubectl apply -f $</prometheus-operator-service-account.yaml


OPERATOR_REMOVAL_TARGETS += remove-prometheus
remove-prometheus: operators/prometheus
	@echo "Removing Prometheus Operator ..."
	@-kubectl delete -f $</prometheus-operator-service-account.yaml
	@-kubectl delete -f $</prometheus-operator-cluster-role-binding.yaml
	@-kubectl delete -f $</prometheus-operator-cluster-role.yaml
	@-kubectl delete -f $</prometheus-operator-deployment.yaml
	@-kubectl delete namespace $(PROM_OPERATOR_NS)
	@echo "Done !"


## `get-linkerd` created the linkerd directory which has linkerd clients binaries
##               it uses standard installation procedure but in the target directory
##               these binaries are removed when the `purge` target is executed
get-linkerd: linkerd
DOWNLOADED_OPERATORS += linkerd
linkerd:
	@echo "Downloading and installing Linkerd Client version $(LINKERD2_VERSION)"
	@mkdir -p ./$@
	@curl --silent --location "https://run.linkerd.io/install" \
		| LINKERD2_VERSION="$(LINKERD2_VERSION)" INSTALLROOT="$(shell pwd)/$@" sh > /dev/null
	@echo "Done !"
LINKERD := $(shell pwd)/linkerd/bin/linkerd


init-linkerd: linkerd
	$(LINKERD) install --ignore-cluster | kubectl apply -f -
	$(LINKERD) check
	kubectl -n linkerd get deploy


OPERATOR_REMOVAL_TARGETS += remove-linkerd
remove-linkerd:
	@-$(LINKERD) install --ignore-cluster | kubectl delete -f -


########------------------------------------------------------------------------------########


install-operators: $(OPERATOR_INSTALL_TARGETS)


install-components: $(COMPONENT_INSTALL_TARGETS)


gg: wipe # Alias for fun ...
wipe: $(COMPONENT_REMOVAL_TARGETS)
	@-kubectl delete namespace $(APPLICATION_NS)


purge: wipe $(OPERATOR_REMOVAL_TARGETS)
	rm -rf $(DOWNLOADED_OPERATORS)
