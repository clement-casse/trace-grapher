
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


.PHONY: setup-kafka-neo4j-connectors setup-neo4j-schema wait-for-neo4j-api wait-for-kafka-connect-api clean

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


setup-neo4j-schema: neo4j-api/request-data.json
	@make wait-for-neo4j-api
	@curl $(SILENT_OPTS) -X POST -d "@$<" $(NEO4J_HTTP_ENDPOINT)/data/transaction/commit | jq .errors
	@echo Done !


REQUEST_DATA_FILES += kafka-connect/connectors/*.json
kafka-connect/connectors/%.json: kafka-connect/connectors/%.cypher kafka-connect/Neo4jSinkConnector.tmpl
	@CYPHER_CMD="$(shell cat $< | sed -e 's|//.*$$||g' -e 's|"|\\\\\\"|g' | tr -s '[:space:]' ' ' )" \
	NEO4J_HOST="neo4j" \
	ENTITY_NAME="$(notdir $(basename $<))" \
	envsubst < kafka-connect/Neo4jSinkConnector.tmpl > $@
	@echo File "$@" created


setup-kafka-neo4j-connectors: $(addprefix kafka-connect/connectors/,$(addsuffix .json,$(shell cd kafka-connect/connectors/; ls *.cypher | cut -d '.' -f 1)))
	@make wait-for-kafka-connect-api
	@for connector in $^; do \
		if curl $(SILENT_OPTS) -X GET $(KAFKA_CONNECT_ENDPOINT)/connectors | grep "$$(cat $$connector | jq -r .name)" ; then \
			echo "The Connector $$(cat $$connector | jq -r .name) is already known by Kafka-Connect, Deleting it !"; \
			curl --silent -o /dev/null $(API_HEADERS_OPT) -X DELETE "$(KAFKA_CONNECT_ENDPOINT)/connectors/$$(cat $$connector | jq -r .name)"; \
			sleep 2; \
		fi; \
		echo "Adding connector '$$(cat $$connector | jq -r .name)' to Kafka-connect." ; \
		curl $(SILENT_OPTS) -X POST -d "@$$connector" "$(KAFKA_CONNECT_ENDPOINT)/connectors" | jq -r .name ; \
		echo "Done !"; \
	done;

clean:
	rm -rf $(REQUEST_DATA_FILES)