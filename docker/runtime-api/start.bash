#!/bin/sh
set -euo pipefail
IFS=$'\n\t'

echo "$(date -u +"%Y-%m-%d %H:%M:%S UTC") - Process started."

while true
do
  HEADERS="$(mktemp)"
  # Get an event. The HTTP request will block until one is received
  EVENT_DATA="$(curl -sS -LD "$HEADERS" -X GET "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")"
  # Extract request ID by scraping response headers received above
  REQUEST_ID="$(grep -Fi Lambda-Runtime-Aws-Request-Id "$HEADERS" | tr -d '[:space:]' | cut -d: -f2)"

  # DO STUFF HERE

  # Exit the script as successful
  curl -sSX POST "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/${REQUEST_ID}/response" -d "Backup process completed successfully."
done
