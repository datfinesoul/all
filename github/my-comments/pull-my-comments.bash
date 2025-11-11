#!/usr/bin/env bash
# vi: set noet :
set -euo pipefail
IFS=$'\n\t'

# Configuration: Set sensible defaults for optional parameters.
# Only repo, username, and label are required - everything else
# adapts to your environment.
year="$(date +%Y)"
repo=""
github_username=""
issue_label=""
issue_limit=300
issue_process_limit=200
sed_command="sed"

# Parse command-line flags to override defaults
while getopts "y:r:u:l:i:p:s:" opt; do
  case "$opt" in
    y) year="$OPTARG" ;;
    r) repo="$OPTARG" ;;
    u) github_username="$OPTARG" ;;
    l) issue_label="$OPTARG" ;;
    i) issue_limit="$OPTARG" ;;
    p) issue_process_limit="$OPTARG" ;;
    s) sed_command="$OPTARG" ;;
    *) exit 1 ;;
  esac
done

# Validation: Ensure the three critical parameters are provided
if [[ -z "$repo" ]]; then
  >&2 echo "[x] Error: -r repo required (format: owner/repo)"
  exit 1
fi
if [[ -z "$github_username" ]]; then
  >&2 echo "[x] Error: -u github_username required"
  exit 1
fi
if [[ -z "$issue_label" ]]; then
  >&2 echo "[x] Error: -l issue_label required"
  exit 1
fi

# Sed compatibility: Detect if we need GNU sed for in-place editing.
# macOS users may have installed GNU sed as 'gsed' or symlinked as
# 'sed'. We test for GNU sed support and fail early if unavailable.
if [[ "$sed_command" == "sed" ]]; then
  # Check if this sed supports GNU-style in-place editing
  if ! sed --version 2>&1 | grep -q "GNU"; then
    # Not GNU sed - check if gsed is available
    if command -v gsed &> /dev/null; then
      >&2 echo "[i] Using gsed instead of sed for GNU compatibility"
      sed_command="gsed"
    else
      >&2 echo "[x] Error: GNU sed required. Install with: brew install gnu-sed"
      >&2 echo "[x] Or specify sed command with: -s gsed"
      exit 1
    fi
  fi
elif [[ "$sed_command" == "gsed" ]]; then
  # User explicitly requested gsed - verify it exists
  if ! command -v gsed &> /dev/null; then
    >&2 echo "[x] Error: gsed not found. Install with: brew install gnu-sed"
    exit 1
  fi
fi

# Setup: Create user-specific output directory for organizing
# multiple users' data
mkdir -p "outputs/$github_username"

# Phase 1: Discover all relevant issues from the repository.
# Caches results to avoid repeated API calls when re-running.
if [[ ! -f "outputs/$github_username/issues.txt" ]]; then
  >&2 echo "[i] Fetching issue list from $repo..."
  gh \
    -R "$repo" issue list \
    --state all \
    --limit "$issue_limit" \
    --label "$issue_label" \
    --search "$year" \
    > "outputs/$github_username/issues.txt"
  >&2 echo "[i] Found $(wc -l < "outputs/$github_username/issues.txt") issues"
else
  >&2 echo "[i] Using cached issue list ($(wc -l < "outputs/$github_username/issues.txt") issues)"
fi

mkdir -p "outputs/$github_username/$year/issues"

# Phase 2: Download detailed data for each issue including all
# comments. Skips already-downloaded issues to enable incremental
# updates and avoid rate limits.
>&2 echo "[i] Processing up to $issue_process_limit issues..."
downloaded=0
skipped=0
cat "outputs/$github_username/issues.txt" \
  | head -n"$issue_process_limit" \
  | awk '{print $1}' \
  | while read -r issue_id; do

  if [[ -f "outputs/$github_username/$year/issues/$issue_id.json" ]]; then
    ((skipped++)) || true
    continue
  fi
  >&2 echo "[d] Downloading $issue_id..."
  ((downloaded++)) || true
  gh -R "$repo" issue view "${issue_id}" \
    --comments \
    --json comments \
    --json title \
    >> "outputs/$github_username/$year/issues/$issue_id.json"
done
>&2 echo "[i] Downloaded: $downloaded, Skipped (cached): $skipped"

# Phase 3: Extract your comments from all issues and compile
# into a single markdown document. Filters by your GitHub username
# so you only see your own contributions for self-review.
if compgen -G "outputs/$github_username/$year/issues/"*.json > /dev/null; then
  >&2 echo "[i] Compiling markdown from $(ls "outputs/$github_username/$year/issues/"*.json | wc -l) issue files..."
  jq -r '"### " + .title, (.comments[] | select(.author.login=="'"$github_username"'") | .body)' \
    "outputs/$github_username/$year/issues/"*.json \
    > "outputs/$github_username/$year.md"
  >&2 echo "[i] Created outputs/$github_username/$year.md"
else
  >&2 echo "[x] No issue files found in outputs/$github_username/$year/issues/"
  exit 1
fi

# Phase 4: Enhance readability by replacing GitHub URLs with
# human-readable titles. Makes it easier to understand referenced
# work without clicking through to each link.
>&2 echo "[i] Resolving GitHub URLs to titles..."
cp "outputs/$github_username/$year.md" "outputs/$github_username/before.md"

# Create cache directory for URL title resolutions
mkdir -p "outputs/$github_username/url_cache"

url_count=0
cached_count=0
fetched_count=0
while read -r line; do
  ((url_count++)) || true
  IFS=$' ' read -r user repo number kind <<< "$(echo "$line" | awk -F'/' '
    /https:\/\/github.com\/.*\/.*\/(issues|pull)\/[0-9]+/ {
      user=$4
      repo=$5
      kind=$6
      number=$7
      sub("[^0-9]+$", "", number)
      print user, repo, number, kind
    }')"

  # Create cache key from user/repo/kind/number
  cache_file="outputs/$github_username/url_cache/${user}_${repo}_${kind}_${number}.txt"

  if [[ -f "$cache_file" ]]; then
    # Use cached title
    title="$(cat "$cache_file")"
    ((cached_count++)) || true
    >&2 echo "[d] Using cached title for $user/$repo#$number ($kind)"
  else
    # Fetch and cache title
    if [[ "$kind" == "issues" ]]; then
      >&2 echo "[d] Resolving $user/$repo#$number (issue)..."
      title="$(gh issue view "$number" --repo "$user/$repo" --json title --jq '.title')"
    elif [[ "$kind" == "pull" ]]; then
      >&2 echo "[d] Resolving $user/$repo#$number (PR)..."
      title="$(gh pr view "$number" --repo "$user/$repo" --json title --jq '.title')"
    fi
    echo "$title" > "$cache_file"
    ((fetched_count++)) || true
  fi

  "$sed_command" -i'' -e "s|https://github.com/$user/$repo/$kind/$number|$user/$repo: $title|g" \
    "outputs/$github_username/$year.md"
done <<< "$(<"outputs/$github_username/$year.md" grep 'github.com\/.*issues\|pull')"
>&2 echo "[i] Resolved $url_count GitHub URLs (fetched: $fetched_count, cached: $cached_count)"
>&2 echo "[i] Done! Final output: outputs/$github_username/$year.md"
