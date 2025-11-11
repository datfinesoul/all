#!/usr/bin/env bash
# vi: set noet :
set -euo pipefail
IFS=$'\n\t'

# Default values
year="$(date +%Y)"
repo=""
github_username=""
issue_label=""
issue_limit=300
issue_process_limit=200
sed_command="sed"

# Parse arguments
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

# Validate required parameters
if [[ -z "$repo" ]]; then
  echo "Error: -r repo required (format: owner/repo)" >&2
  exit 1
fi
if [[ -z "$github_username" ]]; then
  echo "Error: -u github_username required" >&2
  exit 1
fi
if [[ -z "$issue_label" ]]; then
  echo "Error: -l issue_label required" >&2
  exit 1
fi

mkdir -p "outputs/$github_username"

if [[ ! -f "outputs/$github_username/issues.txt" ]]; then
  gh \
    -R "$repo" issue list \
    --state all \
    --limit "$issue_limit" \
    --label "$issue_label" \
    --search "$year" \
    > "outputs/$github_username/issues.txt"
fi

mkdir -p "outputs/$github_username/$year/issues"

cat "outputs/$github_username/issues.txt" \
  | head -n"$issue_process_limit" \
  | awk '{print $1}' \
  | while read -r issue_id; do

  if [[ -f "outputs/$github_username/$year/issues/$issue_id.json" ]]; then
    continue
  fi
  echo "- $issue_id"
  gh -R "$repo" issue view "${issue_id}" \
    --comments \
    --json comments \
    --json title \
    >> "outputs/$github_username/$year/issues/$issue_id.json"
done

# Check if any JSON files exist before processing
if compgen -G "outputs/$github_username/$year/issues/"*.json > /dev/null; then
  jq -r '"### " + .title, (.comments[] | select(.author.login=="'"$github_username"'") | .body)' \
    "outputs/$github_username/$year/issues/"*.json \
    > "outputs/$github_username/$year.md"
else
  echo "No issue files found in outputs/$github_username/$year/issues/" >&2
  exit 1
fi

cp "outputs/$github_username/$year.md" "outputs/$github_username/before.md"
while read -r line; do
  # Extract only valid GitHub URLs with awk
  IFS=$' ' read -r user repo number kind <<< "$(echo "$line" | awk -F'/' '
    /https:\/\/github.com\/.*\/.*\/(issues|pull)\/[0-9]+/ {
      user=$4
      repo=$5
      kind=$6
      number=$7
      sub("[^0-9]+$", "", number)  # Remove trailing non-numeric characters
      print user, repo, number, kind
    }')"
  if [[ "$kind" == "issues" ]]; then
    title="$(gh issue view "$number" --repo "$user/$repo" --json title --jq '.title')"
  elif [[ "$kind" == "pull" ]]; then
    title="$(gh pr view "$number" --repo "$user/$repo" --json title --jq '.title')"
  fi
  "$sed_command" -ie "s|https://github.com/$user/$repo/$kind/$number|$user/$repo: $title|g" \
    "outputs/$github_username/$year.md"
done <<< "$(<"outputs/$github_username/$year.md" grep 'github.com\/.*issues\|pull')"
