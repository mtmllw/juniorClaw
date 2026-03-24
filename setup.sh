#!/bin/bash
set -e

echo "====================================="
echo "  OpenClaw Fast Docker Installation  "
echo "====================================="
echo ""

# Check if .env exists, if not copy from .env.example
if [ ! -f .env ]; then
  echo "=> Warning: .env file not found. Creating a default one..."
  cp .env.example .env
  
  echo "=> Generating a secure Gateway Token..."
  RANDOM_TOKEN=$(openssl rand -hex 16)
  sed -i "s/^OPENCLAW_GATEWAY_TOKEN=$/OPENCLAW_GATEWAY_TOKEN=$RANDOM_TOKEN/" .env
  echo "=========================================================="
  echo "🔑 Your auto-generated Gateway Token is: $RANDOM_TOKEN"
  echo "   (Save this token, you'll need it for the dashboard login!)"
  echo "=========================================================="
  
  echo "❌ SETUP STOPPED: You must open the '.env' file and configure your API keys and GitHub username before running the agent!"
  exit 1
fi

# Auto-generate Gateway Token if it's empty on a pre-existing file
if grep -q "^OPENCLAW_GATEWAY_TOKEN=$" .env; then
  echo "=> Generating a secure Gateway Token..."
  RANDOM_TOKEN=$(openssl rand -hex 16)
  sed -i "s/^OPENCLAW_GATEWAY_TOKEN=$/OPENCLAW_GATEWAY_TOKEN=$RANDOM_TOKEN/" .env
  echo "=========================================================="
  echo "🔑 Your auto-generated Gateway Token is: $RANDOM_TOKEN"
  echo "   (Save this token, you'll need it for the dashboard login!)"
  echo "=========================================================="
fi

# Load variables to validate them
echo "=> Validating configuration..."
set -o allexport; source .env; set +o allexport

# Validate LLM API Key
if [ -z "$OPENAI_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$GEMINI_API_KEY" ] && [ -z "$MISTRAL_API_KEY" ] && [ -z "$GROQ_API_KEY" ]; then
  echo "❌ Error: No LLM Provider API Key found!"
  echo "   Please open .env and add at least one API key (e.g., OPENAI_API_KEY) so the agent has a brain."
  exit 1
fi

# Validate GitHub Variables
if { [ -z "$GITHUB_TOKEN" ] && [ -z "$GH_APP_ID" ]; } || [ -z "$TARGET_GITHUB_USER" ]; then
  echo "❌ Error: GitHub configuration is incomplete!"
  echo "   Please open .env and provide EITHER your GITHUB_TOKEN (PAT) OR GH_APP_ID (GitHub App), AND your TARGET_GITHUB_USER."
  exit 1
fi

echo "✅ Configuration validated successfully!"

echo "=> Preparing local data and workspace directories..."
mkdir -p ./data ./workspace
# Container runs as UID 1000 (node). Ensure it has permissions if we aren't UID 1000.
if [ "$(stat -c %u ./data)" -ne 1000 ] || [ "$(stat -c %u ./workspace)" -ne 1000 ]; then
  echo "=> Adjusting permissions for ./data and ./workspace to UID 1000 (requires sudo)..."
  sudo chown -R 1000:1000 ./data ./workspace
fi

echo "=> Building OpenClaw image to ensure local dependencies (like NPM) are up to date..."
docker compose build

echo "=> Running OpenClaw Headless Onboarding..."
# The non-interactive flag ensures it reads from .env and generates config.json without prompting
docker compose run --rm openclaw-cli npx openclaw onboard --non-interactive --accept-risk --skip-health

# Workaround: Forcing custom .env features into the newly created config using jq
if [ -n "$DEFAULT_MODEL" ]; then
    echo "=> Injecting custom DEFAULT_MODEL ($DEFAULT_MODEL) directly into backend configuration..."
    docker compose run --rm openclaw-cli npx openclaw config set agents.defaults.model.primary "$DEFAULT_MODEL"
fi

if [ -n "$TELEGRAM_CHAT_ID" ]; then
    echo "=> Auto-pairing Telegram Chat ID..."
    docker compose run --rm openclaw-cli npx openclaw config set channels.telegram.allowFrom '["'$TELEGRAM_CHAT_ID'"]' --strict-json
    echo "   ✅ Telegram Chat ID $TELEGRAM_CHAT_ID paired automatically."
fi

# CRITICAL FIX: Ensure any config files or directories created by root in this script are accessible by the container user (node)
if [ "$(stat -c %u ./data)" -ne 1000 ] || [ "$(stat -c %u ./workspace)" -ne 1000 ]; then
  echo "=> Securing data permissions back to the container agent (UID 1000)..."
  sudo chown -R 1000:1000 ./data ./workspace
fi

echo ""
echo "=> Starting OpenClaw Gateway in detached mode..."
docker compose up -d openclaw-gateway

echo ""
echo "✅ OpenClaw Gateway is starting!"
echo "🔗 You can access the Control UI at: http://127.0.0.1:18789/"
echo ""
echo "📊 To view logs, run:"
echo "   docker compose logs -f openclaw-gateway"
echo ""
echo "🚀 To open the dashboard CLI, run:"
echo "   docker compose run --rm openclaw-cli npx openclaw dashboard --no-open"
echo ""
