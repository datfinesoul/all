FROM node:20-bookworm

ARG CLAUDE_VERSION=latest
ARG GIT_DELTA_VERSION=0.18.2

ENV DEVCONTAINER=true \
    SHELL=/bin/zsh \
    EDITOR=nano \
    VISUAL=nano \
    NPM_CONFIG_PREFIX=/usr/local/share/npm-global \
    PATH=/usr/local/share/npm-global/bin:$PATH \
    CLAUDE_CONFIG_DIR=/home/node/.claude

# Install system dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    less \
    git \
    procps \
    sudo \
    fzf \
    zsh \
    man-db \
    unzip \
    gnupg2 \
    gh \
    ripgrep \
    dnsutils \
    jq \
    nano \
    vim \
    gosu && \
    rm -rf /var/lib/apt/lists/*

# Install git-delta for better diffs
RUN ARCH=$(dpkg --print-architecture) && \
    wget -q https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb && \
    dpkg -i git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb && \
    rm git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb

# Configure zsh with oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    chsh -s /bin/zsh node

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_VERSION}

# Setup workspace and config directories
RUN mkdir -p /workspace /home/node/.claude && \
    chown -R node:node /workspace /home/node/.claude

# Setup node user for npm global packages
RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share/npm-global

WORKDIR /workspace

# Copy entrypoint script
COPY --chown=node:node entrypoint.sh /home/node/entrypoint.sh
RUN chmod +x /home/node/entrypoint.sh

ENTRYPOINT ["/home/node/entrypoint.sh"]
CMD ["claude"]
