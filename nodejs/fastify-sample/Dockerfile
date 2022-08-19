# syntax=docker/dockerfile:1.3-labs

#FROM caddy:2.5.2-builder-alpine AS caddy-builder
#RUN xcaddy build

FROM node:16.14-alpine3.15

#COPY --from=caddy-builder /usr/bin/caddy /usr/bin/caddy

# https://www.docker.com/blog/introduction-to-heredocs-in-dockerfiles/
RUN <<DOC
apk add \
	caddy \
	bash \
DOC

ARG S6_OVERLAY_VERSION=3.1.1.2
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

ENV NODE_ENV production
WORKDIR /app
COPY package.json package-lock.json ./

RUN <<DOC
npm clean-install

mkdir -p /etc/s6-overlay/s6-rc.d/web
echo longrun > /etc/s6-overlay/s6-rc.d/web/type
touch /etc/s6-overlay/s6-rc.d/user/contents.d/web

DOC
COPY . .
COPY s6.run /etc/s6-overlay/s6-rc.d/web/run

ENTRYPOINT ["/init"]
