#!/usr/bin/env bash
# vi: set noet :
set -euo pipefail
IFS=$'\n\t'

year=2024

if [[ ! -f issues.txt ]]; then
  gh \
    -R glg/devops-meetings issue list \
    --state all \
    --limit 300 \
    --label Standup \
    --search "$year" \
    > issues.txt
fi

mkdir -p "$year/issues"

cat issues.txt \
  | head -n200 \
  | awk '{print $1}' \
  | while read -r issue_id; do

  if [[ -f "$year/issues/$issue_id.json" ]]; then
    continue
  fi
  echo "- $issue_id"
  gh -R glg/devops-meetings issue view "${issue_id}" \
    --comments \
    --json comments \
    --json title \
    >> "$year/issues/$issue_id.json"
done
jq -r '"### " + .title, (.comments[] | select(.author.login=="datfinesoul") | .body)' \
  "$year/issues/"*.json \
  > "$year.md"

while read -r line; do
  # Extract only valid GitHub URLs with awk
  read -r USER REPO NUMBER <<< "$(echo "$line" | awk -F'/' '
    /https:\/\/github.com\/.*\/.*\/(issues|pull)\/[0-9]+/ {
      user=$4
      repo=$5
      number=$7
      sub("[^0-9]+$", "", number)  # Remove trailing non-numeric characters
      print user, repo, number
    }')"
  echo "sss$USER"

  # Check if variables are set and output the result
  if [[ -n "$USER" && -n "$REPO" && -n "$NUMBER" ]]; then
    echo "$USER/$REPO/$NUMBER"
  fi
    #gh issue view 42 --json title --jq '.title'
    #gh pr view 17 --json title --jq '.title'
done <<< "$(<"$year.md" grep 'github.com\/.*issues\|pull')"
