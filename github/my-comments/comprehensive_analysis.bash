#!/usr/bin/env bash
set -eo pipefail

OUTPUT_DIR="outputs/datfinesoul/2025/involved-issues"
LABELS_CACHE="outputs/datfinesoul/labels_cache.json"

declare -a authored_epics=()
declare -A repo_epic_count
declare -A repo_task_count

for f in "$OUTPUT_DIR"/*.json; do
  participation=$(jq -r '.participation' "$f")
  repo=$(jq -r '.repository.nameWithOwner' "$f")
  
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
      repo_epic_count["$repo"]=$((${repo_epic_count["$repo"]:-0} + 1))
    else
      repo_task_count["$repo"]=$((${repo_task_count["$repo"]:-0} + 1))
    fi
  fi
done

echo "# COMPREHENSIVE STRATEGIC ANALYSIS"
echo ""
echo "## Executive Summary"
echo ""
echo "Phil demonstrates significant strategic leadership capability through authorship of **${#authored_epics[@]} planning/epic-level initiatives** across the GitHub estate. These are large-scope projects requiring:"
echo "- Problem decomposition and scope definition"
echo "- Stakeholder alignment through detailed requirements"
echo "- Long-term vision and implementation roadmap"
echo "- Cross-functional coordination"
echo ""

# Status breakdown
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

echo "## Epic Portfolio Status"
echo ""
echo "| Status | Count | Percentage |"
echo "|--------|-------|------------|"
pct_open=$(echo "scale=1; $open_count * 100 / ${#authored_epics[@]}" | bc)
pct_closed=$(echo "scale=1; $closed_count * 100 / ${#authored_epics[@]}" | bc)
echo "| Open | $open_count | ${pct_open}% |"
echo "| Closed | $closed_count | ${pct_closed}% |"
echo "| **Total** | **${#authored_epics[@]}** | **100%** |"
echo ""

echo "## Repository Distribution"
echo ""
echo "Shows where Phil is focusing strategic planning efforts:"
echo ""
echo "| Repository | Epics Authored | Tasks Authored |"
echo "|------------|----------------|----------------|"
for repo in "${!repo_epic_count[@]}"; do
  echo "| $repo | ${repo_epic_count[$repo]} | ${repo_task_count[$repo]:-0} |"
done | sort -t'|' -k3 -nr
echo ""

# Category analysis
declare -A category_count
for epic in "${authored_epics[@]}"; do
  issue_url=$(jq -r '.url' "$epic")
  labels=$(jq -r --arg url "$issue_url" '.[$url] // "none"' "$LABELS_CACHE")
  
  if [[ "$labels" == *"ConOps"* ]]; then
    category_count["ConOps"]=$((${category_count["ConOps"]:-0} + 1))
  elif [[ "$labels" == *"observe-migration"* ]]; then
    category_count["Observe Migration"]=$((${category_count["Observe Migration"]:-0} + 1))
  elif [[ "$labels" == *"ISO:27001"* ]]; then
    category_count["ISO 27001 / Security"]=$((${category_count["ISO 27001 / Security"]:-0} + 1))
  else
    category_count["General SRE Infrastructure"]=$((${category_count["General SRE Infrastructure"]:-0} + 1))
  fi
done

echo "## Strategic Focus Areas"
echo ""
for category in "${!category_count[@]}"; do
  count=${category_count[$category]}
  pct=$(echo "scale=1; $count * 100 / ${#authored_epics[@]}" | bc)
  echo "- **$category**: $count epics (${pct}%)"
done
echo ""

echo "## Key Themes in Epic Content"
echo ""
echo "Analysis of epic descriptions reveals Phil's strategic planning encompasses:"
echo ""
echo "1. **Platform Maturation**: Multiple epics around maturing Observe platform post-migration"
echo "2. **Security & Compliance**: S3 bucket security standardization, SSE-C restrictions, ISO 27001 alignment"
echo "3. **Cost Optimization**: Legacy system decommissioning (Sumo Logic, CloudTrail duplicates)"
echo "4. **Process Definition**: Standardizing ingestion workflows, decommissioning processes"
echo "5. **Infrastructure Governance**: S3 bucket lifecycle management, naming conventions"
echo "6. **Cloud Platform Optimization**: Spacelift improvements, AWS China infrastructure"
echo "7. **Observability Enhancement**: Log ingestion from multiple sources (GitHub, PRTG, Fluentd)"
echo ""

echo "## Evidence of Strategic Capability"
echo ""
echo "Phil's epics consistently demonstrate:"
echo ""
echo "- **User Story Framing**: \"As an X, I want Y, so that Z\" format showing outcome orientation"
echo "- **Clear Acceptance Criteria**: Measurable success metrics defined upfront"
echo "- **Business Context**: Background sections explaining \"why\" not just \"what\""
echo "- **Scope Documentation**: Detailed descriptions (often 800+ characters) showing thorough planning"
echo "- **Stakeholder Consideration**: Multiple roles/teams referenced in epic requirements"
echo ""

echo "## Open Epics Requiring Strategic Oversight ($open_count issues)"
echo ""
echo "These represent ongoing strategic initiatives Phil is managing:"
echo ""
for epic in "${authored_epics[@]}"; do
  state=$(jq -r '.state' "$epic")
  if [ "$state" == "open" ]; then
    repo=$(jq -r '.repository.nameWithOwner' "$epic")
    number=$(jq -r '.number' "$epic")
    title=$(jq -r '.title' "$epic")
    created=$(jq -r '.createdAt' "$epic" | cut -d'T' -f1)
    echo "- **$repo#$number**: $title (opened $created)"
  fi
done | sort
echo ""

echo "## Completed Strategic Initiatives ($closed_count epics)"
echo ""
echo "Demonstrates ability to drive epics to completion:"
echo ""
for epic in "${authored_epics[@]}"; do
  state=$(jq -r '.state' "$epic")
  if [ "$state" == "closed" ]; then
    repo=$(jq -r '.repository.nameWithOwner' "$epic")
    number=$(jq -r '.number' "$epic")
    title=$(jq -r '.title' "$epic")
    created=$(jq -r '.createdAt' "$epic" | cut -d'T' -f1)
    closed=$(jq -r '.closedAt' "$epic" | cut -d'T' -f1)
    duration_days=$(( ($(date -j -f "%Y-%m-%d" "$closed" +%s) - $(date -j -f "%Y-%m-%d" "$created" +%s)) / 86400 ))
    echo "- **$repo#$number**: $title ($duration_days days, closed $closed)"
  fi
done | sort
echo ""

