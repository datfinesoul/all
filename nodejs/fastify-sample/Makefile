SHELL:=/usr/bin/env bash -euo pipefail -c
NAME:=fastify-sample
LABEL:=$(NAME):latest
APP_PORT:=8080
HOST_PORT:=9000

main:
	echo $(LABEL)
	@>&2 echo "no supported default option"; false

# OSX alternative to docker desktop
docker-start:
	minikube start
	# pause everything running in minikube
	minikube pause
	# setup docker support
	eval $(minikube docker-env)

build:
	# https://www.docker.com/blog/introduction-to-heredocs-in-dockerfiles/
	# https://www.stereolabs.com/docs/docker/building-arm-container-on-x86/
	DOCKER_BUILDKIT=1 \
		docker build \
		--file "Dockerfile" \
		--tag "$(LABEL)" \
		.

# attach to the running debug instance
shell:
	docker exec \
		--interactive \
		--tty \
		"$(NAME)" \
		"/bin/bash"

debug: build
	docker run \
		--rm \
		--env-file .env \
		--env DEBUG=1 \
		--name "$(NAME)" \
		--publish $(HOST_PORT):$(APP_PORT) \
		--volume "$(shell pwd)/src:/app/src:ro" \
		"$(LABEL)"

run: build
	docker run \
		--rm \
		--env-file .env \
		--name "$(NAME)" \
		--publish $(HOST_PORT):$(APP_PORT) \
		"$(LABEL)"

dive: build
	dive "${LABEL}"

.PHONY: main docker-start build shell run dive debug
