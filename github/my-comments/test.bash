#!/usr/bin/env bash
set -euo pipefail

# Issues assigned to you that were CREATED in 2025
gh search issues --assignee @me --owner glg --created "2025-01-01..2025-12-31" --limit 1000 --json number,title,url,createdAt,closedAt,repository,state > /tmp/created.json

# Issues assigned to you that were CLOSED in 2025
gh search issues --assignee @me --owner glg --closed "2025-01-01..2025-12-31" --limit 1000 --json number,title,url,createdAt,closedAt,repository,state > /tmp/closed.json

# Combine and deduplicate
jq -s 'add | unique_by(.url)' /tmp/created.json /tmp/closed.json

# Cleanup
rm -f /tmp/created.json /tmp/closed.json
