#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# https://nodejs.org/api/process.html#signal-events
# https://linuxconfig.org/how-to-propagate-a-signal-to-child-processes-from-a-bash-script
cleanup() {
  >&2 echo ":: cleaning up..."
}

# TODO: needs to be refactored
trap '>&2 echo ":: SIGINT:${child_pid}"; kill "${child_pid}"; wait "${child_pid}"; cleanup' SIGINT
trap '>&2 echo ":: SIGTERM:${child_pid}"; kill "${child_pid}"; wait "${child_pid}"; cleanup' SIGTERM

caddy start

if [[ -z "${DEBUG:-}" ]]; then
	>&2 echo ":: production"
	node src/index.js &
else
	>&2 echo ":: debug"
	npm install nodemon
	./node_modules/.bin/nodemon --config nodemon.json &
fi

child_pid="$!"
wait
