
## CHECK IF REQUIRED EXECUTABLES ARE PRESENT ON THE MACHINE
#  Raise an error and stop make before executing rules
REQUIRED_EXECUTABLES := curl jq sed envsubst
CAN_RUN := $(foreach exec,$(REQUIRED_EXECUTABLES), \
	$(if $(shell which $(exec)), "$(exec) found", $(error "The tool $(exec) cannot be found in PATH")) \
)

HOSTNAME ?= localhost
KAFKA_CONNECT_ENDPOINT := http://$(HOSTNAME)/api/kafka-connect-1
NEO4J_HTTP_ENDPOINT := http://$(HOSTNAME)/db
REQUEST_DATA_FILES :=

API_HEADERS_OPT := -H 'Content-Type: application/json' -H 'Accept: application/json'
SILENT_OPTS := --silent $(API_HEADERS_OPT)
GET_CODE_OPT := -o /dev/null --write-out '%{http_code}' $(SILENT_OPTS)


.PHONY: setup-kafka-neo4j-connector setup-neo4j-schema wait-for-neo4j-api wait-for-kafka-connect-api clean

wait-for-neo4j-api:
	@echo Waiting Neo4j HTTP API to be available ...
	@while [ "$$(curl $(GET_CODE_OPT) -X POST '$(NEO4J_HTTP_ENDPOINT)/data/transaction/commit')" != "200" ]; do \
		echo "  > Cannot reach Neo4j HTTP API retrying in 10 sec"; \
		sleep 10; \
	done
	@echo Neo4j HTTP API Ready !


wait-for-kafka-connect-api:
	@echo Waiting Kafka Connect API to be available ...
	@while [ "$$(curl $(GET_CODE_OPT) -X GET '$(KAFKA_CONNECT_ENDPOINT)/connectors')" != "200" ]; do \
		echo "  > Cannot reach Kafka Connect API retrying in 5 sec"; \
		sleep 5; \
	done
	@echo Kafka-Connect API Ready !


REQUEST_DATA_FILES += neo4j-api/request-data.json
neo4j-api/request-data.json: CYPHER_CMD = $(shell cat init-neo4j.cypher | sed -e 's|//.*$$||g' -e 's|"|\\\\\\"|g' | tr -s '[:space:]' ' ' )
neo4j-api/request-data.json: neo4j-api/request.tmpl
	@CYPHER_CMD="$(CYPHER_CMD)" envsubst < $< > $@
	@echo File "$@" created


REQUEST_DATA_FILES += kafka-connect/request-data.json
kafka-connect/request-data.json: CYPHER_CMD = $(shell cat trace-to-graph-mapping.cypher | sed -e 's|//.*$$||g' -e 's|"|\\\\\\"|g' | tr -s '[:space:]' ' ' )
kafka-connect/request-data.json: NEO4J_HOST = neo4j
kafka-connect/request-data.json: kafka-connect/request.tmpl
	@CYPHER_CMD="$(CYPHER_CMD)" NEO4J_HOST="$(NEO4J_HOST)" envsubst < $< > $@
	@echo File "$@" created


setup-neo4j-schema: neo4j-api/request-data.json
	@make wait-for-neo4j-api
	@curl $(SILENT_OPTS) -X POST -d "@$<" $(NEO4J_HTTP_ENDPOINT)/data/transaction/commit | jq .errors
	@echo Done !


setup-kafka-neo4j-connector: CONNECTOR_NAME = $(shell cat $< | jq -r .name)
setup-kafka-neo4j-connector: kafka-connect/request-data.json
	@make wait-for-kafka-connect-api
	@if curl $(SILENT_OPTS) -X GET $(KAFKA_CONNECT_ENDPOINT)/connectors | grep "$(CONNECTOR_NAME)" ; then \
		echo "The Connector $(CONNECTOR_NAME) is already known by Kafka-Connect, Deleting it !"; \
		curl --silent -o /dev/null $(API_HEADERS_OPT) -X DELETE $(KAFKA_CONNECT_ENDPOINT)/connectors/$(CONNECTOR_NAME); \
		sleep 2; \
	fi; \
	echo 'Adding connector "$(CONNECTOR_NAME)" to Kafka-connect.' ; \
	curl $(SILENT_OPTS) -X POST -d "@$<" $(KAFKA_CONNECT_ENDPOINT)/connectors | jq -r .name ; \
	echo Done !


clean:
	rm -rf $(REQUEST_DATA_FILES)