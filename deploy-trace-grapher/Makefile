include vars.mk

OVERLAY ?= docker-desktop

.PHONY: \
	install-components \
	remove-components \
	purge


install-components:
	@kubectl apply -k ./overlays/$(OVERLAY)


remove-components:
	@-kubectl delete -k ./overlays/$(OVERLAY)


purge: remove-components
	@-kubectl delete namespace "$(APPLICATION_NS)"