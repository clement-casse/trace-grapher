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

## About this project

This project is a part of my PhD experimentation platform: in this repository some Kubernetes manifest files instantiate a validation platform providing both **metrics** and **traces** for sample Cloud Applications.
These monitored applications are classical micro-services demonstration platforms in which anomalous behavior may easily be injected.

The platform is made of the following components:

- **A namespace `monitoring-stack`**: Cloud APM are deployed in this namespace:
  - **Prometheus** is the monitoring tool that pulls metrics from the various components in the system and store them in its time-serie Database.
  - **Jaeger** is the monitoring tools that collects and aggregates tracing data, structuring them in traces and proving a web view of these traces.
  - **OpenTelemetry Collector** is a part of the monitoring data flow, OpenTelemetry is a project which aims to normalize tracing and metrics by enhancing the capability of correlation between the two data-sources. This project is still mature for production but it look promising and have a very active community.
  - A variety of other tools that are used by either Prometheus or Jaeger.
- **Istio Service-Mesh**: A Service-Mesh is a set of network-proxies intercepting service-to-service communications manage by a logically centralized control-plane. The Service-Mesh is used both to Observe and Control cross-services communications, it creates the tracing data collected and aggregated by Jaeger and is able to overwrite services responses to inject errors/delay.
- **A `default` namespace**: Where the monitored application lives.

> Service-Meshes are, as of today, the most transparent solution allowing to have tracing data in a Kubernetes Cluster without modifying application code.

Both Prometheus and Jaeger have their Web-UI mapped outside of the cluster, this allows their API to be queries by external sources :

![Architecture](https://docs.google.com/drawings/d/e/2PACX-1vQWQs1rYiCxHqaHzJGNZW6mpdt_XjOI0oKvMqRvDgJcuvNZJokMbSXYA1g1QqF74smHIdS0R16G_hhf/pub?w=853&amp;h=1208)

### Monitoring scope of this project

Whereas distributed tracing is not a Kubernetes-specific monitoring data, as of today, it is this ecosystem that tracing is the most tested.
Nowadays Kubernetes platform are usually made of a custom OS installed on different machines in a IaaS to ensure multi-tenancy.
In that context, the monitoring scope of the Cloud application should cover all the abstraction layers managed by *Application Developers*:

- **Infrastructure**: Virtual Machines and Virtual Networks are still managed by the *Application Developers*, although the Operating System is managed by a Third-Party.
  Cloud Providers usually bill their clients based on the number of "Nodes" (= VM) they have in the cluster, therefore *Application Developers* need to keep track of the capacity and usage of the pool resource they pay for.
  Infrastructure is still in the scope of monitoring while subscribing to a managed Kubernetes.
- **Containers Orchestration**
- **Containers**

## How to run the trace grapher

This repository goal is just to provide an experimentation platform providing State-of-the-Art Monitoring Data for Cloud applications.
A Jupyter Notebook deployment integrated with Prometheus and Jaeger is also provided in the directory `./deploy-trace-grapher`, however example notebooks are note present in this repository (...yet?).

### Launch the stack locally with `docker-compose`

This project undergo major changes of scope frequently and the deployment is not automated (... yet?).

```sh
docker-compose run stack-builder
# now a shell pops as root in the project directory of the `stack-builder` container

make # add whatever target you want
```

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
