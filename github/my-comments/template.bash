#!/usr/bin/env bash
# vi: set noet :
set -euo pipefail
IFS=$'\n\t'


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

# Output ISO timestamp at script end
>&2 echo "END: $(date -Iseconds)"
