
## CHECK IF REQUIRED EXECUTABLES ARE PRESENT ON THE MACHINE
#  Raise an error and stop make before executing rules
REQUIRED_EXECUTABLES := docker docker-compose
CAN_RUN := $(foreach exec,$(REQUIRED_EXECUTABLES), \
	$(if $(shell which $(exec)), "$(exec) found", $(error "The tool $(exec) cannot be found in PATH")) \
)

HOSTNAME ?= localhost
HTTP_PROXY ?=
HTTPS_PROXY ?=
NO_PROXY ?= localhost

.PHONY: deploy stop clean

deploy:
	ADVERTISED_HOST='$(HOSTNAME)' \
	HTTP_PROXY=$(HTTP_PROXY) \
	HTTPS_PROXY=$(HTTPS_PROXY) \
	NO_PROXY='$(NO_PROXY)' \
	docker-compose up -d --build

stop:
	ADVERTISED_HOST='$(HOSTNAME)' docker-compose down

remove:
	ADVERTISED_HOST='$(HOSTNAME)' docker-compose down -v
