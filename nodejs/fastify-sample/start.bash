#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

cd "${CWD}"
if [[ -z "${DEBUG:-}" ]]; then
	>&2 echo ":: production"
	node src/index.js
else
	>&2 echo ":: debug"
	npm install nodemon
	./node_modules/.bin/nodemon --config nodemon.json
fi
