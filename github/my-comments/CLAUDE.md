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

**Edit these three values in the script before running:**

1. **Line 6** - `year=2024`
   - Set to the year you want to collect data for

2. **Line 10** - `-R glg/devops-meetings`
   - Set to your organization's standup/meetings repository
   - Format: `owner/repo`

3. **Line 35** - `.author.login=="GITHUBUSERNAME"`
   - Replace `GITHUBUSERNAME` with your actual GitHub username

## Usage

```bash
./pull-my-comments.bash
```

The script will:
1. Fetch list of standup issues for the configured year
2. Download individual issue details (skips already downloaded)
3. Extract your comments and compile into markdown
4. Resolve any GitHub URLs to readable titles

## Output Files

- `issues.txt` - Cached list of standup issues
- `$year/issues/*.json` - Individual issue data files (one per issue)
- `$year.md` - **Final compiled markdown document** (e.g., `2024.md`)
- `before.md` - Backup created before URL resolution

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

- Requires manual editing of configuration variables
- Limited to 300 issues and 200 issue details per run
- Organization/formatting of output for HR review is a separate step
- Platform-specific sed command (`gsed` on macOS may need adjustment for Linux)

## Example Output Format

```markdown
### Weekly Standup - Jan 8, 2024
Worked on migrating S3 state backend. Completed PR #456 for infrastructure updates.
Referenced: user/repo: Fix terraform state locking issue

### Weekly Standup - Jan 15, 2024
Implemented new CI/CD pipeline for automated deployments.
```
