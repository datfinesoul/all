# syntax=docker/dockerfile:1.3-labs

#FROM ubuntu:22.04
FROM amazonlinux:latest

RUN <<DOC
yum install -y \
	vim
DOC

COPY telegraf.sh .

ENTRYPOINT ["/usr/bin/env", "bash"]


