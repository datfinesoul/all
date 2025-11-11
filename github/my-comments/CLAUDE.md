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
- **GNU sed** - Text processing
  - Linux: Usually pre-installed as `sed`
  - macOS: Install with `brew install gnu-sed` (creates `gsed` command)
  - Script auto-detects GNU sed and falls back to `gsed` if needed

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
- **`-s <cmd>`** - Sed command: `sed` or `gsed` (default: `sed`, auto-detects GNU sed)

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
- `outputs/<username>/url_cache/*.txt` - Cached GitHub issue/PR titles for URL resolution
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
- **User-isolated**: Organizes outputs by username to support multiple users
- **Validated**: Checks for required parameters before execution
- **Cached**: Reuses downloaded data to minimize API calls and rate limit impact
- **Platform-aware**: Auto-detects GNU sed availability and provides helpful install messages

## Limitations

- Three required parameters: repo, username, and label must be provided
- Organization/formatting of output for HR review is a separate step
- Requires GNU sed (script auto-detects and provides install guidance)
- Handles up to configured limits for issues (default 300 fetched, 200 processed)

## Cache Management

Use `cache-clear.bash` to view and manage cached data:

```bash
# View cache statistics (default)
./cache-clear.bash -u <username>

# Clear specific caches
./cache-clear.bash -u <username> -i  # Clear issue list
./cache-clear.bash -u <username> -j  # Clear JSON details
./cache-clear.bash -u <username> -c  # Clear URL titles

# Clear multiple caches
./cache-clear.bash -u <username> -i -c  # Clear issues and URLs

# Clear everything
./cache-clear.bash -u <username> -a
```

**Cache Types:**
- **Issue list** (`-i`): The initial list of issues fetched from GitHub
- **JSON details** (`-j`): Full issue data including all comments
- **URL titles** (`-c`): Cached titles for GitHub issue/PR URL resolution

**Why clear cache:**
- Issue list: When new issues are added to the repository
- JSON details: When comments are updated or added to existing issues
- URL titles: When issue/PR titles are changed (rare)

## Example Output Format

```markdown
### Weekly Standup - Jan 8, 2024
Worked on migrating S3 state backend. Completed PR #456 for infrastructure updates.
Referenced: user/repo: Fix terraform state locking issue

### Weekly Standup - Jan 15, 2024
Implemented new CI/CD pipeline for automated deployments.
```

## Development Guidelines

When modifying this script:

1. **Comments**: Explain purpose and rationale, not actions. Keep lines ≤75 chars.
2. **Parameters**: Use dash flags (`-r`, `-u`, etc.) for all configuration
3. **Defaults**: Only year, limits, and sed command have defaults - core params are required
4. **Output Structure**: All files go to `outputs/<username>/<year>/` for multi-user support
5. **Error Handling**: Validate inputs early, fail fast with clear error messages
6. **Caching**: Check for existing files before API calls to enable incremental runs
7. **Logging Format**: All messages use `>&2 echo "[X] message"` format where:
   - `[i]` = informational messages (general progress, completion)
   - `[d]` = debug messages (detailed per-item progress)
   - `[x]` = error messages (failures, missing requirements)
8. **Progress Reporting**: Provide status updates for all long-running operations to avoid appearance of hanging
9. **Sed Compatibility**: Use `-i'' -e` format for in-place edits (works on both BSD and GNU sed without creating backup files)
