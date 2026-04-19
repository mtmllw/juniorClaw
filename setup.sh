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

# Ensure Langfuse variables exist in .env for backward compatibility
if ! grep -q "^LANGFUSE_NEXTAUTH_SECRET=" .env; then
  echo "=> Appending Langfuse configuration to .env..."
  echo "" >> .env
  echo "# OBSERVABILITY CONFIGURATION (LANGFUSE)" >> .env
  echo "LANGFUSE_NEXTAUTH_SECRET=" >> .env
  echo "LANGFUSE_SALT=" >> .env
  echo "LANGFUSE_ENCRYPTION_KEY=" >> .env
  echo "LANGFUSE_NEXTAUTH_URL=http://localhost:3000" >> .env
  echo "LANGFUSE_INIT_USER_EMAIL=admin@openclaw.local" >> .env
  echo "LANGFUSE_INIT_USER_PASSWORD=" >> .env
  echo "LANGFUSE_HOST=http://localhost:3000" >> .env
  echo "LANGFUSE_PUBLIC_KEY=" >> .env
  echo "LANGFUSE_SECRET_KEY=" >> .env
fi

# Auto-generate Langfuse Secrets if they are empty
if grep -q "^LANGFUSE_NEXTAUTH_SECRET=$" .env; then
  echo "=> Generating secure Langfuse Secrets..."
  NEXTAUTH_SECRET=$(openssl rand -base64 32 | tr -d '\n' | tr -d '/' | tr -d '+')
  SALT=$(openssl rand -base64 32 | tr -d '\n' | tr -d '/' | tr -d '+')
  ENCRYPTION_KEY=$(openssl rand -hex 32)
  LF_PASSWORD=$(openssl rand -hex 8)
  LF_PUBLIC_KEY="pk-lf-$(openssl rand -hex 16)"
  LF_SECRET_KEY="sk-lf-$(openssl rand -hex 16)"

  sed -i "s|^LANGFUSE_NEXTAUTH_SECRET=$|LANGFUSE_NEXTAUTH_SECRET=$NEXTAUTH_SECRET|" .env
  sed -i "s|^LANGFUSE_SALT=$|LANGFUSE_SALT=$SALT|" .env
  sed -i "s|^LANGFUSE_ENCRYPTION_KEY=$|LANGFUSE_ENCRYPTION_KEY=$ENCRYPTION_KEY|" .env
  sed -i "s|^LANGFUSE_INIT_USER_PASSWORD=$|LANGFUSE_INIT_USER_PASSWORD=$LF_PASSWORD|" .env
  sed -i "s|^LANGFUSE_PUBLIC_KEY=$|LANGFUSE_PUBLIC_KEY=$LF_PUBLIC_KEY|" .env
  sed -i "s|^LANGFUSE_SECRET_KEY=$|LANGFUSE_SECRET_KEY=$LF_SECRET_KEY|" .env
  
  echo "=========================================================="
  echo "📊 Langfuse Observability is enabled!"
  echo "   Dashboard: http://127.0.0.1:3000"
  echo "   Email: admin@openclaw.local"
  echo "   Password: $LF_PASSWORD"
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

echo "=> Detecting available models based on your API keys..."
# Run the python script to fetch models actively from the internet/APIs
MODELS_FETCHED=$(python3 ./workspace/scripts/fetch_models.py 2>/dev/null)
AVAILABLE_MODELS=()
while IFS= read -r line; do
  if [ -n "$line" ]; then
    AVAILABLE_MODELS+=("$line")
  fi
done <<< "$MODELS_FETCHED"

if [ ${#AVAILABLE_MODELS[@]} -eq 0 ]; then
  # Fallback if internet fetch fails
  AVAILABLE_MODELS=("gpt-4o" "claude-3-5-sonnet-20241022" "gemini-2.5-pro")
fi
  echo "Please select the models you want the Orchestrator to use (space-separated numbers, e.g., '1 2'):"
  for i in "${!AVAILABLE_MODELS[@]}"; do
    echo "$((i+1)). ${AVAILABLE_MODELS[$i]}"
  done

  read -p "Selection: " selections
  SELECTED_MODELS=()
  for sel in $selections; do
    # Only process numbers to prevent errors
    if [[ "$sel" =~ ^[0-9]+$ ]]; then
      idx=$((sel-1))
      if [ -n "${AVAILABLE_MODELS[$idx]}" ]; then
        SELECTED_MODELS+=("${AVAILABLE_MODELS[$idx]}")
      fi
    fi
  done

  if [ ${#SELECTED_MODELS[@]} -eq 0 ]; then
    echo "❌ Error: You must select at least one valid model."
    exit 1
  fi

  PRIMARY_MODEL="${SELECTED_MODELS[0]}"
  if [ ${#SELECTED_MODELS[@]} -gt 1 ]; then
    echo "Multiple models selected. Which one should be the DEFAULT primary model?"
    for i in "${!SELECTED_MODELS[@]}"; do
      echo "$((i+1)). ${SELECTED_MODELS[$i]}"
    done
    read -p "Select primary (number): " primary_sel
    if [[ "$primary_sel" =~ ^[0-9]+$ ]]; then
      idx=$((primary_sel-1))
      if [ -n "${SELECTED_MODELS[$idx]}" ]; then
        PRIMARY_MODEL="${SELECTED_MODELS[$idx]}"
      fi
    fi
  fi

  sed -i '/^SELECTED_MODELS=/d' .env
  sed -i '/^DEFAULT_MODEL=/d' .env
  echo "SELECTED_MODELS=\"${SELECTED_MODELS[*]}\"" >> .env
  echo "DEFAULT_MODEL=\"$PRIMARY_MODEL\"" >> .env
  DEFAULT_MODEL="$PRIMARY_MODEL"
  echo "=> Set primary model to $PRIMARY_MODEL."

# Validate GitHub Variables
if { [ -z "$GITHUB_TOKEN" ] && [ -z "$GH_APP_ID" ]; } || [ -z "$TARGET_GITHUB_USER" ]; then
  echo "❌ Error: GitHub configuration is incomplete!"
  echo "   Please open .env and provide EITHER your GITHUB_TOKEN (PAT) OR GH_APP_ID (GitHub App), AND your TARGET_GITHUB_USER."
  exit 1
fi

echo "✅ Configuration validated successfully!"

echo "=> Preparing local data and workspace directories..."
mkdir -p ./data ./workspace

echo "=> Searching for GitHub App .pem key..."
shopt -s nullglob
PEM_FILES=(*.pem)
shopt -u nullglob

if [ ${#PEM_FILES[@]} -eq 1 ]; then
  echo "   Found ${PEM_FILES[0]}. Copying to data directory for internal use..."
  cp "${PEM_FILES[0]}" ./data/github-app.pem
elif [ ${#PEM_FILES[@]} -gt 1 ]; then
  echo "   ⚠️ Multiple .pem files found. Please manually copy the correct one to ./data/github-app.pem"
else
  echo "   No .pem files found in the current directory. Assuming PAT auth or manual setup."
fi
# Container runs as UID 1000 (node). Ensure it has permissions if we aren't UID 1000.
if [ "$(stat -c %u ./data)" -ne 1000 ] || [ "$(stat -c %u ./workspace)" -ne 1000 ]; then
  echo "=> Adjusting permissions for ./data and ./workspace to UID 1000 (requires sudo)..."
  sudo chown -R 1000:1000 ./data ./workspace
fi

echo "=> Building OpenClaw image to ensure local dependencies (like NPM) are up to date..."
docker compose build

echo "=> Running OpenClaw Headless Onboarding..."

AGENT_CMD="npx openclaw onboard --non-interactive --accept-risk --skip-health && \
npx openclaw config set tools.elevated.enabled true"

if [ -n "$DEFAULT_MODEL" ]; then
    echo "=> Injecting custom DEFAULT_MODEL ($DEFAULT_MODEL)..."
    AGENT_CMD="$AGENT_CMD && npx openclaw config set agents.defaults.model.primary \"$DEFAULT_MODEL\""
fi

if [ -n "$TELEGRAM_CHAT_ID" ]; then
    echo "=> Injecting Telegram Chat ID ($TELEGRAM_CHAT_ID) and authorizing elevated permissions for Telegram..."
    AGENT_CMD="$AGENT_CMD && \
    npx openclaw config set channels.telegram.dmPolicy 'pairing' && \
    npx openclaw config set channels.telegram.allowFrom '[\"$TELEGRAM_CHAT_ID\"]' --strict-json && \
    npx openclaw config set tools.elevated.allowFrom.telegram '[\"$TELEGRAM_CHAT_ID\"]' --strict-json"
fi

echo "=> Executing configuration sequence..."
docker compose run --rm openclaw-cli /bin/sh -c "$AGENT_CMD"

if [ $? -eq 0 ]; then
    echo "   ✅ Setup and configuration completed successfully."
else
    echo "   ❌ An error occurred during the setup process."
fi

echo "=> Injecting environment variables into sandbox workspace..."
cp .env ./workspace/.env
chmod 600 ./workspace/.env

# CRITICAL FIX: Ensure any config files or directories created by root in this script (and our injected .env) are accessible by the container user (node)
if [ "$(stat -c %u ./data)" -ne 1000 ] || [ "$(stat -c %u ./workspace)" -ne 1000 ] || [ "$(stat -c %u ./workspace/.env)" -ne 1000 ]; then
  echo "=> Securing data permissions back to the container agent (UID 1000)..."
  sudo chown -R 1000:1000 ./data ./workspace
fi

echo ""
echo "=> Starting OpenClaw Gateway and Langfuse in detached mode..."
docker compose up -d --force-recreate openclaw-gateway langfuse-server langfuse-db

echo ""
echo -n "=> Waiting for OpenClaw Gateway to become healthy (timeout: 5 mins)"
RETRIES=0
MAX_RETRIES=30

while [ $RETRIES -lt $MAX_RETRIES ]; do
  STATUS=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' openclaw-gateway 2>/dev/null || echo "starting")
  
  if [ "$STATUS" = "healthy" ]; then
    echo " [OK]"
    break
  elif [ "$STATUS" = "exited" ] || [ "$STATUS" = "dead" ]; then
    echo ""
    echo "❌ Gateway container crashed during startup!"
    break
  fi
  
  # Print a dot to show we are silently waiting, not frozen
  echo -n "."
  sleep 10
  RETRIES=$((RETRIES+1))
done

if [ $RETRIES -eq $MAX_RETRIES ]; then
  echo ""
  echo "⚠️ Timeout: Gateway took longer than 5 minutes to report 'healthy'."
  echo "   It might still be downloading dependencies. Check logs if issues persist."
fi

echo ""
echo "=========================================================="
echo "                 ✨ Setup Complete! ✨                    "
echo "=========================================================="
echo "✓ Default Model: ${DEFAULT_MODEL:-Not Set}"
echo "✓ GitHub Auth:   $(if [ -f "./data/github-app.pem" ]; then echo "App .pem Key Active"; else echo "Using PAT / Default"; fi)"
echo "✓ Telegram:      $(if [ -n "$TELEGRAM_CHAT_ID" ]; then echo "Connected"; else echo "Not Configured"; fi)"
echo ""
echo "🔗 Gateway UI:    http://127.0.0.1:18789"
echo "🔑 Gateway Token: Check your .env file"
echo "=========================================================="
echo "💻 Useful Commands:"
echo "   View Logs: docker compose logs -f openclaw-gateway"
echo "   Open CLI:  docker compose run --rm openclaw-cli npx openclaw dashboard --no-open"
echo "=========================================================="
echo ""
