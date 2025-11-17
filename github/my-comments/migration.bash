#!/usr/bin/env bash
# vi: set noet :
set -euo pipefail
IFS=$'\n\t'

# Migration script: Move existing issue/PR files to shared cache
# and replace with symlinks in user directories.
#
# This script:
# 1. Scans all user directories for existing issue/PR JSON files
# 2. Moves files to shared cache (outputs/.shared-cache/)
# 3. Replaces originals with symlinks pointing to shared cache
# 4. Preserves file contents and directory structure
# 5. Skips files already migrated (existing symlinks)

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUTS_DIR="$SCRIPT_DIR/outputs"
SHARED_CACHE_DIR="$OUTPUTS_DIR/.shared-cache"
SHARED_ISSUES_CACHE="$SHARED_CACHE_DIR/issues"
SHARED_PRS_CACHE="$SHARED_CACHE_DIR/prs"
SHARED_TRANSFORMS_CACHE="$SHARED_CACHE_DIR/transforms"

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

# Create shared cache directories
info "Creating shared cache directories..."
mkdir -p "$SHARED_ISSUES_CACHE" "$SHARED_PRS_CACHE" "$SHARED_TRANSFORMS_CACHE"

# Migration counters
total_issues_moved=0
total_issues_skipped=0
total_prs_moved=0
total_prs_skipped=0
total_standups_moved=0
total_standups_skipped=0
total_transforms_moved=0
total_transforms_skipped=0

# Migrate involved issues
info "Scanning for involved issues to migrate..."
while IFS= read -r issue_file; do
  # Skip if already a symlink
  if [[ -L "$issue_file" ]]; then
    total_issues_skipped=$((total_issues_skipped + 1))
    continue
  fi
  
  # Extract username/year for debug output (relative to outputs dir)
  rel_path="${issue_file#$OUTPUTS_DIR/}"
  username="$(echo "$rel_path" | cut -d'/' -f1)"
  year="$(echo "$rel_path" | cut -d'/' -f2)"
  
  filename="$(basename "$issue_file")"
  shared_file="$SHARED_ISSUES_CACHE/$filename"
  
  # Move to shared cache if not already there
  if [[ ! -f "$shared_file" ]]; then
    debug "Moving $username/$year $filename to shared cache"
    mv "$issue_file" "$shared_file"
  else
    debug "Shared cache already has $filename, removing duplicate"
    rm "$issue_file"
  fi
  
  # Create relative symlink (from involved-issues dir to shared cache)
  # ../../../.shared-cache/issues/filename.json
  relative_path="../../../.shared-cache/issues/$filename"
  ln -sf "$relative_path" "$issue_file"
  total_issues_moved=$((total_issues_moved + 1))
done < <(find "$OUTPUTS_DIR" -path "$OUTPUTS_DIR/.shared-cache" -prune -o -path "*/transforms" -prune -o \( -type f -o -type l \) -path "*/involved-issues/*.json" -print)

# Migrate involved PRs
info "Scanning for involved PRs to migrate..."
while IFS= read -r pr_file; do
  # Skip if already a symlink
  if [[ -L "$pr_file" ]]; then
    total_prs_skipped=$((total_prs_skipped + 1))
    continue
  fi
  
  # Extract username/year for debug output (relative to outputs dir)
  rel_path="${pr_file#$OUTPUTS_DIR/}"
  username="$(echo "$rel_path" | cut -d'/' -f1)"
  year="$(echo "$rel_path" | cut -d'/' -f2)"
  
  filename="$(basename "$pr_file")"
  shared_file="$SHARED_PRS_CACHE/$filename"
  
  # Move to shared cache if not already there
  if [[ ! -f "$shared_file" ]]; then
    debug "Moving $username/$year $filename to shared cache"
    mv "$pr_file" "$shared_file"
  else
    debug "Shared cache already has $filename, removing duplicate"
    rm "$pr_file"
  fi
  
  # Create relative symlink (from involved-prs dir to shared cache)
  # ../../../.shared-cache/prs/filename.json
  relative_path="../../../.shared-cache/prs/$filename"
  ln -sf "$relative_path" "$pr_file"
  total_prs_moved=$((total_prs_moved + 1))
done < <(find "$OUTPUTS_DIR" -path "$OUTPUTS_DIR/.shared-cache" -prune -o -path "*/transforms" -prune -o \( -type f -o -type l \) -path "*/involved-prs/*.json" -print)

# Migrate standup issues
info "Scanning for standup issues to migrate..."
while IFS= read -r standup_file; do
  # Skip if already a symlink
  if [[ -L "$standup_file" ]]; then
    total_standups_skipped=$((total_standups_skipped + 1))
    continue
  fi
  
  # Extract username, year, and parent directory (relative to outputs dir)
  rel_path="${standup_file#$OUTPUTS_DIR/}"
  username="$(echo "$rel_path" | cut -d'/' -f1)"
  year="$(echo "$rel_path" | cut -d'/' -f2)"
  year_dir="$OUTPUTS_DIR/$username/$year"
  
  # Extract repo info from the standup-issues list file
  # Look for standup-issues_OWNER_REPO.json in same year directory
  standup_list_file="$(find "$year_dir" -maxdepth 1 -name "standup-issues_*.json" -type f 2>/dev/null | head -n 1)"
  
  if [[ -z "$standup_list_file" ]]; then
    warn "Cannot find standup-issues list for $username/$year, skipping standup migration"
    continue
  fi
  
  # Extract owner and repo from filename: standup-issues_OWNER_REPO.json
  standup_list_basename="$(basename "$standup_list_file")"
  # Remove standup-issues_ prefix and .json suffix
  owner_repo="${standup_list_basename#standup-issues_}"
  owner_repo="${owner_repo%.json}"
  # Split on underscore to get owner and repo
  repo_owner="$(echo "$owner_repo" | cut -d'_' -f1)"
  repo_name="$(echo "$owner_repo" | cut -d'_' -f2-)"
  
  issue_num="$(basename "$standup_file" .json)"
  filename="${repo_owner}_${repo_name}_${issue_num}.json"
  shared_file="$SHARED_ISSUES_CACHE/$filename"
  
  # Move to shared cache if not already there
  if [[ ! -f "$shared_file" ]]; then
    debug "Moving $username/$year standup $issue_num to shared cache as $filename"
    mv "$standup_file" "$shared_file"
  else
    debug "Shared cache already has $filename, removing duplicate"
    rm "$standup_file"
  fi
  
  # Create relative symlink (from standup dir to shared cache)
  # ../../../.shared-cache/issues/filename.json
  relative_path="../../../.shared-cache/issues/$filename"
  ln -sf "$relative_path" "$standup_file"
  total_standups_moved=$((total_standups_moved + 1))
done < <(find "$OUTPUTS_DIR" -path "$OUTPUTS_DIR/.shared-cache" -prune -o -path "*/transforms" -prune -o \( -type f -o -type l \) -path "*/standup/*.json" -print)

# Migrate involved-issues transforms (markdown summaries)
info "Scanning for involved-issues transforms to migrate..."
while IFS= read -r transform_file; do
  # Skip if already a symlink
  if [[ -L "$transform_file" ]]; then
    total_transforms_skipped=$((total_transforms_skipped + 1))
    continue
  fi
  
  # Extract username/year for debug output (relative to outputs dir)
  rel_path="${transform_file#$OUTPUTS_DIR/}"
  username="$(echo "$rel_path" | cut -d'/' -f1)"
  year="$(echo "$rel_path" | cut -d'/' -f2)"
  
  filename="$(basename "$transform_file")"
  shared_file="$SHARED_TRANSFORMS_CACHE/$filename"
  
  # Move to shared cache if not already there
  if [[ ! -f "$shared_file" ]]; then
    debug "Moving $username/$year transform $filename to shared cache"
    mv "$transform_file" "$shared_file"
  else
    debug "Shared cache already has $filename, removing duplicate"
    rm "$transform_file"
  fi
  
  # Create relative symlink (from transforms/involved-issues dir to shared cache)
  # ../../../../.shared-cache/transforms/filename.md
  relative_path="../../../../.shared-cache/transforms/$filename"
  ln -sf "$relative_path" "$transform_file"
  total_transforms_moved=$((total_transforms_moved + 1))
done < <(find "$OUTPUTS_DIR" -path "$OUTPUTS_DIR/.shared-cache" -prune -o \( -type f -o -type l \) -path "*/transforms/involved-issues/*.md" -print)

# Summary
info "Migration complete!"
pass "Involved issues: $total_issues_moved migrated, $total_issues_skipped already symlinks"
pass "Involved PRs: $total_prs_moved migrated, $total_prs_skipped already symlinks"
pass "Standup issues: $total_standups_moved migrated, $total_standups_skipped already symlinks"
pass "Issue transforms: $total_transforms_moved migrated, $total_transforms_skipped already symlinks"

total_moved=$((total_issues_moved + total_prs_moved + total_standups_moved + total_transforms_moved))
total_skipped=$((total_issues_skipped + total_prs_skipped + total_standups_skipped + total_transforms_skipped))

pass "Total: $total_moved files migrated to shared cache, $total_skipped already migrated"
info "Shared cache location: $SHARED_CACHE_DIR"

# Output ISO timestamp at script end
>&2 echo "END: $(date -Iseconds)"
