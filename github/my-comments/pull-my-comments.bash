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

mkdir -p "outputs/$github_username/$year/standup"

# Phase 2: Download detailed data for each issue including all
# comments. Skips already-downloaded issues to enable incremental
# updates and avoid rate limits.
>&2 echo "[i] Processing up to $issue_process_limit standup issues..."
downloaded=0
skipped=0
cat "outputs/$github_username/issues.txt" \
  | head -n"$issue_process_limit" \
  | awk '{print $1}' \
  | while read -r issue_id; do

  if [[ -f "outputs/$github_username/$year/standup/$issue_id.json" ]]; then
    ((skipped++)) || true
    continue
  fi
  >&2 echo "[d] Downloading standup issue $issue_id..."
  ((downloaded++)) || true
  gh -R "$repo" issue view "${issue_id}" \
    --comments \
    --json comments \
    --json title \
    >> "outputs/$github_username/$year/standup/$issue_id.json"
done
>&2 echo "[i] Standup issues - Downloaded: $downloaded, Skipped (cached): $skipped"

# Phase 2b: Discover involved issues (assigned or authored) from org.
# Queries GitHub for issues where user was assigned or authored,
# filtering by created/closed dates. Caches results to avoid
# repeated API calls.
org="$(echo "$repo" | cut -d/ -f1)"
involved_cache="outputs/$github_username/involved-issues-$year.json"

if [[ ! -f "$involved_cache" ]]; then
  >&2 echo "[i] Fetching involved issues (assigned/authored) from org: $org..."

  # Fetch 4 queries: assigned+created, assigned+closed, author+created, author+closed
  # Combine and deduplicate by URL
  {
    gh search issues --assignee "$github_username" --owner "$org" --created "$year-01-01..$year-12-31" --limit 1000 --json number,title,url,createdAt,closedAt,repository,state,body 2>/dev/null || echo "[]"
    gh search issues --assignee "$github_username" --owner "$org" --closed "$year-01-01..$year-12-31" --limit 1000 --json number,title,url,createdAt,closedAt,repository,state,body 2>/dev/null || echo "[]"
    gh search issues --author "$github_username" --owner "$org" --created "$year-01-01..$year-12-31" --limit 1000 --json number,title,url,createdAt,closedAt,repository,state,body 2>/dev/null || echo "[]"
    gh search issues --author "$github_username" --owner "$org" --closed "$year-01-01..$year-12-31" --limit 1000 --json number,title,url,createdAt,closedAt,repository,state,body 2>/dev/null || echo "[]"
  } | jq -s 'add | unique_by(.url)' > "$involved_cache"

  >&2 echo "[i] Found $(jq 'length' "$involved_cache") involved issues"
else
  >&2 echo "[i] Using cached involved issues ($(jq 'length' "$involved_cache") issues)"
fi

# Phase 2c: Download involved issue details and determine participation type.
# Stores in separate directory with repo-namespaced filenames.
mkdir -p "outputs/$github_username/$year/involved-issues"

>&2 echo "[i] Processing involved issues..."
involved_downloaded=0
involved_skipped=0

jq -c '.[]' "$involved_cache" | while read -r issue_json; do
  repo_name="$(echo "$issue_json" | jq -r '.repository.name')"
  repo_owner="$(echo "$issue_json" | jq -r '.repository.owner.login')"
  issue_num="$(echo "$issue_json" | jq -r '.number')"
  cache_file="outputs/$github_username/$year/involved-issues/${repo_owner}_${repo_name}_${issue_num}.json"

  if [[ -f "$cache_file" ]]; then
    ((involved_skipped++)) || true
    continue
  fi

  >&2 echo "[d] Downloading involved issue $repo_owner/$repo_name#$issue_num..."
  ((involved_downloaded++)) || true

  # Fetch full issue details to determine participation type
  full_issue="$(gh issue view "$issue_num" --repo "$repo_owner/$repo_name" --json number,title,url,createdAt,closedAt,state,body,author,assignees)"

  # Determine participation type: Assigned, Author, or both
  is_author="$(echo "$full_issue" | jq -r --arg user "$github_username" '.author.login == $user')"
  is_assigned="$(echo "$full_issue" | jq -r --arg user "$github_username" '[.assignees[].login] | contains([$user])')"

  if [[ "$is_author" == "true" && "$is_assigned" == "true" ]]; then
    participation="Assigned+Author"
  elif [[ "$is_author" == "true" ]]; then
    participation="Author"
  elif [[ "$is_assigned" == "true" ]]; then
    participation="Assigned"
  else
    participation="Involved"
  fi

  # Add participation type to JSON and save
  echo "$full_issue" | jq --arg part "$participation" '. + {participation: $part}' > "$cache_file"
done

>&2 echo "[i] Involved issues - Downloaded: $involved_downloaded, Skipped (cached): $involved_skipped"

# Phase 3: Compile date-organized markdown with standup and
# involvement sections. Groups by date (prefer closed, fallback
# to created) and creates separate sections for each.
>&2 echo "[i] Compiling date-organized markdown..."

# Temporary file to collect all entries with dates
temp_entries="outputs/$github_username/$year-temp-entries.txt"
> "$temp_entries"

# Process standup issues: extract date from title and comments
if compgen -G "outputs/$github_username/$year/standup/"*.json > /dev/null; then
  for standup_file in "outputs/$github_username/$year/standup/"*.json; do
    title="$(jq -r '.title' "$standup_file")"

    # Extract date from standup title (assuming format like "Weekly Standup - Jan 8, 2024")
    # Try to parse various date formats and convert to YYYY-MM-DD
    standup_date="$(echo "$title" | grep -oE '[A-Za-z]+ [0-9]+, [0-9]{4}' | head -1 | xargs -I {} date -d "{}" +%Y-%m-%d 2>/dev/null || echo "unknown")"

    # Extract user's comments
    comments="$(jq -r '.comments[] | select(.author.login=="'"$github_username"'") | .body' "$standup_file")"

    if [[ -n "$comments" && "$standup_date" != "unknown" ]]; then
      echo "STANDUP|$standup_date|$title|$comments" >> "$temp_entries"
    fi
  done
fi

# Process involved issues: use closed date or created date
if compgen -G "outputs/$github_username/$year/involved-issues/"*.json > /dev/null; then
  for involved_file in "outputs/$github_username/$year/involved-issues/"*.json; do
    closed_at="$(jq -r '.closedAt // empty' "$involved_file")"
    created_at="$(jq -r '.createdAt' "$involved_file")"

    # Prefer closed date, fallback to created date
    if [[ -n "$closed_at" ]]; then
      activity_date="$(echo "$closed_at" | cut -d'T' -f1)"
    else
      activity_date="$(echo "$created_at" | cut -d'T' -f1)"
    fi

    # Extract issue details
    repo_owner="$(jq -r '.url' "$involved_file" | cut -d'/' -f4)"
    repo_name="$(jq -r '.url' "$involved_file" | cut -d'/' -f5)"
    issue_num="$(jq -r '.number' "$involved_file")"
    title="$(jq -r '.title' "$involved_file")"
    participation="$(jq -r '.participation' "$involved_file")"
    body="$(jq -r '.body // ""' "$involved_file")"

    # Extract summary: first paragraph or first 200 chars
    summary="$(echo "$body" | head -c 200 | sed 's/\r//g' | tr '\n' ' ')"
    if [[ ${#summary} -eq 200 ]]; then
      summary="${summary}..."
    fi

    echo "INVOLVED|$activity_date|[$participation] $repo_owner/$repo_name#$issue_num: $title|$summary" >> "$temp_entries"
  done
fi

# Sort by date and generate markdown with date headings
sort -t'|' -k2 "$temp_entries" | awk -F'|' '
BEGIN {
  current_date = ""
}
{
  entry_type = $1
  entry_date = $2
  entry_title = $3
  entry_content = $4

  # New date heading
  if (entry_date != current_date) {
    if (current_date != "") {
      print ""
    }
    print "## " entry_date
    print ""
    current_date = entry_date
    current_section = ""
  }

  # Section headers
  if (entry_type == "STANDUP" && current_section != "STANDUP") {
    print "### Standup"
    print ""
    current_section = "STANDUP"
  } else if (entry_type == "INVOLVED" && current_section != "INVOLVED") {
    if (current_section != "") print ""
    print "### Involvement"
    print ""
    current_section = "INVOLVED"
  }

  # Content
  if (entry_type == "STANDUP") {
    print "**" entry_title "**"
    print entry_content
    print ""
  } else if (entry_type == "INVOLVED") {
    print "**" entry_title "**"
    if (entry_content != "") {
      print entry_content
    }
    print ""
  }
}
' > "outputs/$github_username/$year.md"

rm -f "$temp_entries"
>&2 echo "[i] Created outputs/$github_username/$year.md"

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
