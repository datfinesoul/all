SHELL:=/usr/bin/env bash -euo pipefail -c
NAME:=workstation
LABEL:=$(NAME):latest

main:
	echo $(LABEL)
	@>&2 echo "no supported default option"; false

build:
	# https://www.docker.com/blog/introduction-to-heredocs-in-dockerfiles/
	# https://www.stereolabs.com/docs/docker/building-arm-container-on-x86/
	DOCKER_BUILDKIT=1 \
		docker build \
		--file "Dockerfile" \
		--tag "$(LABEL)" \
		.

# run the container using only the shell
shell: build
	docker run \
		--interactive \
		--tty \
		--rm \
		"$(NAME)"

.PHONY: main build shell
