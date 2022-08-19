SHELL:=/usr/bin/env bash -euo pipefail -c
NAME:=fastify-sample
LABEL:=$(NAME):latest
APP_PORT:=8080
HOST_PORT:=9000
minikube start --container-runtime=docker --vm=true


main:
	echo $(LABEL)
	@>&2 echo "no supported default option"; false

# OSX alternative to docker desktop
docker-start:
	#minikube start
	minikube start --container-runtime=docker --vm=true
	# pause everything running in minikube
	minikube pause
	# setup docker support
	@>&2 echo ":: please run the following command:"
	@>&2 echo -e '\neval $$(minikube docker-env)'

build:
	# https://www.docker.com/blog/introduction-to-heredocs-in-dockerfiles/
	# https://www.stereolabs.com/docs/docker/building-arm-container-on-x86/
	DOCKER_BUILDKIT=1 \
		docker build \
		--file "Dockerfile" \
		--tag "$(LABEL)" \
		.
	docker image ls --filter=reference="$(NAME):latest"

# attach to the running debug instance
shell:
	docker exec \
		--interactive \
		--tty \
		"$(NAME)" \
		"/bin/bash"

run-shell: build
	docker run \
			--rm \
			--interactive \
			--tty \
			--env-file .env \
			--name "$(NAME)" \
			--entrypoint '' \
			"$(LABEL)" \
			"/bin/bash"

debug: build
	touch .env
	docker run \
		--rm \
		--env-file .env \
		--env DEBUG=1 \
		--name "$(NAME)" \
		--publish $(HOST_PORT):$(APP_PORT) \
		--volume "$(shell pwd)/src:/app/src:ro" \
		"$(LABEL)"

osx-debug: build
	touch .env
	docker run \
		--rm \
		--env-file .env \
		--env DEBUG=1 \
		--name "$(NAME)" \
		--publish $(HOST_PORT):$(APP_PORT) \
		--volume "/fastify-sample-src:/app/src:ro" \
		"$(LABEL)"

osx-volume:
	minikube mount ./src:/fastify-sample-src

osx-ip:
	# need this to connect to the container
	minikube ip

run: build
	touch .env
	docker run \
		--rm \
		--env-file .env \
		--name "$(NAME)" \
		--publish $(HOST_PORT):$(APP_PORT) \
		"$(LABEL)"

dive: build
	dive "${LABEL}"

.PHONY: main docker-start build shell run dive debug osx-debug osx-volume osx-ip run-shell
