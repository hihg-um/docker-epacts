ORG_NAME := um
PROJECT_NAME ?= docker-epacts

USER ?= `whoami`
GID ?= users

IMAGE_REPOSITORY :=
IMAGE := $(USER)/$(ORG_NAME)/$(PROJECT_NAME):latest

# Use this for debugging builds. Turn off for a more slick build log
DOCKER_BUILD_ARGS := --progress=plain

EPACTS_DIR := /opt/epacts

.PHONY: all build clean test tests

all: docker test

test: docker
#	@docker run -t $(IMAGE) epacts help
#	@docker run -t $(IMAGE) R --version > /dev/null

tests: test

clean:
	@docker rmi $(IMAGE)

docker:
	@docker build -t $(IMAGE) \
		--build-arg GROUP=$(GID) \
		--build-arg EPACTS_DIR="$(EPACTS_DIR)" \
		$(DOCKER_BUILD_ARGS) \
	  .

release:
	docker push $(IMAGE_REPOSITORY)/$(IMAGE)
