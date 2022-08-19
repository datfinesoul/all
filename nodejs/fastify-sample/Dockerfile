# syntax=docker/dockerfile:1.3-labs

# https://itnext.io/lightweight-and-performance-dockerfile-for-node-js-ec9eed3c5aef
#FROM caddy:2.5.2-builder-alpine AS caddy-builder
#RUN xcaddy build

FROM node:16.14-alpine3.15
#FROM alpine

#COPY --from=caddy-builder /usr/bin/caddy /usr/bin/caddy

# https://www.docker.com/blog/introduction-to-heredocs-in-dockerfiles/
RUN <<DOC
apk add \
  --no-cache \
	--update \
	caddy \
	bash
DOC

# apk add --update nodejs npm

ENV NODE_ENV production
USER node
WORKDIR /app

# copy the package,json and do npm ci since this is less likely to change than code
COPY --chown=node:node package.json package-lock.json ./
RUN <<DOC
npm clean-install
DOC

COPY --chown=node:node . .

USER root
RUN <<DOC
apk del --purge
rm -rf /tmp/*
DOC

USER node
ENTRYPOINT ["./start.bash"]
CMD [""]
