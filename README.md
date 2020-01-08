# Trace Grapher

## Motivation

**The idea behind this project is take profit of the heavily connected nature of trace data to create and maintain at runtime a property graph modeling the performance of the monitored Cloud-Application.**

Nowadays more and more applications are developed to be Cloud-Native, which means some constraints:

- The application is developed as a fully distributed system
- Components are disposable and may be volatile
- The application is built on top of abstractions layers managed by third-parties that may not be monitored

Monitoring such systems involves addressing new challenges in the APM community.
Indeed, for Cloud-Applications, **ensuring bottlenecks are identified** is a critical criteria for delivering the service and scaling.
Also, the **ability to identify the root-cause** in an error propagation scenario is also crucial to patch and recover the system.
*These challenges involve maintaining a global view of a rapidly evolving distributed system*.

This is why tracing became an important topic among the companies doing their business in the Clouds [[1], [2], [3], [4], [5]].
Recent initiatives like [OpenTelemetry](https://opentelemetry.io) aims to normalize, and also to provide an implementation, on how trace data is passed from the monitoring system to the APM.
As a result, we can expect trace data to follow some well-defined schema [[6]] and to respect some semantic conventions [[7], [8]].

However, state-of-the-art trace-based APM lack maturity and fail to provide a global view of the system.
Their main purpose is helping the developer to understand interactions between the components while debugging and optimizing their code [[9]].

[1]: https://eng.uber.com/distributed-tracing/ "Uber evolution of tracing"
[2]: https://blog.twitter.com/engineering/en_us/a/2012/distributed-systems-tracing-with-zipkin.html "Twitter opensourced Zipkin"
[3]: https://ai.google/research/pubs/pub36356 "Google publication on Dapper"
[4]: https://www.usenix.org/system/files/osdi18-veeraraghavan.pdf "Facebook publication Maelstrom"
[5]: https://eng.lyft.com/envoy-joins-the-cncf-dc18baefbc22 "Lyft with Envoy-Proxy"
[6]: https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/api-tracing.md "OpenTelemetry Tracing API"
[7]: https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-resource-semantic-conventions.md "Resource Semantic Conventions"
[8]: https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-semantic-conventions.md#span-conventions "Span Semantic Conventions"
[9]: https://medium.com/@copyconstruct/distributed-tracing-weve-been-doing-it-wrong-39fc92a857df "Distributed Tracing — we’ve been doing it wrong Cindy Sridharan"

## Model

### Expressing OpenTelemetry data as a property graph

According to OpenTelemetry Specifications (still work in progress as the time of writing) a *Trace* is an aggregation of *Spans*.
*Spans* represent the time taken to do an action and bear also some semantic information about the measurement.
Each *Span* is associated with :

- an *Operation*, which represents the intent of this action
- a *Resource*, which represents its executor

![OpenTelemetry Property Graph Meta-Model](https://docs.google.com/drawings/d/e/2PACX-1vTU8yfwfsLbpB3zEs7_-8g_zVF3T77s5iem4hotwDhw5mEbhbyWwzMHHzg8tsRHwILKtgzMqQHLJAC0/pub?w=1440&amp;h=1080)

> **To Do List:**
>
> - [ ] Implement the relationship `(:Span)-[:REFERENCE]->(:Span)` from te model in the PoC to be able to do root-cause analysis.
> - [ ] Make resources not identified only by their name but by the whole set of properties of the vertex: the current implementation would hide load-balanced services or upgraded ones.
> - [ ] Add the notion of [metrics and measurement](https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/api-metrics.md)

### Extending the model

> Still WIP

## Implementation

The Goal of this project is to provide a Distributed Tracing collector capable of ingesting traces from a Cloud Application and make this data available for other tools to consume data.
It uses the [Jaeger Application](https://www.jaegertracing.io/) which is one of the most used solutions for collecting such traces as of today.

### Architecture

The application is built on top of a [Jaeger deployment based on Kafka](https://www.jaegertracing.io/docs/1.14/deployment/#kafka) to store Spans before joining them into Traces.
The stream of Spans is consumed by Kafka-Connect that execute a [Cypher query](setup/trace-to-graph-mapping.cypher) to push data in Neo4j.

For the moment graph manipulation is done through Neo4j Web-UI, although the goal remains to make the pipeline go a step further by automating this graph analysis.

![Architecture](https://docs.google.com/drawings/d/e/2PACX-1vSlGvjSOVp4mCCCZwOfgbp1Dvl6InGC1wrb9KNi-eUAjBdWwdqYtZxIo5R8aHMphAwwkCOUc7V557CC/pub?w=1912&amp;h=1208)

## How to run the trace grapher

### Dependencies

To deploy the stack, either on the local machine (with `docker-compose`) or on a Kubernetes Cluster, the machine needs to have docker installed.
Indeed, all build / deployment tools are embedded in a docker image, this image requires

    - either to bind `/var/run/docker.sock` for a local deployment
    - either to have the kube-config file mounted as the file `/root/.kube/config` in the container

To be able to run make, start a shell in the container that has all tools to run the Makefiles :

```sh
docker-compose run stack-builder
# now a shell pops as root in the project directory of the `stack-builder` container

make # add whatever target you want
```

> Automatic build is still WIP

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
