#!/bin/bash

# Check for authentication
CREDENTIALS_FILE="$HOME/.claude/.credentials.json"

if [ ! -f "$CREDENTIALS_FILE" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "Error: No authentication credentials found"
  echo "Either:"
  echo "  1. Ensure ~/.claude/.credentials.json exists (for OAuth)"
  echo "  2. Export ANTHROPIC_API_KEY environment variable"
  exit 1
fi

# Run container with docker-compose (use docker compose v2 syntax)
docker compose run --rm claude-code "$@"
