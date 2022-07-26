APISIX_ALPINE_BASE_IMAGE_TAG    ?= 2.14.1-alpine
APISIX_CENTOS_BASE_IMAGE_TAG    ?= 2.14.1-centos
APISIX_DASHBOARD_BASE_IMAGE_TAG ?= 2.13-alpine

.PHONY: docker-build-apisix-alpine
docker-build-apisix-alpine:
	@cd ./dockerfiles/apisix-alpine && docker build \
		--build-arg APISIX_BASE_IMAGE_TAG=$(APISIX_ALPINE_BASE_IMAGE_TAG) \
		--build-arg APISIX_GEOIPUPDATE_ACCOUNT_ID=$(APISIX_GEOIPUPDATE_ACCOUNT_ID) \
		--build-arg APISIX_GEOIPUPDATE_LICENSE_KEY=$(APISIX_GEOIPUPDATE_LICENSE_KEY) \
		--tag apisix:$(APISIX_ALPINE_BASE_IMAGE_TAG) \
		.

.PHONY: docker-build-apisix-centos
docker-build-apisix-centos:
	@cd ./dockerfiles/apisix-centos && docker build \
		--build-arg APISIX_BASE_IMAGE_TAG=$(APISIX_CENTOS_BASE_IMAGE_TAG) \
		--build-arg APISIX_GEOIPUPDATE_ACCOUNT_ID=$(APISIX_GEOIPUPDATE_ACCOUNT_ID) \
		--build-arg APISIX_GEOIPUPDATE_LICENSE_KEY=$(APISIX_GEOIPUPDATE_LICENSE_KEY) \
		--tag apisix:$(APISIX_CENTOS_BASE_IMAGE_TAG) \
		.

.PHONY: docker-build-apisix-dashboard
docker-build-apisix-dashboard:
	@cd ./dockerfiles/apisix-dashboard && docker build \
		--build-arg APISIX_DASHBOARD_BASE_IMAGE_TAG=$(APISIX_DASHBOARD_BASE_IMAGE_TAG) \
		--tag apisix-dashboard:$(APISIX_DASHBOARD_BASE_IMAGE_TAG) \
		--tag apisix-dashboard:latest \
		.
