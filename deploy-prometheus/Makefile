OVERLAY ?= docker-desktop

.PHONY: \
	install-prometheus \
	remove-prometheus

install-monitoring:
	@kubectl apply -k ./overlays/$(OVERLAY)

remove-monitoring:
	@-kubectl delete -k ./overlays/$(OVERLAY)