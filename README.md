# Trace Grapher

## Motivation

@TODO

## Architecture

The application is built on top of a [Jaeger deployment based on Kafka](https://www.jaegertracing.io/docs/1.14/deployment/#kafka) to store Spans before joining them into Traces.
The stream of Spans is consumed by Kafka-Connect that execute a [Cypher query](setup/trace-to-graph-mapping.cypher) to push data in Neo4j.

For the moment graph manipulation is done through Neo4j Web-UI.

![Architecture](https://docs.google.com/drawings/d/e/2PACX-1vSlGvjSOVp4mCCCZwOfgbp1Dvl6InGC1wrb9KNi-eUAjBdWwdqYtZxIo5R8aHMphAwwkCOUc7V557CC/pub?w=1912&amp;h=1208)

## How to run the trace grapher

### Dependencies

To run `make` some tools need to be installed :

- `curl` Most of the time already installed on the machine or available on most of the package managers (`apt`, `brew`, ...)
- `sed` Most of the time already installed on the machine or available on most of the package managers (`apt`, `brew`, ...)
- `docker` can be installed following the [official Docker documentation](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- `docker-compose` can be installed following the [official `docker-compose` documentation](https://docs.docker.com/compose/install/)
- `jq` a [command line tool to decode json](https://stedolan.github.io/jq/), available on most of the package managers (`apt`, `brew`, ...)
- `envsubst` from [gettext](https://www.gnu.org/software/gettext/), use your package manager to install `gettext`.

> When using `make`, it should complain when these executable are not found in your `$PATH`

### Launch the stack locally with `docker-compose`

Be sure variables in the file `vars.mk` meet the requirement of your target environment and use `make`: this will both deploy and setup the pipeline consuming traces from Kafka and sending them to Neo4j.

### Available web interfaces

This project has a lot of Web-UI to inspect the pipeline, for a local deployment (`HOSTNAME := localhost` in file `vars.mk`), URIs are:

- [http://localhost/jaeger/] to reach Jaeger and see traces in the standard pipeline
- [http://localhost/browser/] to reach Neo4j browser and query the property graph
- [http://localhost/db/] to get Neo4j HTTP API (mostly used in the setup process)
- [http://localhost/kafka-connect/] to reach a [Kafka-Connect Web UI](https://github.com/lensesio/kafka-connect-ui)
- [http://localhost/api/kafka-connect/] to reach Kafka-Connect REST API (mandatory for Kafka-Connect Web UI)
- [http://localhost/kafka-topics/] to reach [Kafka-Topics Web UI](https://github.com/lensesio/kafka-topics-ui)
- [http://localhost/api/kafka-rest-proxy/] to reach Kafka Rest Proxy API (mandatory for Kafka-Topics Web UI)
