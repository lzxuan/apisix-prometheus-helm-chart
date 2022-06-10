APISIX_BASE_IMAGE_TAG           ?= 2.14.1-alpine
APISIX_DASHBOARD_BASE_IMAGE_TAG ?= 2.13-alpine

.PHONY: docker-build-apisix
docker-build-apisix:
	@cd ./dockerfiles/apisix && docker build \
		--build-arg APISIX_BASE_IMAGE_TAG=$(APISIX_BASE_IMAGE_TAG) \
		--build-arg APISIX_GEOIPUPDATE_ACCOUNT_ID=$(APISIX_GEOIPUPDATE_ACCOUNT_ID) \
		--build-arg APISIX_GEOIPUPDATE_LICENSE_KEY=$(APISIX_GEOIPUPDATE_LICENSE_KEY) \
		--tag apisix:$(APISIX_BASE_IMAGE_TAG) \
		--tag apisix:latest \
		.

.PHONY: docker-build-apisix-dashboard
docker-build-apisix-dashboard:
	@cd ./dockerfiles/apisix-dashboard && docker build \
		--build-arg APISIX_DASHBOARD_BASE_IMAGE_TAG=$(APISIX_DASHBOARD_BASE_IMAGE_TAG) \
		--tag apisix-dashboard:$(APISIX_DASHBOARD_BASE_IMAGE_TAG) \
		--tag apisix-dashboard:latest \
		.
