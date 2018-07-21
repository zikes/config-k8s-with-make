PACKAGE ?= hello-world
VERSION ?= $(shell git describe --tags --always --dirty --match="v*" 2> /dev/null || cat $(CURDIR)/.version 2> /dev/null || echo v0)

K8S_DIR ?= ./k8s
K8S_BUILD_DIR ?= ./build_k8s
K8S_FILES     := $(shell find $(K8S_DIR) -name '*.yaml' | sed 's:$(K8S_DIR)/::g')

DOCKER_REGISTRY_DOMAIN ?= docker.io
DOCKER_REGISTRY_PATH   ?= zikes
DOCKER_IMAGE           ?= $(DOCKER_REGISTRY_PATH)/$(PACKAGE):$(VERSION)
DOCKER_IMAGE_DOMAIN    ?= $(DOCKER_REGISTRY_DOMAIN)/$(DOCKER_IMAGE)

MAKE_ENV += PACKAGE VERSION DOCKER_IMAGE DOCKER_IMAGE_DOMAIN

HELLO ?= World
MAKE_ENV += HELLO

SHELL_EXPORT := $(foreach v,$(MAKE_ENV),$(v)='$($(v))' )

.PHONY: build
build:
	go build -o ./bin/hello

.PHONY: build-docker
build-docker: build
	docker build . -t "$(DOCKER_IMAGE)"

.PHONY: push-docker
push-docker: build-docker
	docker push "$(DOCKER_IMAGE)"

# Builds the Kubernetes build directory if it does not exist
# The @ symbol prevents Make from echoing the results of the
# command.
$(K8S_BUILD_DIR):
	@mkdir -p $(K8S_BUILD_DIR)

.PHONY: build-k8s
build-k8s: $(K8S_BUILD_DIR)
	@for file in $(K8S_FILES); do \
		mkdir -p `dirname "$(K8S_BUILD_DIR)/$$file"` ; \
		$(SHELL_EXPORT) envsubst <$(K8S_DIR)/$$file >$(K8S_BUILD_DIR)/$$file ;\
	done

.PHONY: deploy
deploy: build-k8s push-docker
	kubectl apply -f $(K8S_BUILD_DIR)
