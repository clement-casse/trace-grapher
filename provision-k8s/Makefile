include vars.mk

## CHECK IF REQUIRED EXECUTABLES ARE PRESENT ON THE MACHINE
#  Raise an error and stop make before executing rules
REQUIRED_EXECUTABLES := curl kubectl yq
CAN_RUN := $(foreach exec,$(REQUIRED_EXECUTABLES), \
	$(if $(shell which $(exec)), "$(exec) found", $(error "The tool $(exec) cannot be found in PATH")) \
)

DOWNLOADED_COMPONENTS :=

.PHONY: configure-init \
	get-strimzi init-strimzi setup-kafka-cluster \
	get-jaeger init-jaeger remove-jaeger \
	get-prometheus init-prometheus remove-prometheus \
	get-linkerd init-linkerd remove-linkerd \
	wipe purge

## `configure-init` Lists actions to be done on a new Kubernetes Cluster
configure-init:
	kubectl create namespace $(APPLICATION_NS) || echo "$(APPLICATION_NS) Already exists"


## `get-strimzi` Downloads Strimzy-Operator installation procedure for Kubernetes
##               these files are removed when the `purge` target is executed
get-strimzi: strimzi
DOWNLOADED_COMPONENTS += strimzi
strimzi:
	@echo "Downloading Strimzi version $(STRIMZI_VERSION)"
	@mkdir -p ./$@
	@curl --silent --location \
		"https://github.com/strimzi/strimzi-kafka-operator/releases/download/$(STRIMZI_VERSION)/strimzi-$(STRIMZI_VERSION).tar.gz" \
	| tar --extract --gzip --directory="$@" --strip-components=1 --exclude=docs/
	@echo "Done !"
	@echo "Changing namespace references in YAML files."
	@sed -i '' 's/namespace: .*/namespace: $(STRIMZI_OPERATOR_NS)/' $@/install/cluster-operator/*RoleBinding*.yaml
	@yq delete --inplace \
		'$@/install/cluster-operator/050-Deployment-strimzi-cluster-operator.yaml' \
		'spec.template.spec.containers[0].env[0].valueFrom'
	@yq write --inplace \
		'$@/install/cluster-operator/050-Deployment-strimzi-cluster-operator.yaml' \
		'spec.template.spec.containers[0].env[0].value' $(APPLICATION_NS)
	@echo "Done !"


## `init-strimzi` Installs the Strimzi-Operator in the Target Kubernetes Cluster, as well as
##                strimzi CRDs and RBAC. It does not instanciate any Kafka broker nor zookeeper.
##                Operator, CRDs & RBAC are removed with `remove-strimzi`.
init-strimzi: strimzi configure-init
	@kubectl create namespace $(STRIMZI_OPERATOR_NS) || echo "$(STRIMZI_OPERATOR_NS) Already exists"
	@kubectl apply -f '$(shell pwd)/$</install/cluster-operator/' -n $(STRIMZI_OPERATOR_NS)
	@kubectl apply -f '$(shell pwd)/$</install/cluster-operator/020-RoleBinding-strimzi-cluster-operator.yaml' -n $(APPLICATION_NS)
	@kubectl apply -f '$(shell pwd)/$</install/cluster-operator/032-RoleBinding-strimzi-cluster-operator-topic-operator-delegation.yaml' -n $(APPLICATION_NS)
	@kubectl apply -f '$(shell pwd)/$</install/cluster-operator/031-RoleBinding-strimzi-cluster-operator-entity-operator-delegation.yaml' -n $(APPLICATION_NS)


## `remove-strimzi` Deletes the Cluster Operator Deployment, the strimzi CRD and RBAC
remove-strimzi: strimzi
	@kubectl delete -f '$(shell pwd)/$</install/cluster-operator'
	@kubectl delete namespace $(STRIMZI_OPERATOR_NS)


## `setup-kafka-cluster` 
setup-kafka-cluster: kafka-cluster.yml init-strimzi
	@kubectl apply -n $(APPLICATION_NS) -f $<


## `remove-kafka-cluster` 
remove-kafka-cluster: kafka-cluster.yml remove-kafka-topic
	@kubectl delete -n $(APPLICATION_NS) -f $<


## `setup-kafka-topic` Creates the Kafka Topics that will be used by the Application
setup-kafka-topic: kafka-topic.yml setup-kafka-cluster
	@kubectl wait 'kafka/$(shell yq read $< 'metadata.labels.['strimzi.io/cluster']')' \
		--for=condition=Ready --timeout=300s -n $(APPLICATION_NS)
	@kubectl apply -n $(APPLICATION_NS) -f $<


## `remove-kafka-topic`
remove-kafka-topic: kafka-topic.yml
	@kubectl delete -n $(APPLICATION_NS) -f $<


get-jaeger: jaeger
DOWNLOADED_COMPONENTS += jaeger
jaeger:
	@mkdir -p $@
	@echo "Downloading Jaeger Operator"
	@curl --silent \
		https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/crds/jaegertracing_v1_jaeger_crd.yaml \
		> $@/jaegertracing_v1_jaeger_crd.yaml
	@curl --silent \
		https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/service_account.yaml \
		> $@/service_account.yaml
	@curl --silent \
		https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role.yaml \
		> $@/role.yaml
	@curl --silent \
		https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role_binding.yaml \
		> $@/role_binding.yaml
	@curl --silent \
		https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/operator.yaml \
		> $@/operator.yaml
	@echo "Done !"
	@echo "Changing namespace references in YAML files."
	@sed -i '' 's/namespace: .*/namespace: $(JAEGER_OPERATOR_NS)/' $@/service_account.yaml
	@sed -i '' 's/namespace: .*/namespace: $(JAEGER_OPERATOR_NS)/' $@/role.yaml
	@sed -i '' 's/namespace: .*/namespace: $(JAEGER_OPERATOR_NS)/' $@/role_binding.yaml
	@sed -i '' 's/namespace: .*/namespace: $(JAEGER_OPERATOR_NS)/' $@/operator.yaml
	@echo "Done !"


init-jaeger: jaeger
	kubectl create namespace $(JAEGER_OPERATOR_NS) || echo "Namespace $(JAEGER_OPERATOR_NS) Already exists."
	kubectl apply -f $</jaegertracing_v1_jaeger_crd.yaml
	kubectl apply -f $</service_account.yaml
	kubectl apply -f $</role.yaml
	kubectl apply -f $</role_binding.yaml
	kubectl apply -f $</operator.yaml


remove-jaeger: jaeger
	kubectl delete -f $</operator.yaml
	kubectl delete -f $</role_binding.yaml
	kubectl delete -f $</role.yaml
	kubectl delete -f $</service_account.yaml
	kubectl delete -f $</jaegertracing_v1_jaeger_crd.yaml
	kubectl delete namespace $(JAEGER_OPERATOR_NS)

get-prometheus: prometheus
DOWNLOADED_COMPONENTS += prometheus
prometheus:
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


init-prometheus: prometheus configure-init
	@kubectl create namespace $(PROM_OPERATOR_NS)
	@kubectl apply -f $</prometheus-operator-deployment.yaml
	@kubectl apply -f $</prometheus-operator-cluster-role.yaml
	@kubectl apply -f $</prometheus-operator-cluster-role-binding.yaml
	@kubectl apply -f $</prometheus-operator-service-account.yaml


remove-prometheus: prometheus
	@kubectl delete -f $</prometheus-operator-service-account.yaml
	@kubectl delete -f $</prometheus-operator-cluster-role-binding.yaml
	@kubectl delete -f $</prometheus-operator-cluster-role.yaml
	@kubectl delete -f $</prometheus-operator-deployment.yaml
	@kubectl delete namespace $(PROM_OPERATOR_NS)


## `get-linkerd` created the linkerd directory which has linkerd clients binaries
##               it uses standard installation procedure but in the target directory
##               these binaries are removed when the `purge` target is executed
get-linkerd: linkerd
DOWNLOADED_COMPONENTS += linkerd
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


remove-linkerd: linkerd
	$(LINKERD) install --ignore-cluster | kubectl delete -f -


wipe: remove-prometheus remove-strimzi remove-linkerd
	kubectl delete namespace $(APPLICATION_NS)

purge:
	rm -rf $(DOWNLOADED_COMPONENTS)