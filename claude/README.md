# Claude Code Docker Setup

Run Claude Code in an isolated Docker container with limited host system exposure while maintaining git repository access.

## Prerequisites

- Docker with Compose v2
- OAuth credentials at `~/.claude/.credentials.json` and `~/.claude.json`
- Or an Anthropic API key

## Quick Start

### 1. Build the Container

```bash
docker compose build
```

This creates a container with:
- Node.js 20
- Claude Code CLI
- Git, ripgrep, zsh, and development tools

### 2. Run Claude Code

**Using wrapper script:**
```bash
./run-claude-docker.sh
```

**Direct docker compose:**
```bash
docker compose run --rm claude-code
```

**With specific command:**
```bash
docker compose run --rm claude-code chat
```

## Making It Accessible

### Option 1: Shell Alias

Add to `~/.bashrc` or `~/.zshrc`:

```bash
alias claude-docker='docker compose -f /home/philip.hadviger/github/datfinesoul/all/claude/docker-compose.yml run --rm claude-code'
```

Then reload:
```bash
source ~/.bashrc  # or ~/.zshrc
```

Usage:
```bash
claude-docker chat
claude-docker "analyze the codebase"
```

### Option 2: Wrapper in PATH

Create `/usr/local/bin/claude-docker`:

```bash
sudo tee /usr/local/bin/claude-docker > /dev/null <<'EOF'
#!/bin/bash
cd /home/philip.hadviger/github/datfinesoul/all/claude
exec docker compose run --rm claude-code "$@"
EOF

sudo chmod +x /usr/local/bin/claude-docker
```

Usage:
```bash
claude-docker chat
claude-docker "help me debug this"
```

### Option 3: Symlink Wrapper Script

```bash
sudo ln -s /home/philip.hadviger/github/datfinesoul/all/claude/run-claude-docker.sh /usr/local/bin/claude-docker
```

Usage:
```bash
claude-docker
```

## Authentication

### OAuth (Default)

Automatically uses credentials from:
- `~/.claude/.credentials.json` (OAuth tokens)
- `~/.claude.json` (account metadata)

These are mounted read-only and copied to the container on startup.

### API Key

If you have an API key instead:

```bash
docker compose run --rm -e ANTHROPIC_API_KEY='sk-ant-...' claude-code
```

Or modify `run-claude-docker.sh` to export the key before running.

## Configuration

### Container Isolation

- **Config directory**: Fresh container-only config at `/home/node/.claude` (persisted in `claude-code-config` volume)
- **Credentials**: Copied from host on each run (read-only mounts)
- **Git repo**: Mounted at `/workspace` (read-write)

### Volumes

- `claude-code-config`: Persists Claude settings and state
- `claude-code-history`: Persists shell history

To reset container state:
```bash
docker volume rm claude-code-config claude-code-history
```

## File Structure

```
.
├── .docker/
│   ├── Dockerfile              # Container definition
│   ├── entrypoint.sh           # Startup script (copies credentials)
│   └── settings.json.template  # Reference config
├── docker-compose.yml          # Volume mounts and orchestration
├── run-claude-docker.sh        # Convenience wrapper
├── debug-docker.sh             # Debugging utility
└── .dockerignore               # Build exclusions
```

## Troubleshooting

### Debug Container State

```bash
./debug-docker.sh
```

### Rebuild After Changes

```bash
docker compose build --no-cache
```

### Check Logs

```bash
docker compose run --rm --entrypoint bash claude-code
```

### Authentication Errors

Ensure host credentials are current:
```bash
# Refresh tokens on host
claude --version

# Verify files exist
ls -la ~/.claude/.credentials.json ~/.claude.json
```

## Customization

### Change Claude Version

Edit `docker-compose.yml`:
```yaml
args:
  CLAUDE_VERSION: 2.0.65  # Specify version
```

### Modify Permissions

Edit `.docker/settings.json.template` and rebuild.

### Change Timezone

Edit `docker-compose.yml`:
```yaml
args:
  TZ: America/New_York
```

## Notes

- Container runs as non-root `node` user (UID 1000)
- Git operations inherit container user identity
- No Docker-in-Docker capability
- SSH keys not mounted (container-only git operations)
- Full internet access (no network restrictions)
