# 
APPLICATION_NS := trace-grapher

OVERLAY := k3s-cluster

# Strimzi Version Number as written in the Github Release page: https://github.com/strimzi/strimzi-kafka-operator/releases
STRIMZI_VERSION := 0.15.0

JAEGER_OPERATOR_VERSION := v1.15.1

# Namespace for the Strimzi Kafka Cluster Operator.
STRIMZI_OPERATOR_NS := kafka-operator
PROM_OPERATOR_NS := prometheus-operator
JAEGER_OPERATOR_NS := jaeger-operator
ECK_VERSION := 1.0.0-beta1

ISTIO_VERSION := 1.4.2