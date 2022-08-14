#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# TODO: needs to be refactored
trap '>&2 echo ":: SIGINT:${child_pid}"; kill "${child_pid}"; wait "${child_pid}"; cleanup' SIGINT
trap '>&2 echo ":: SIGTERM:${child_pid}"; kill "${child_pid}"; wait "${child_pid}"; cleanup' SIGTERM

cd /app
if [[ -z "${DEBUG:-}" ]]; then
	>&2 echo ":: production"
	node src/index.js
else
	>&2 echo ":: debug"
	npm install nodemon
	./node_modules/.bin/nodemon --config nodemon.json
fi
