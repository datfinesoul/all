FROM node:20-bookworm

ARG CLAUDE_VERSION=latest

ENV DEVCONTAINER=true \
    PNPM_HOME=/usr/local/share/pnpm \
    PATH=/usr/local/share/pnpm:$PATH \
    CLAUDE_CONFIG_DIR=/home/node/.claude

# Install system dependencies required for Claude Code
RUN <<EOF
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    gh \
    ripgrep \
    jq \
    gosu
rm -rf /var/lib/apt/lists/*
EOF

# Install Claude Code CLI globally using pnpm, then remove npm
RUN <<EOF
corepack enable
corepack prepare pnpm@latest --activate
pnpm install -g @anthropic-ai/claude-code@${CLAUDE_VERSION}
npm uninstall -g npm
EOF

# Setup workspace and config directories
RUN mkdir -p /workspace /home/node/.claude

# Setup pnpm global packages directory
RUN mkdir -p /usr/local/share/pnpm

WORKDIR /workspace

# Copy entrypoint script
COPY entrypoint.sh /home/node/entrypoint.sh
RUN chmod +x /home/node/entrypoint.sh

ENTRYPOINT ["/home/node/entrypoint.sh"]
