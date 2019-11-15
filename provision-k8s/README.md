# Provision Trace-Grapher on Kubernetes

## Concept and Scope

## Makefile rules

### Global Rules

- `make configure-init`
- `make wipe`
- `make purge`

### Apache Kafka Operator with Strimzi

- `make get-strimzi`: Download Strimzi K8S deployment files from GitHub into the `strimzi` directory.
- `make init-strimzi`: Apply the Strimzi Operator config to the Kubernetes Cluster.
- `make remove-strimzi`: Delete Strimzi Opertor from the Kubernetes Cluster.

### Jaeger Operator

- `make get-jaeger`: Download Jaeger Operator deployment files from Github into the `jaeger` directory.
- `make init-jaeger`: Apply the Jaeger Operator configuration to the Kubernetes Cluster.
- `make remove-jaeger`: Delete Jaeger Operator from the Kubernetes Cluster.

### Linkerd Service Mesh

- `make get-linkerd`: Download Linkerd executable and installs it locally in the `linkerd` directory.
- `make init-linkerd`: Applies Linkerd configuration to the Kubernetes Cluster to install Linkerd Service-Mesh.
- `make remove-linkerd`: Delete Linkerd Service Mesh from the Kubernetes Cluster.
