# 
APPLICATION_NS := trace-grapher

OVERLAY := k3s-cluster

# Strimzi Version Number as written in the Github Release page: https://github.com/strimzi/strimzi-kafka-operator/releases
STRIMZI_VERSION := 0.16.0
JAEGER_OPERATOR_VERSION := v1.15.1
ECK_VERSION := 1.0.0-rc6
ISTIO_VERSION := 1.4.3

# Namespaces
STRIMZI_OPERATOR_NS := kafka-operator
JAEGER_OPERATOR_NS := jaeger-operator
JAEGER_STACK_NS := jaeger-tracing-stack
ELASTIC_STACK_NS := elastic-monitoring-stack
