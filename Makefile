.DEFAULT_GOAL := help

REPO := "ahawker"

CWD := $(shell pwd)
COMMIT := $(shell git rev-parse --short HEAD)
BUILD_ID := $(shell date -u +%s)
TAG := $(COMMIT)-$(BUILD_ID)

USR := "hawker"
GRP := "hawker"
UID := "4739"
GID := "4739"
INIT_VERSION := "1.2.1"

.PHONY: alpine
alpine:  ## Alpine Linux (https://alpinelinux.org)
	docker build \
		--rm \
		--force-rm \
		--tag $(REPO)/alpine:$(TAG) \
		--tag $(REPO)/alpine:latest \
		--build-arg USR=$(USR) \
		--build-arg GRP=$(GRP) \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg BUILD_ID=$(BUILD_ID) \
		--build-arg INIT_VERSION=$(INIT_VERSION) \
		$(CWD)/alpine
	docker push $(REPO)/alpine:latest

TERRAFORM_VERSION := "0.10.0"
TERRAFORM_SHA256 := "f991039e3822f10d6e05eabf77c9f31f3831149b52ed030775b6ec5195380999"

.PHONY: terraform
terraform: alpine  ## Terraform (https://www.terraform.io)
	docker build \
		--rm \
		--force-rm \
		--tag $(REPO)/terraform:$(TAG) \
		--tag $(REPO)/terraform:latest \
		--build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION) \
		--build-arg TERRAFORM_SHA256=$(TERRAFORM_SHA256) \
		$(CWD)/terraform
	docker push $(REPO)/terraform:latest

.PHONY: help
help: ## Print Makefile usage.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
