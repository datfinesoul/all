# GitHub Activity Collector for Self-Review

## Overview

`pull-my-comments.bash` is a bash script that collects your GitHub activity from an organization, including standup comments and issue involvement (assigned/authored), and compiles them into a date-organized markdown document for employee self-review purposes.

## Purpose

This script automates the extraction of your contributions across GitHub, making it easier to prepare annual performance reviews by gathering a year's worth of your standup comments and issue involvement, organized chronologically by date.

## Workflow Context

This is **Phase 1** (data collection) of a two-phase self-review process:
- **Phase 1**: Download and compile GitHub data (this script)
- **Phase 2**: Organize and format for HR review (separate/manual process)

## Key Features

- **Standup Comments**: Fetches issues labeled "Standup" from configurable GitHub repository and extracts your comments
- **Issue Involvement**: Discovers issues org-wide where you were assigned or the author
- **Date Organization**: Compiles activity chronologically with separate Standup and Involvement sections per date
- **Participation Tracking**: Marks issues with participation type: [Assigned], [Author], or [Assigned+Author]
- **Smart Caching**: Caches all downloaded data to avoid redundant API calls and respect rate limits
- **URL Resolution**: Resolves GitHub issue/PR URLs to human-readable titles
- **Separate Cache Directories**: Standup and involved issues stored separately for easier management

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
1. Fetch list of standup issues from the specified repository
2. Discover assigned/authored issues org-wide (extracts org from repo parameter)
3. Download individual issue details for both standup and involved issues
4. Extract your comments from standup issues and determine participation type for involved issues
5. Compile into date-organized markdown with separate Standup and Involvement sections
6. Resolve any GitHub URLs to readable titles

## Output Files

All output files are written to the `outputs/<username>/` directory:

**Standup Issue Cache:**
- `outputs/<username>/issues.txt` - Cached list of standup issues
- `outputs/<username>/$year/standup/*.json` - Individual standup issue data files

**Involved Issues Cache:**
- `outputs/<username>/involved-issues-$year.json` - Cached list of assigned/authored issues
- `outputs/<username>/$year/involved-issues/owner_repo_123.json` - Individual involved issue data with participation type

**Other Files:**
- `outputs/<username>/url_cache/*.txt` - Cached GitHub issue/PR titles for URL resolution
- `outputs/<username>/$year.md` - **Final compiled markdown document** (e.g., `2025.md`)
- `outputs/<username>/before.md` - Backup created before URL resolution

## How It Works

### Phase 1: Standup Issue Discovery
Queries GitHub for all issues labeled with the specified label (e.g., "Standup") from the configured repository, matching the configured year.

### Phase 2: Standup Issue Detail Extraction
Downloads full issue data including all comments as JSON. Only fetches issues not already cached locally.

### Phase 2b: Involved Issues Discovery
Extracts organization from repo parameter and runs 4 queries:
- Assigned to you + created in year
- Assigned to you + closed in year
- Authored by you + created in year
- Authored by you + closed in year

Combines and deduplicates results by URL.

### Phase 2c: Involved Issue Detail Extraction
Downloads full issue details and determines participation type:
- **[Assigned]**: You are an assignee
- **[Author]**: You authored the issue
- **[Assigned+Author]**: Both assigned and author
- **[Involved]**: Other participation (fallback)

### Phase 3: Date-Organized Compilation
Groups all activity by date and generates markdown:
- **Standup sections**: Extract date from issue title, include your comments
- **Involvement sections**: Use closed date (preferred) or created date, include issue summary
- Sorts chronologically with date headers

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
./cache-clear.bash -u <username> -i  # Clear standup issue list
./cache-clear.bash -u <username> -j  # Clear JSON details (standup + involved)
./cache-clear.bash -u <username> -v  # Clear involved issues list
./cache-clear.bash -u <username> -c  # Clear URL titles

# Clear multiple caches
./cache-clear.bash -u <username> -i -v  # Clear all list caches

# Clear everything
./cache-clear.bash -u <username> -a
```

**Cache Types:**
- **Standup issue list** (`-i`): The initial list of standup issues from the repository
- **JSON details** (`-j`): Full issue data for both standup and involved issues
- **Involved issues list** (`-v`): The list of assigned/authored issues from org-wide search
- **URL titles** (`-c`): Cached titles for GitHub issue/PR URL resolution

**Why clear cache:**
- Standup issue list: When new standup issues are added to the repository
- JSON details: When comments/issues are updated
- Involved issues list: When you're assigned new issues or author new issues
- URL titles: When issue/PR titles are changed (rare)

## Example Output Format

```markdown
## 2024-01-08

### Standup

**Weekly Standup - Jan 8, 2024**
Worked on migrating S3 state backend. Completed PR #456 for infrastructure updates.
Referenced: user/repo: Fix terraform state locking issue

### Involvement

**[Assigned] glg/platform#123: Fix authentication timeout**
Updated authentication service to handle session timeouts more gracefully. Added retry logic and improved error messaging.

**[Author] glg/infrastructure#456: Migrate S3 state backend**
Migrated Terraform state from local to S3 backend with DynamoDB locking for team collaboration.

## 2024-01-15

### Standup

**Weekly Standup - Jan 15, 2024**
Implemented new CI/CD pipeline for automated deployments.

### Involvement

**[Assigned+Author] glg/devops#789: Automate deployment pipeline**
Created GitHub Actions workflow for automated testing and deployment to staging environment.
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
