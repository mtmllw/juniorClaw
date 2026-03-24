# Use the official OpenClaw image as the base
FROM ghcr.io/openclaw/openclaw:latest


USER root
# Install dev roots (Python, Build Tools), Docker CLI (for Agent Sandboxing), and headless browser tools (xvfb, chromium)
RUN apt-get update && \
    apt-get install -y \
        git curl jq \
        python3 python3-pip python3-venv \
        python3-jwt python3-requests python3-cryptography \
        build-essential \
        docker.io \
        xvfb libnss3 libasound2 chromium \
        imagemagick && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Install Scrapling and required python libraries
RUN pip3 install --break-system-packages scrapling lxml || true

# Fix npm update warning by always forcing the latest version globally
RUN npm install -g npm@latest

USER node

# Use standard entrypoint from the base image
