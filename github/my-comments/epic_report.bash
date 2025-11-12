#!/usr/bin/env bash
set -eo pipefail

OUTPUT_DIR="outputs/datfinesoul/2025/involved-issues"
LABELS_CACHE="outputs/datfinesoul/labels_cache.json"

declare -a authored_epics=()
declare -a authored_tasks=()

for f in "$OUTPUT_DIR"/*.json; do
  participation=$(jq -r '.participation' "$f")
  
  if [[ "$participation" == "Author" ]] || [[ "$participation" == "Assigned+Author" ]]; then
    title=$(jq -r '.title' "$f")
    body=$(jq -r '.body // ""' "$f")
    
    # Determine if epic/planning based on content
    is_epic=0
    if [[ "$title" == *"Epic"* ]] || \
       [[ "$body" == *"## Background"* ]] || \
       [[ "$body" == *"Acceptance Criteria"* ]] || \
       [[ "$body" == *"## Acceptance Criteria"* ]] || \
       [[ "$body" == *"## Goals"* ]] || \
       [[ ${#body} -gt 800 ]]; then
      is_epic=1
      authored_epics+=("$f")
    else
      authored_tasks+=("$f")
    fi
  fi
done

echo "# PHIL'S STRATEGIC PLANNING ANALYSIS"
echo ""
echo "## Summary Statistics"
echo ""
echo "- **Total Epics/Planning Issues Authored:** ${#authored_epics[@]}"
echo "- **Total Tasks/Implementation Authored:** ${#authored_tasks[@]}"
echo "- **Strategic Work Percentage:** $(echo "scale=1; ${#authored_epics[@]} * 100 / (${#authored_epics[@]} + ${#authored_tasks[@]})" | bc)%"
echo ""

# Count open vs closed
open_count=0
closed_count=0
for epic in "${authored_epics[@]}"; do
  state=$(jq -r '.state' "$epic")
  if [ "$state" == "open" ]; then
    open_count=$((open_count + 1))
  else
    closed_count=$((closed_count + 1))
  fi
done

echo "## Epic Status"
echo "- **Open:** $open_count"
echo "- **Closed:** $closed_count"
echo ""

echo "## OPEN EPICS (Requiring Attention)"
echo ""
for epic in "${authored_epics[@]}"; do
  state=$(jq -r '.state' "$epic")
  if [ "$state" == "open" ]; then
    repo=$(jq -r '.repository.nameWithOwner' "$epic")
    number=$(jq -r '.number' "$epic")
    title=$(jq -r '.title' "$epic")
    created=$(jq -r '.createdAt' "$epic" | cut -d'T' -f1)
    issue_url=$(jq -r '.url' "$epic")
    labels=$(jq -r --arg url "$issue_url" '.[$url] // "none"' "$LABELS_CACHE")
    body=$(jq -r '.body // ""' "$epic")
    body_preview="${body:0:600}"
    
    echo "### $repo#$number: $title"
    echo "- **Created:** $created"
    echo "- **Labels:** $labels"
    echo "- **URL:** $issue_url"
    echo ""
    echo "<details><summary>Description</summary>"
    echo ""
    echo '```'
    echo "$body_preview"
    if [ ${#body} -gt 600 ]; then echo "..."; fi
    echo '```'
    echo ""
    echo "</details>"
    echo ""
  fi
done

echo "## CLOSED EPICS (Completed)"
echo ""
for epic in "${authored_epics[@]}"; do
  state=$(jq -r '.state' "$epic")
  if [ "$state" == "closed" ]; then
    repo=$(jq -r '.repository.nameWithOwner' "$epic")
    number=$(jq -r '.number' "$epic")
    title=$(jq -r '.title' "$epic")
    created=$(jq -r '.createdAt' "$epic" | cut -d'T' -f1)
    closed=$(jq -r '.closedAt' "$epic" | cut -d'T' -f1)
    issue_url=$(jq -r '.url' "$epic")
    labels=$(jq -r --arg url "$issue_url" '.[$url] // "none"' "$LABELS_CACHE")
    body=$(jq -r '.body // ""' "$epic")
    body_preview="${body:0:500}"
    
    echo "### $repo#$number: $title"
    echo "- **Created:** $created | **Closed:** $closed"
    echo "- **Labels:** $labels"
    echo "- **URL:** $issue_url"
    echo ""
    echo "<details><summary>Description</summary>"
    echo ""
    echo '```'
    echo "$body_preview"
    if [ ${#body} -gt 500 ]; then echo "..."; fi
    echo '```'
    echo ""
    echo "</details>"
    echo ""
  fi
done

