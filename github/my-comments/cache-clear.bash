#!/usr/bin/env bash
# vi: set noet :
set -euo pipefail
IFS=$'\n\t'

# Cache management script for pull-my-comments data
# Displays cache statistics and optionally clears cached data

# Default values
username=""
show_only=true
clear_issues=false
clear_json=false
clear_urls=false
clear_all=false

# Parse command-line flags
while getopts "u:ijac" opt; do
  case "$opt" in
    u) username="$OPTARG" ;;
    i) clear_issues=true; show_only=false ;;
    j) clear_json=true; show_only=false ;;
    a) clear_all=true; show_only=false ;;
    c) clear_urls=true; show_only=false ;;
    *) exit 1 ;;
  esac
done

# Validation: username is required
if [[ -z "$username" ]]; then
  >&2 echo "[x] Error: -u username required"
  >&2 echo ""
  >&2 echo "Usage: $0 -u <username> [-i] [-j] [-c] [-a]"
  >&2 echo ""
  >&2 echo "Options:"
  >&2 echo "  -u <username>  GitHub username (required)"
  >&2 echo "  -i             Clear issue list cache (issues.txt)"
  >&2 echo "  -j             Clear JSON issue details cache"
  >&2 echo "  -c             Clear URL title cache"
  >&2 echo "  -a             Clear all caches (issues, JSON, URLs)"
  >&2 echo ""
  >&2 echo "Without options, displays cache statistics only"
  exit 1
fi

# Check if output directory exists
if [[ ! -d "outputs/$username" ]]; then
  >&2 echo "[x] No cache found for user: $username"
  >&2 echo "[i] Directory does not exist: outputs/$username"
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
json_count=0
url_count=0

if [[ -f "outputs/$username/issues.txt" ]]; then
  issues_exists=true
fi

# Count JSON files by searching for directories named "issues"
if [[ -d "outputs/$username" ]]; then
  json_count=$(find "outputs/$username" -type d -name "issues" -exec find {} -type f -name "*.json" \; 2>/dev/null | wc -l | tr -d ' ')
else
  json_count=0
fi

url_count=$(count_files "outputs/$username/url_cache")

# Calculate sizes - get total size of all year directories
if [[ -d "outputs/$username" ]]; then
  json_size=$(find "outputs/$username" -type d -name "issues" -exec du -sh {} + 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
  if [[ "$json_size" == "0" ]] || [[ -z "$json_size" ]]; then
    json_size=$(du -sh outputs/$username/*/issues 2>/dev/null | awk '{print $1}' | head -1 || echo "0")
  fi
else
  json_size="0"
fi
url_size=$(get_size "outputs/$username/url_cache")

# Display cache statistics
>&2 echo "[i] Cache statistics for user: $username"
>&2 echo ""
>&2 echo "  Issue list cache:    $(if $issues_exists; then echo "exists"; else echo "not found"; fi)"
>&2 echo "  JSON details cache:  $json_count files ($json_size)"
>&2 echo "  URL title cache:     $url_count files ($url_size)"
>&2 echo ""

# If show_only mode, exit here
if $show_only; then
  >&2 echo "[i] Use -i, -j, -c, or -a flags to clear cache"
  exit 0
fi

# Clear caches based on flags
if $clear_all; then
  >&2 echo "[i] Clearing all caches for $username..."
  rm -rf "outputs/$username"
  >&2 echo "[i] Removed: outputs/$username/"
  exit 0
fi

if $clear_issues; then
  if [[ -f "outputs/$username/issues.txt" ]]; then
    rm "outputs/$username/issues.txt"
    >&2 echo "[i] Cleared issue list cache"
  else
    >&2 echo "[i] No issue list cache to clear"
  fi
fi

if $clear_json; then
  if [[ -d "outputs/$username" ]]; then
    find "outputs/$username" -type d -name "issues" -exec rm -rf {} + 2>/dev/null || true
    >&2 echo "[i] Cleared JSON details cache ($json_count files)"
  else
    >&2 echo "[i] No JSON cache to clear"
  fi
fi

if $clear_urls; then
  if [[ -d "outputs/$username/url_cache" ]]; then
    rm -rf "outputs/$username/url_cache"
    >&2 echo "[i] Cleared URL title cache ($url_count files)"
  else
    >&2 echo "[i] No URL cache to clear"
  fi
fi

>&2 echo "[i] Cache clearing complete"
