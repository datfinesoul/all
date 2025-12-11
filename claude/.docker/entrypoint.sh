#!/bin/bash
set -euo pipefail

API_KEY="${ANTHROPIC_API_KEY:-}"
HOST_CREDENTIALS_FILE="/home/node/.claude-host-credentials.json"
CLAUDE_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --api-key)
      API_KEY="$2"
      shift 2
      ;;
    *)
      CLAUDE_ARGS+=("$1")
      shift
      ;;
  esac
done

# Setup config directory
mkdir -p "${CLAUDE_CONFIG_DIR}"

# Copy credentials and session files if mounted from host
if [ -f "$HOST_CREDENTIALS_FILE" ]; then
  echo "Copying credentials from host to ${CLAUDE_CONFIG_DIR}/.credentials.json"
  cp "$HOST_CREDENTIALS_FILE" "${CLAUDE_CONFIG_DIR}/.credentials.json"
  chmod 600 "${CLAUDE_CONFIG_DIR}/.credentials.json"

  # Copy session metadata file
  if [ -f "/home/node/.claude-host.json" ]; then
    echo "Copying session metadata to ${CLAUDE_CONFIG_DIR}/.claude.json"
    cp "/home/node/.claude-host.json" "${CLAUDE_CONFIG_DIR}/.claude.json"
    chmod 600 "${CLAUDE_CONFIG_DIR}/.claude.json"
  fi
elif [ -n "$API_KEY" ]; then
  # Use API key from environment or argument via apiKeyHelper
  echo "Using API key from environment variable"
  HELPER_SCRIPT="${CLAUDE_CONFIG_DIR}/api-key-helper.sh"
  cat > "${HELPER_SCRIPT}" <<'EOF'
#!/bin/bash
echo "${ANTHROPIC_API_KEY}"
EOF
  chmod +x "${HELPER_SCRIPT}"
  export ANTHROPIC_API_KEY="${API_KEY}"

  # Generate settings.json with apiKeyHelper
  SETTINGS_FILE="${CLAUDE_CONFIG_DIR}/settings.json"
  if [ ! -f "${SETTINGS_FILE}" ]; then
    cat > "${SETTINGS_FILE}" <<EOF
{
  "apiKeyHelper": "${HELPER_SCRIPT}"
}
EOF
    echo "Created settings.json at ${SETTINGS_FILE}"
  fi
else
  # No authentication available
  echo "Error: No authentication credentials available."
  echo "Either:"
  echo "  1. Mount ~/.claude/.credentials.json (currently not found at ${HOST_CREDENTIALS_FILE})"
  echo "  2. Set ANTHROPIC_API_KEY environment variable"
  echo "  3. Use --api-key argument"
  exit 1
fi

# Execute Claude Code with remaining arguments
exec claude "${CLAUDE_ARGS[@]}"
