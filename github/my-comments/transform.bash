#!/usr/bin/env bash
# vi: set noet :
set -euo pipefail
IFS=$'\n\t'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sed_command="${sed_command:-sed}"

# Cleanup trap to remove temp files on exit
cleanup() {
  true
}
trap cleanup EXIT

# Color definitions for logging
red="$(tput setaf 1)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"
cyan="$(tput setaf 6)"
white="$(tput setaf 7)"
gray="$(tput dim)$(tput setaf 7)"
magenta="$(tput setaf 5)"
reset="$(tput sgr0)"

# Logging functions with color support
custom_log() {
    local prefix="$1"
    local postfix="$2"
    shift 2
    local epoch="$(date +%s)"
    if [[ -p /dev/stdin && "$#" -eq 0 ]]; then
        while IFS= read -r line || [ -n "$line" ]; do
            >&2 echo -e "${epoch} ${prefix}${line}${postfix}"
        done
    else
        >&2 echo -e "${epoch} ${prefix}$*${postfix}"
    fi
}
plain() { custom_log "" "" "$@"; }
info() { custom_log "[i] " "" "$@"; }
debug() { custom_log "[${gray}D${reset}]${gray} " "${reset}" "$@"; }
pass() { custom_log "[${green}✔${reset}]${green} " "${reset}" "$@"; }
warn() { custom_log "[${magenta}!${reset}]${magenta} " "${reset}" "$@"; }
fail() { custom_log "[${red}✘${reset}]${red} " "${reset}" "$@"; }

# Output ISO timestamp at script start
>&2 echo "START: $(date -Iseconds)"

# Sed compatibility: Detect if we need GNU sed for in-place editing.
# macOS users may have installed GNU sed as 'gsed' or symlinked as
# 'sed'. We test for GNU sed support and fail early if unavailable.
if [[ "$sed_command" == "sed" ]]; then
  # Check if this sed supports GNU-style in-place editing
  if ! sed --version 2>&1 | grep -q "GNU"; then
    # Not GNU sed - check if gsed is available
    if command -v gsed &> /dev/null; then
      info "Using gsed instead of sed for GNU compatibility"
      sed_command="gsed"
    else
      fail "Error: GNU sed required. Install with: brew install gnu-sed"
      fail "Or specify sed command with: -s gsed"
      exit 1
    fi
  fi
elif [[ "$sed_command" == "gsed" ]]; then
  # User explicitly requested gsed - verify it exists
  if ! command -v gsed &> /dev/null; then
    fail "Error: gsed not found. Install with: brew install gnu-sed"
    exit 1
  fi
fi

# Function to filter comments from JSON file
# Removes comments where author.login is "spacelift-io" or "github-actions"
filter_bot_comments() {
  local input_file="$1"
  local output_file="$2"

  jq 'if .comments then
        .comments |= map(select(.author.login != "spacelift-io" and .author.login != "github-actions"))
      else . end' "$input_file" > "$output_file"
}

# Process involved-prs for both users
process_user_prs() {
  local username="$1"
  local input_dir="$SCRIPT_DIR/outputs/$username/2025/involved-prs"
  local output_dir="$SCRIPT_DIR/transforms/$username/2025/involved-prs"

  if [[ ! -d "$input_dir" ]]; then
    warn "Input directory does not exist: $input_dir"
    return
  fi

  mkdir -p "$output_dir"

  local file_count=0
  local filtered_count=0
  local total_files=$(find "$input_dir" -name "*.json" -type f | wc -l | tr -d ' ')

  info "Processing $username involved-prs ($total_files files)"

  for json_file in "$input_dir"/*.json; do
    if [[ ! -f "$json_file" ]]; then
      continue
    fi

    local filename="$(basename "$json_file")"
    local output_file="$output_dir/$filename"

    filter_bot_comments "$json_file" "$output_file"

    ((file_count++))

    # Progress update every 25 files
    if [[ $((file_count % 25)) -eq 0 ]]; then
      info "Progress: $file_count/$total_files files processed"
    fi
  done

  pass "Processed $file_count files for $username"
}

# Main execution
info "Starting bot comment filter transformation"

process_user_prs "datfinesoul" || warn "Failed processing datfinesoul"
process_user_prs "glg-satish-tripathi" || warn "Failed processing glg-satish-tripathi"

pass "Transformation complete"

# Output ISO timestamp at script end
>&2 echo "END: $(date -Iseconds)"
