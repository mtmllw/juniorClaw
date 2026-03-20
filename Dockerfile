# Use the official OpenClaw image as the base
FROM ghcr.io/openclaw/openclaw:latest

# Set the working directory
WORKDIR /home/node/.openclaw

USER root
# Install dev roots (Python, Build Tools), Docker CLI (for Agent Sandboxing), and headless browser tools (xvfb, chromium)
RUN apt-get update && \
    apt-get install -y \
        git curl jq \
        python3 python3-pip python3-venv \
        build-essential \
        docker.io docker-compose-plugin \
        xvfb libnss3 libasound2t64 chromium && \
    rm -rf /var/lib/apt/lists/*
USER node

# Use standard entrypoint from the base image
