ELECTRUM_VERSION = $(strip $(shell cat ELECTRUM_VERSION))
ELECTRUM_CHECKSUM_SHA512 = $(strip $(shell cat ELECTRUM_CHECKSUM_SHA512))
GIT_COMMIT = $(strip $(shell git rev-parse --short HEAD))

DOCKER_IMAGE ?= osminogin/electrum-daemon
DOCKER_TAG = $(ELECTRUM_VERSION)

# Build Docker image
build: docker_build docker_tag output

# Build and push Docker image
release: docker_tag docker_push output

default: docker_build output

download:
	@

docker_build:
	@docker build \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		--build-arg ELECTRUM_VERSION=$(ELECTRUM_VERSION) \
		--build-arg ELECTRUM_CHECKSUM_SHA512=$(ELECTRUM_CHECKSUM_SHA512) \
		--build-arg VCS_REF=$(GIT_COMMIT) \
		-t $(DOCKER_IMAGE):$(DOCKER_TAG) .

docker_tag:
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_IMAGE):latest

docker_push:
	docker push $(DOCKER_IMAGE):latest
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

output:
	@echo Docker Image: $(DOCKER_IMAGE):$(DOCKER_TAG)
