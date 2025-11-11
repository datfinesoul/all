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
  >&2 echo "[x] Error: -u username required"
  >&2 echo ""
  >&2 echo "Usage: $0 -u <username> [-i] [-j] [-c] [-v] [-a]"
  >&2 echo ""
  >&2 echo "Options:"
  >&2 echo "  -u <username>  GitHub username (required)"
  >&2 echo "  -i             Clear standup issue list cache (issues.txt)"
  >&2 echo "  -j             Clear JSON issue details cache (standup + involved)"
  >&2 echo "  -c             Clear URL title cache"
  >&2 echo "  -v             Clear involved issues list cache (involved-issues-*.json)"
  >&2 echo "  -a             Clear all caches"
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
>&2 echo "[i] Cache statistics for user: $username"
>&2 echo ""
>&2 echo "  Standup issue list:     $(if $issues_exists; then echo "exists"; else echo "not found"; fi)"
>&2 echo "  Standup JSON details:   $standup_json_count files ($standup_json_size)"
>&2 echo "  Involved issues list:   $involved_list_count files"
>&2 echo "  Involved JSON details:  $involved_json_count files ($involved_json_size)"
>&2 echo "  URL title cache:        $url_count files ($url_size)"
>&2 echo ""

# If show_only mode, exit here
if $show_only; then
  >&2 echo "[i] Use -i, -j, -v, -c, or -a flags to clear cache"
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
    >&2 echo "[i] Cleared JSON details cache ($total_cleared files)"
  else
    >&2 echo "[i] No JSON cache to clear"
  fi
fi

if $clear_involved; then
  if [[ -d "outputs/$username" ]]; then
    cleared_count=$(find "outputs/$username" -maxdepth 1 -type f -name "involved-issues-*.json" -delete -print 2>/dev/null | wc -l | tr -d ' ')
    >&2 echo "[i] Cleared involved issues list cache ($cleared_count files)"
  else
    >&2 echo "[i] No involved issues list cache to clear"
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
