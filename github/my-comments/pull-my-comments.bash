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

cp "$year.md" before.md
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
  gsed -ie "s|https://github.com/$user/$repo/$kind/$number|$user/$repo: $title|g" \
    "$year.md"
done <<< "$(<"$year.md" grep 'github.com\/.*issues\|pull')"
