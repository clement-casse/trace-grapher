# Trace Grapher

## Context

In the recent years distributed-tracing became an invaluable tool to better inspect Heavily Distributed Cloud Applications.
Trace data is rich by nature: it has both a numeric side, measuring latency at precise points in time, and also has a semantic side by exposing metadata and relationship between measurements.
Unlike other monitoring methods (metrics collection or logging), distributed tracing establish first causality between measurements.
This kind of data is, as a result, first-class citizen when solving problems like bottleneck identification or root-cause analysis, problems often encountered in nowadays Cloud Application.
Most of the main actors of Cloud Computing have OpenSourced parts of their tooling to handle Tracing [[1], [2], [5]] and reported success stories using traces in production [[3], [4]].

In the OpenSource landscape, a major initiative regarding distributed-tracing is [OpenTelemetry](https://opentelemetry.io/); this project has a high visibility in the OpenSource community.
This project is the result of the fusion of two initiatives related to tracing Cloud-Applications: OpenTracing, whose aim is to provide a unified API for tracing and OpenCensus, whose focus is a production-ready way of creating trace.

> @TODO Talk about how OpenTelemetry can provide more numeric data.

However, distributed-tracing adoption for smaller-size Cloud-Applications remains low.
Indeed, the most common use-case for distributed-tracing is the developer gaining insight of the propagation of requests in the application with the Gantt-Chart view of the traces.
State-of-the-Art trace-based APM collect measurements and aggregate them into traces; then these traces are stored in a database and displayed by a UI without any further treatment.
In addition Tracing is costly, trace data is heavy and may require high infrastructure costs if not sampled properly.
Some work has already been done on how to keep trace data representative while having a sparse sampling strategy [[6]].
While there is an increased adoption of tracing tool, trace data is rarely used in production because of its complexity.

[1]: https://eng.uber.com/distributed-tracing/ "Uber evolution of tracing"
[2]: https://blog.twitter.com/engineering/en_us/a/2012/distributed-systems-tracing-with-zipkin.html "Twitter opensourced Zipkin"
[3]: https://ai.google/research/pubs/pub36356 "Google publication on Dapper"
[4]: https://www.usenix.org/system/files/osdi18-veeraraghavan.pdf "Facebook publication Maelstrom"
[5]: https://eng.lyft.com/envoy-joins-the-cncf-dc18baefbc22 "Lyft with Envoy-Proxy"
[6]: https://people.mpi-sws.org/~jcmace/papers/lascasas2018weighted.pdf "Weighted Sampling of Execution Traces"

## Motivation

The idea behind this project is take profit of the heavily connected nature of trace data to create a property graph modeling performance of the monitored application.

> **TBC**
> @TODO Describe performances issues that need to be automatically discovered with trace data

## Model

> **Draft / Ideas**
> According to OpenTelemetry Specifications (still work in progress as the time of writing) a *Trace*, is made of *Spans*, which represent the time taken to do an action.
> Each *Span* is associated with an *Operation*, which represents the intent of this action, and a *Resource*, which represents its executor.
> @TODO insert meta model and Use-Cases

## Implementation

The Goal of this project is to provide a Distributed Tracing collector capable of ingesting traces from a Cloud Application and make this data available for other tools to consume data.
It uses the [Jaeger Application](https://www.jaegertracing.io/) which is one of the most used solutions for collecting such traces as of today.

### Architecture

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
