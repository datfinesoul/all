# ADR 001: Using Docker Secrets with gosu for Credential Management

## Status

Accepted

## Context

The Claude Code CLI requires authentication credentials (`~/.claude/.credentials.json` and `~/.claude.json`) to function. When running Claude Code in Docker, these credentials need to be securely passed from the host to the container.

### Problem

Initial implementation attempted to mount credentials files directly:
```yaml
volumes:
  - ~/.claude/.credentials.json:/home/node/.claude-host-credentials.json:ro
```

This approach failed with permission errors:
```
cp: cannot open '/home/node/.claude-host-credentials.json' for reading: Permission denied
```

**Root cause:** File ownership mismatch between host user UID and container's `node` user UID. The mounted file retained the host's UID/GID, which the container's non-root user couldn't read.

### Alternatives Considered

1. **Direct file mount (rejected)**
   - Simple but fails due to UID mismatch
   - Only works if host and container UIDs match (not portable)

2. **Environment variables (rejected)**
   - Credentials visible in `docker inspect` output
   - Exposed to all container processes
   - Visible in logs during debugging
   - Security risk

3. **Run container as host UID (rejected)**
   - Requires `user: "${UID}:${GID}"` in docker-compose.yml
   - Breaks npm global package installation
   - Complicates container setup
   - Less portable across different host environments

4. **Docker Secrets with gosu (accepted)**
   - Secrets not exposed in `docker inspect`
   - Standard Docker pattern for sensitive data
   - Maintains security by running application as non-root
   - Allows root-level initialization tasks

## Decision

Use Docker Compose secrets to mount credential files, with an entrypoint script that:
1. Runs as root to access secrets at `/run/secrets/`
2. Copies secrets to the application config directory
3. Fixes file ownership
4. Drops to non-root `node` user via `gosu`
5. Executes Claude Code as non-root user

### Implementation

**docker-compose.yml:**
```yaml
services:
  claude-code:
    secrets:
      - claude_credentials
      - claude_session

secrets:
  claude_credentials:
    file: ${HOME}/.claude/.credentials.json
  claude_session:
    file: ${HOME}/.claude.json
```

**Dockerfile:**
```dockerfile
# Install gosu for user switching
RUN apt-get install -y gosu

# Don't set USER directive - entrypoint runs as root
WORKDIR /workspace
```

**entrypoint.sh:**
```bash
# Copy secrets (runs as root)
cp /run/secrets/claude_credentials ${CLAUDE_CONFIG_DIR}/.credentials.json
chown -R node:node ${CLAUDE_CONFIG_DIR}

# Drop to non-root user and execute
exec gosu node claude "${CLAUDE_ARGS[@]}"
```

## Consequences

### Positive

- **Security:** Credentials not exposed in environment variables or logs
- **Portability:** Works regardless of host UID/GID
- **Best Practice:** Follows Docker's official recommendation for user switching
- **Signal Handling:** gosu properly forwards SIGTERM for graceful shutdown
- **Flexibility:** Allows root-level initialization while running app as non-root

### Negative

- **Complexity:** Additional entrypoint logic compared to simple volume mount
- **Dependencies:** Requires gosu installation (adds ~2MB to image)
- **Startup Time:** Minimal overhead from secret copying on each container start

### Risks

- **Secret Permissions:** Docker Compose file-based secrets are mounted world-readable (mode 0444) at `/run/secrets/`. This is acceptable because:
  - Secrets are only readable by processes inside the container
  - Container isolation provides security boundary
  - We copy and chmod 600 the credentials in the container

- **Root in Entrypoint:** Entrypoint runs as root, increasing attack surface during initialization. Mitigated by:
  - Minimal root operations (copy, chown)
  - Immediate privilege drop via gosu
  - Standard pattern recommended by Docker

## References

- [Docker Dockerfile Reference - USER Instruction](https://docs.docker.com/engine/reference/builder/)
  - Docker's official recommendation: "If you need to write a starter script for a single executable, you can ensure that the final executable receives the Unix signals by using exec and gosu commands"
- [Docker Best Practices](https://docs.docker.com/build/building/best-practices/)
  - Recommends "avoiding sudo due to unpredictable TTY and signal-forwarding behavior, and suggests using gosu instead"
- [Secrets in Compose | Docker Docs](https://docs.docker.com/compose/how-tos/use-secrets/)
  - "Secrets are mounted as a file in /run/secrets/<secret_name> inside the container"
- [Official gosu Repository](https://github.com/tianon/gosu)
  - "gosu avoids all the issues of signal passing and TTY by properly executing the process directly"
- [Running docker container with a non-root user and fixing shared volume permissions with GOSU](https://www.inanzzz.com/index.php/post/dna6/unning-docker-container-with-a-non-root-user-and-fixing-shared-volume-permissions-with-gosu)
  - Community example of the entrypoint + gosu pattern

## Date

2025-12-12
