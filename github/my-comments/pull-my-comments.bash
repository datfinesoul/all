#!/usr/bin/env bash
# vi: set noet :
set -euo pipefail
IFS=$'\n\t'

if [[ ! -f issues.txt ]]; then
  gh \
    -R glg/devops-meetings issue list \
    --state all \
    --limit 300 \
    --label Standup \
    --search 2023 \
    > issues.txt
fi

cat issues.txt \
  | head -n200 \
  | awk '{print $1}' \
  | while read -r ISSUE_ID; do
  echo "- $ISSUE_ID"
  gh -R glg/devops-meetings issue view "${ISSUE_ID}" \
    --comments \
    --json comments \
    --jq '.comments[] | select(.author.login=="datfinesoul")' \
    >> datfinesoul.json
done

<datfinesoul.json jq -r '.body' > datfinesoul.md

