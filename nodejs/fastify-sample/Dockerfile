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
	curl
DOC

ENV NODE_ENV production
USER node
WORKDIR /app
COPY --chown=node:node package.json package-lock.json ./

RUN <<DOC
npm clean-install
DOC
COPY --chown=node:node . .

#ENTRYPOINT ["npm", "run", "start"]
ENTRYPOINT ["./start.bash"]
CMD [""]
