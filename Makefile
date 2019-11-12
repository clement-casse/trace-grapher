HOSTNAME ?= localhost

.PHONY: all deploy-local stop-local remove-local init-neo4j-indices provision-kafka-connect reload-kafka-connect

include vars.mk

all:
	@make deploy-local
	@make init-neo4j-indices
	@make provision-kafka-connect

deploy-local:
	@make --directory=provision-compose deploy HOSTNAME='$(HOSTNAME)' HTTP_PROXY=$(HTTP_PROXY) HTTPS_PROXY=$(HTTPS_PROXY) NO_PROXY='$(NO_PROXY)'

stop-local:
	@make --directory=provision-compose stop HOSTNAME='$(HOSTNAME)'

remove-local:
	@make --directory=provision-compose remove HOSTNAME='$(HOSTNAME)'

init-neo4j-indices:
	@make --directory=setup setup-neo4j-schema HOSTNAME='$(HOSTNAME)'

provision-kafka-connect:
	@make --directory=setup setup-kafka-neo4j-connector HOSTNAME='$(HOSTNAME)'

reload-kafka-connect:
	@make --directory=setup clean 
	@make --directory=setup setup-kafka-neo4j-connector HOSTNAME='$(HOSTNAME)'
