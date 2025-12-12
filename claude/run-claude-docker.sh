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

# Auto-detect and export timezone if not set
if [ -z "$TZ" ]; then
  # Detect system timezone
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    DETECTED_TZ=$(readlink /etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##')
  else
    # Linux
    if command -v timedatectl >/dev/null 2>&1; then
      DETECTED_TZ=$(timedatectl show -p Timezone --value 2>/dev/null)
    else
      DETECTED_TZ=$(readlink /etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##')
    fi
  fi

  if [ -n "$DETECTED_TZ" ]; then
    export TZ=$DETECTED_TZ
  fi
fi

# Export user/group IDs for docker-compose
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

# Run container with docker-compose (use docker compose v2 syntax)
docker compose run --rm claude-code "$@"
