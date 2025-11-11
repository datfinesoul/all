# GitHub Standup Comments Collector

## Overview

`pull-my-comments.bash` is a bash script that collects your GitHub standup comments from an organization's meetings repository and compiles them into a markdown document for employee self-review purposes.

## Purpose

This script automates the extraction of your contributions from GitHub standup issues, making it easier to prepare annual performance reviews by gathering a year's worth of your activity, comments, and referenced work.

## Workflow Context

This is **Phase 1** (data collection) of a two-phase self-review process:
- **Phase 1**: Download and compile GitHub data (this script)
- **Phase 2**: Organize and format for HR review (separate/manual process)

## Key Features

- Fetches issues labeled "Standup" from configurable GitHub repository
- Downloads issue details with all comments as JSON
- Filters comments to only those authored by specified GitHub user
- Resolves GitHub issue/PR URLs to human-readable titles
- Caches downloaded data to avoid redundant API calls
- Generates structured markdown output organized by issue

## Prerequisites

### Required Tools
- **GitHub CLI** (`gh`) - Must be authenticated with access to target repository
- **jq** - Command-line JSON processor
- **GNU sed** - Text processing (use `gsed` on macOS, `sed` on Linux)

### Repository Access
- Read access to the target GitHub repository (default: organization meetings repo)
- Authenticated GitHub CLI session: `gh auth status`

## Configuration

All configuration is passed via command-line flags. Parameters can be specified in any order.

## Usage

```bash
./pull-my-comments.bash -r <repo> -u <username> -l <label> [-y <year>] [-i <limit>] [-p <process_limit>] [-s <sed_cmd>]
```

**Parameters:**

**Required:**
- **`-r <repo>`** - Organization's standup/meetings repository (format: `owner/repo`)
- **`-u <username>`** - Your GitHub username
- **`-l <label>`** - GitHub issue label to filter on

**Optional:**
- **`-y <year>`** - Year to collect data for (default: current year)
- **`-i <limit>`** - Maximum issues to fetch (default: `300`)
- **`-p <limit>`** - Maximum issues to process (default: `200`)
- **`-s <cmd>`** - Sed command to use: `sed` or `gsed` (default: `sed`)

**Examples:**

```bash
# Minimal - uses all defaults
./pull-my-comments.bash -r glg/devops-meetings -u myusername -l Standup

# Specify year
./pull-my-comments.bash -r glg/devops-meetings -u myusername -l Standup -y 2024

# macOS with gsed, custom limits
./pull-my-comments.bash -r glg/devops-meetings -u myusername -l Standup -s gsed -i 500 -p 300

# Parameters in any order
./pull-my-comments.bash -u myusername -l Standup -r glg/devops-meetings -y 2023
```

The script will:
1. Fetch list of standup issues for the configured year
2. Download individual issue details (skips already downloaded)
3. Extract your comments and compile into markdown
4. Resolve any GitHub URLs to readable titles

## Output Files

All output files are written to the `outputs/<username>/` directory:

- `outputs/<username>/issues.txt` - Cached list of standup issues
- `outputs/<username>/$year/issues/*.json` - Individual issue data files (one per issue)
- `outputs/<username>/$year.md` - **Final compiled markdown document** (e.g., `2025.md`)
- `outputs/<username>/before.md` - Backup created before URL resolution

## How It Works

### Phase 1: Issue Discovery
Queries GitHub for all issues labeled "Standup" matching the configured year, limited to 300 results.

### Phase 2: Issue Detail Extraction
Downloads full issue data including all comments as JSON. Only fetches issues not already cached locally. Processes up to 200 issues.

### Phase 3: Comment Filtering & Formatting
Parses JSON files to extract:
- Issue titles (formatted as markdown headers)
- Your comment bodies (filtered by GitHub username)

### Phase 4: URL Resolution
Scans generated markdown for GitHub issue/PR URLs and replaces them with formatted titles:
```
https://github.com/user/repo/issues/123
↓
user/repo: Issue Title Here
```

## Script Behavior

- **Idempotent**: Safe to run multiple times (checks for existing downloads)
- **Incremental**: Only fetches missing issue details
- **Non-destructive**: Creates backup before URL replacement
- **Error-strict**: Exits immediately on errors (`set -euo pipefail`)

## Limitations

- Requires all parameters to be passed as command-line arguments
- Organization/formatting of output for HR review is a separate step
- Platform-specific sed command must be specified (gsed/sed)

## Example Output Format

```markdown
### Weekly Standup - Jan 8, 2024
Worked on migrating S3 state backend. Completed PR #456 for infrastructure updates.
Referenced: user/repo: Fix terraform state locking issue

### Weekly Standup - Jan 15, 2024
Implemented new CI/CD pipeline for automated deployments.
```
