#!/usr/bin/env bash
# vi: set noet :
set -euo pipefail
IFS=$'\n\t'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sed_command="${sed_command:-sed}"

# Cleanup trap to remove temp files on exit
cleanup() {
  true
}
trap cleanup EXIT

# Color definitions for logging
red="$(tput setaf 1)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"
cyan="$(tput setaf 6)"
white="$(tput setaf 7)"
gray="$(tput dim)$(tput setaf 7)"
magenta="$(tput setaf 5)"
reset="$(tput sgr0)"

# Logging functions with color support
custom_log() {
    local prefix="$1"
    local postfix="$2"
    shift 2
    local epoch="$(date +%s)"
    if [[ -p /dev/stdin && "$#" -eq 0 ]]; then
        while IFS= read -r line || [ -n "$line" ]; do
            >&2 echo -e "${epoch} ${prefix}${line}${postfix}"
        done
    else
        >&2 echo -e "${epoch} ${prefix}$*${postfix}"
    fi
}
plain() { custom_log "" "" "$@"; }
info() { custom_log "[i] " "" "$@"; }
debug() { custom_log "[${gray}D${reset}]${gray} " "${reset}" "$@"; }
pass() { custom_log "[${green}✔${reset}]${green} " "${reset}" "$@"; }
warn() { custom_log "[${magenta}!${reset}]${magenta} " "${reset}" "$@"; }
fail() { custom_log "[${red}✘${reset}]${red} " "${reset}" "$@"; }

# Output ISO timestamp at script start
>&2 echo "START: $(date -Iseconds)"

# Sed compatibility: Detect if we need GNU sed for in-place editing.
# macOS users may have installed GNU sed as 'gsed' or symlinked as
# 'sed'. We test for GNU sed support and fail early if unavailable.
if [[ "$sed_command" == "sed" ]]; then
  # Check if this sed supports GNU-style in-place editing
  if ! sed --version 2>&1 | grep -q "GNU"; then
    # Not GNU sed - check if gsed is available
    if command -v gsed &> /dev/null; then
      info "Using gsed instead of sed for GNU compatibility"
      sed_command="gsed"
    else
      fail "Error: GNU sed required. Install with: brew install gnu-sed"
      fail "Or specify sed command with: -s gsed"
      exit 1
    fi
  fi
elif [[ "$sed_command" == "gsed" ]]; then
  # User explicitly requested gsed - verify it exists
  if ! command -v gsed &> /dev/null; then
    fail "Error: gsed not found. Install with: brew install gnu-sed"
    exit 1
  fi
fi

# Function to filter comments from JSON file and extract PR description
# Removes comments where author.login is "spacelift-io" or "github-actions"
# Extracts only the meaningful description from PR template
filter_bot_comments() {
  local input_file="$1"
  local output_file="$2"

  jq '
    # Filter bot comments
    (if .comments then
      .comments |= map(select(.author.login != "spacelift-io" and .author.login != "github-actions"))
    else . end) |
    
    # Extract meaningful description from template
    (if .body then
      .body |= (. | 
        # Normalize line endings
        gsub("\r\n"; "\n") |
        # Split into lines
        split("\n") |
        # Find start of description section (after first ####)
        (. as $lines | 
          (reduce range(0; length) as $i (null; 
            if . == null and ($lines[$i] | test("^#### Document the change")) then $i else . end)) as $start |
          # Find "What type of testing" header specifically
          (reduce range($start + 1; length) as $i (null;
            if . == null and ($lines[$i] | test("^#### What type of testing")) then $i else . end)) as $end |
          # Extract lines between headers, skip empty and template placeholders
          if $start != null then
            $lines[($start + 1):($end // length)] |
            map(select(. != "" and (test("^>") | not))) |
            join("\n")
          else . end)
      )
    else . end)
  ' "$input_file" > "$output_file"
}

# Filter standup comments by user and mentions
# Removes the issue body and keeps only comments by user or mentioning name
filter_standup_comments() {
  local input_file="$1"
  local output_file="$2"
  local username="$3"
  local mention_name="$4"

  jq --arg user "$username" --arg mention "$mention_name" '
    # Remove the body field
    .body = "" |
    # Filter comments after body removal
    if .comments then
      .comments |= map(select(
        .author.login == $user or 
        (.body | ascii_downcase | contains($mention | ascii_downcase))
      ))
    else . end
  ' "$input_file" > "$output_file"
}

# Process involved-prs for both users
process_user_prs() {
  local username="$1"
  local input_dir="$SCRIPT_DIR/outputs/$username/2025/involved-prs"
  local output_dir="$SCRIPT_DIR/outputs/$username/2025/transforms/involved-prs"

  if [[ ! -d "$input_dir" ]]; then
    warn "Input directory does not exist: $input_dir"
    return
  fi

  mkdir -p "$output_dir"

  local file_count=0
  local filtered_count=0
  local total_files=$(find "$input_dir" -name "*.json" -type f | wc -l | tr -d ' ')

  info "Processing $username involved-prs ($total_files files)"

  for json_file in "$input_dir"/*.json; do
    if [[ ! -f "$json_file" ]]; then
      continue
    fi

    local filename="$(basename "$json_file")"
    local output_file="$output_dir/$filename"

    filter_bot_comments "$json_file" "$output_file"

    ((file_count++))

    # Progress update every 25 files
    if [[ $((file_count % 25)) -eq 0 ]]; then
      info "Progress: $file_count/$total_files files processed"
    fi
  done

  pass "Processed $file_count files for $username"
}

# Process standup files for a user
process_user_standup() {
  local username="$1"
  local mention_name="$2"
  local input_dir="$SCRIPT_DIR/outputs/$username/2025/standup"
  local output_dir="$SCRIPT_DIR/outputs/$username/2025/transforms/standup"

  if [[ ! -d "$input_dir" ]]; then
    warn "Input directory does not exist: $input_dir"
    return
  fi

  mkdir -p "$output_dir"

  local file_count=0
  local kept_count=0
  local total_files=$(find "$input_dir" -name "*.json" -type f | wc -l | tr -d ' ')

  info "Processing $username standup ($total_files files, filtering for: $username or mentions of '$mention_name')"

  for json_file in "$input_dir"/*.json; do
    if [[ ! -f "$json_file" ]]; then
      continue
    fi

    local filename="$(basename "$json_file")"
    local output_file="$output_dir/$filename"

    filter_standup_comments "$json_file" "$output_file" "$username" "$mention_name"

    ((file_count++))

    # Check if there are any comments left, remove file if empty
    local comment_count=$(jq -r '.comments | length' "$output_file" 2>/dev/null || echo 0)
    if [[ "$comment_count" -eq 0 ]]; then
      rm "$output_file"
    else
      ((kept_count++))
    fi

    # Progress update every 25 files
    if [[ $((file_count % 25)) -eq 0 ]]; then
      info "Progress: $file_count/$total_files files processed"
    fi
  done

  pass "Processed $file_count standup files for $username ($kept_count kept, $((file_count - kept_count)) removed)"
}

# Process involved-issues using opencode to summarize
process_user_issues() {
  local username="$1"
  local input_dir="$SCRIPT_DIR/outputs/$username/2025/involved-issues"
  local output_dir="$SCRIPT_DIR/outputs/$username/2025/transforms/involved-issues"

  if [[ ! -d "$input_dir" ]]; then
    warn "Input directory does not exist: $input_dir"
    return
  fi

  mkdir -p "$output_dir"

  local file_count=0
  local skipped_count=0
  local generated_count=0
  local total_files=$(find "$input_dir" -name "*.json" -type f | wc -l | tr -d ' ')

  info "Processing $username involved-issues ($total_files files, using opencode for summaries)"

  for json_file in "$input_dir"/*.json; do
    if [[ ! -f "$json_file" ]]; then
      continue
    fi

    local filename="$(basename "$json_file" .json)"
    local output_file="$output_dir/${filename}.md"

    ((file_count++))
    
    # Skip if summary already exists
    if [[ -f "$output_file" ]]; then
      ((skipped_count++))
      continue
    fi
    
    debug "[$file_count/$total_files] Summarizing $filename"
    
    # Run opencode to summarize the issue
    opencode run "summarize the $json_file file, add a footer about author, assignees, and overall work" > "$output_file" 2>&1
    
    ((generated_count++))

    # Progress update every 10 files
    if [[ $((file_count % 10)) -eq 0 ]]; then
      info "Progress: $file_count/$total_files issues processed ($generated_count generated, $skipped_count skipped)"
    fi
  done

  pass "Processed $file_count issue files for $username ($generated_count generated, $skipped_count skipped)"
}

# Parse command line arguments
username=""
mention_name=""
while getopts "u:n:" opt; do
  case $opt in
    u) username="$OPTARG" ;;
    n) mention_name="$OPTARG" ;;
    *) 
      fail "Usage: $0 -u username [-n mention_name]"
      exit 1
      ;;
  esac
done

# Prompt for username if not provided
if [[ -z "$username" ]]; then
  >&2 echo -n "Enter username to process: "
  read username
  if [[ -z "$username" ]]; then
    fail "Username is required"
    exit 1
  fi
fi

# Prompt for mention name if not provided
if [[ -z "$mention_name" ]]; then
  >&2 echo -n "Enter name to filter mentions (leave empty to skip standup processing): "
  read mention_name
fi

# Main execution
info "Starting bot comment filter transformation for user: $username"

process_user_prs "$username" || warn "Failed processing $username involved-prs"

if [[ -n "$mention_name" ]]; then
  info "Processing standup files with mention filter: $mention_name"
  process_user_standup "$username" "$mention_name" || warn "Failed processing $username standup"
else
  info "Skipping standup processing"
fi

process_user_issues "$username" || warn "Failed processing $username involved-issues"

pass "Transformation complete for $username"

# Output ISO timestamp at script end
>&2 echo "END: $(date -Iseconds)"
