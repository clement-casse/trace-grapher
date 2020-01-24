HOSTNAME ?= localhost

.PHONY: all

include vars.mk

all:
	@make --directory=provision-k8s/ install-operators
	@make --directory=provision-k8s/ install-components