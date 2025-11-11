#!/usr/bin/env bash
# vi: set noet :
set -euo pipefail
IFS=$'\n\t'

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
    if [[ -p /dev/stdin && "$#" -eq 0 ]]; then
        while IFS= read -r line || [ -n "$line" ]; do
            >&2 echo -e "${prefix}${line}${postfix}"
        done
    else
        >&2 echo -e "${prefix}$*${postfix}"
    fi
}
plain() { custom_log "" "" "$@"; }
info() { custom_log "[i] " "" "$@"; }
debug() { custom_log "[${gray}D${reset}]${gray} " "${reset}" "$@"; }
pass() { custom_log "[${green}✔${reset}]${green} " "${reset}" "$@"; }
warn() { custom_log "[${magenta}!${reset}]${magenta} " "${reset}" "$@"; }
fail() { custom_log "[${red}✘${reset}]${red} " "${reset}" "$@"; }

# Cache management script for pull-my-comments data
# Displays cache statistics and optionally clears cached data

# Default values
username=""
show_only=true
clear_issues=false
clear_json=false
clear_urls=false
clear_involved=false
clear_all=false

# Parse command-line flags
while getopts "u:ijacv" opt; do
  case "$opt" in
    u) username="$OPTARG" ;;
    i) clear_issues=true; show_only=false ;;
    j) clear_json=true; show_only=false ;;
    a) clear_all=true; show_only=false ;;
    c) clear_urls=true; show_only=false ;;
    v) clear_involved=true; show_only=false ;;
    *) exit 1 ;;
  esac
done

# Validation: username is required
if [[ -z "$username" ]]; then
  fail "Error: -u username required"
  plain ""
  plain "Usage: $0 -u <username> [-i] [-j] [-c] [-v] [-a]"
  plain ""
  plain "Options:"
  plain "  -u <username>  GitHub username (required)"
  plain "  -i             Clear standup issue list cache (issues.txt)"
  plain "  -j             Clear JSON issue details cache (standup + involved)"
  plain "  -c             Clear URL title cache"
  plain "  -v             Clear involved issues list cache (involved-issues-*.json)"
  plain "  -a             Clear all caches"
  plain ""
  plain "Without options, displays cache statistics only"
  exit 1
fi

# Check if output directory exists
if [[ ! -d "outputs/$username" ]]; then
  fail "No cache found for user: $username"
  info "Directory does not exist: outputs/$username"
  exit 1
fi

# Function to count files in a directory
count_files() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    find "$dir" -type f | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

# Function to get directory size
get_size() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    du -sh "$dir" 2>/dev/null | awk '{print $1}' || echo "0"
  else
    echo "0"
  fi
}

# Count cache items
issues_exists=false
standup_json_count=0
involved_json_count=0
involved_list_count=0
url_count=0

if [[ -f "outputs/$username/issues.txt" ]]; then
  issues_exists=true
fi

# Count standup JSON files
if [[ -d "outputs/$username" ]]; then
  standup_json_count=$(find "outputs/$username" -type d -name "standup" -exec find {} -type f -name "*.json" \; 2>/dev/null | wc -l | tr -d ' ')
else
  standup_json_count=0
fi

# Count involved issues JSON files
if [[ -d "outputs/$username" ]]; then
  involved_json_count=$(find "outputs/$username" -type d -name "involved-issues" -exec find {} -type f -name "*.json" \; 2>/dev/null | wc -l | tr -d ' ')
else
  involved_json_count=0
fi

# Count involved issues list cache files
if [[ -d "outputs/$username" ]]; then
  involved_list_count=$(find "outputs/$username" -maxdepth 1 -type f -name "involved-issues-*.json" 2>/dev/null | wc -l | tr -d ' ')
else
  involved_list_count=0
fi

url_count=$(count_files "outputs/$username/url_cache")

# Calculate sizes
standup_json_size="0"
involved_json_size="0"
if [[ -d "outputs/$username" ]]; then
  if find "outputs/$username" -type d -name "standup" 2>/dev/null | grep -q .; then
    standup_json_size=$(du -sh "$(find "outputs/$username" -type d -name "standup" | head -1)" 2>/dev/null | awk '{print $1}' || echo "0")
  fi
  if find "outputs/$username" -type d -name "involved-issues" 2>/dev/null | grep -q .; then
    involved_json_size=$(du -sh "$(find "outputs/$username" -type d -name "involved-issues" | head -1)" 2>/dev/null | awk '{print $1}' || echo "0")
  fi
fi
url_size=$(get_size "outputs/$username/url_cache")

# Display cache statistics
info "Cache statistics for user: $username"
plain ""
plain "  Standup issue list:     $(if $issues_exists; then echo "exists"; else echo "not found"; fi)"
plain "  Standup JSON details:   $standup_json_count files ($standup_json_size)"
plain "  Involved issues list:   $involved_list_count files"
plain "  Involved JSON details:  $involved_json_count files ($involved_json_size)"
plain "  URL title cache:        $url_count files ($url_size)"
plain ""

# If show_only mode, exit here
if $show_only; then
  info "Use -i, -j, -v, -c, or -a flags to clear cache"
  exit 0
fi

# Clear caches based on flags
if $clear_all; then
  warn "Clearing all caches for $username..."
  rm -rf "outputs/$username"
  pass "Removed: outputs/$username/"
  exit 0
fi

if $clear_issues; then
  if [[ -f "outputs/$username/issues.txt" ]]; then
    rm "outputs/$username/issues.txt"
    pass "Cleared issue list cache"
  else
    info "No issue list cache to clear"
  fi
fi

if $clear_json; then
  total_cleared=0
  if [[ -d "outputs/$username" ]]; then
    # Clear standup JSON files
    if find "outputs/$username" -type d -name "standup" 2>/dev/null | grep -q .; then
      find "outputs/$username" -type d -name "standup" -exec rm -rf {} + 2>/dev/null || true
      ((total_cleared += standup_json_count)) || true
    fi
    # Clear involved issues JSON files
    if find "outputs/$username" -type d -name "involved-issues" 2>/dev/null | grep -q .; then
      find "outputs/$username" -type d -name "involved-issues" -exec rm -rf {} + 2>/dev/null || true
      ((total_cleared += involved_json_count)) || true
    fi
    pass "Cleared JSON details cache ($total_cleared files)"
  else
    info "No JSON cache to clear"
  fi
fi

if $clear_involved; then
  if [[ -d "outputs/$username" ]]; then
    cleared_count=$(find "outputs/$username" -maxdepth 1 -type f -name "involved-issues-*.json" -delete -print 2>/dev/null | wc -l | tr -d ' ')
    pass "Cleared involved issues list cache ($cleared_count files)"
  else
    info "No involved issues list cache to clear"
  fi
fi

if $clear_urls; then
  if [[ -d "outputs/$username/url_cache" ]]; then
    rm -rf "outputs/$username/url_cache"
    pass "Cleared URL title cache ($url_count files)"
  else
    info "No URL cache to clear"
  fi
fi

pass "Cache clearing complete"
