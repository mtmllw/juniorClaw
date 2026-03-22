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
  echo "=> Please edit .env to add your API keys!"
fi

# Auto-generate Gateway Token if it's empty
if grep -q "^OPENCLAW_GATEWAY_TOKEN=$" .env; then
  echo "=> Generating a secure Gateway Token..."
  RANDOM_TOKEN=$(openssl rand -hex 16)
  sed -i "s/^OPENCLAW_GATEWAY_TOKEN=$/OPENCLAW_GATEWAY_TOKEN=$RANDOM_TOKEN/" .env
  echo "=========================================================="
  echo "🔑 Your auto-generated Gateway Token is: $RANDOM_TOKEN"
  echo "   (Save this token, you'll need it for the dashboard login!)"
  echo "=========================================================="
fi

echo "=> Preparing local data and workspace directories..."
mkdir -p ./data ./workspace
# Container runs as UID 1000 (node). Ensure it has permissions if we aren't UID 1000.
if [ "$(stat -c %u ./data)" -ne 1000 ] || [ "$(stat -c %u ./workspace)" -ne 1000 ]; then
  echo "=> Adjusting permissions for ./data and ./workspace to UID 1000 (requires sudo)..."
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
