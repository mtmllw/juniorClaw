# JuniorClaw: Enterprise Autonomous Developer (VDS Optimized)

JuniorClaw is a highly customized, fast, containerized installation of OpenClaw. It serves as an autonomous, self-healing **Senior Engineering Team** operating natively within a headless Virtual Dedicated Server (VDS) or VPS.

## 🌟 Key Enterprise Features

1. **True Headless Plug-and-Play**: 
   The `setup.sh` script automatically detects missing `.env` variables, securely auto-generates your Gateway Token natively using `openssl`, enforces pre-flight validation checks for API keys, and securely boots the background OpenClaw service without any human wizard prompts (`--non-interactive`).
2. **Master Orchestrator Architecture (`AGENTS.md`)**:
   Instead of a simple recursive agent, JuniorClaw uses a Hierarchical Persona Orchestrator. The Master Agent breaks down your prompts, assigns roles (e.g., Lead Architect, Frontend Dev, QA Tester), and coordinates them using a segmented Memory Architecture (`tasks.md`) to prevent LLM context pollution.
3. **Dynamic GitHub Publishing**: 
   Equipped with a native GitHub CLI (`gh`) and a custom Python JWT token generator (`get_gh_app_token.py`), the agent can autonomously spin up private repositories, commit its work, dynamically assume GitHub App Identities (bypassing static PATs), and instantly invite you as a collaborator.
4. **Visual Proof of Work (Telegram)**:
   Since JuniorClaw runs on a headless server, it cannot natively "see" the UI it builds. We injected an X11 virtual framebuffer (`xvfb`) and `imagemagick` into the Docker container. Before completing a project, the QA Persona boots the app, snaps a screenshot of the virtual display, and instantly uploads the picture and terminal test results to your phone via the Telegram API.

---

## 🚀 Installation & Setup

### 1. Configure Environment
Provide your Provider API keys, Telegram Bot Tokens, and GitHub Identities cleanly via `.env`:
```bash
cp .env.example .env
nano .env
```

#### First Time Setup: GitHub App Identity
To use GitHub App authentication (recommended):
1. Create a GitHub App, install it on your repository, and generate a `.pem` Private Key.
2. Place the downloaded `.pem` file into the `data/` directory and rename it to `github-app.pem`.
3. Inside your `.env` file, provide your App configuration:
   - `GH_APP_ID=your_app_id`
   - `GH_APP_INSTALLATION_ID=your_installation_id`
   - `GH_APP_PRIVATE_KEY_PATH=/home/node/.openclaw/github-app.pem` *(Keep this path exactly!)*

### 2. Auto-Boot
Execute the foolproof setup script. It will run pre-flight checks and boot silently:
```bash
chmod +x setup.sh
./setup.sh
```
*(If your `.env` is missing critical values, it will safely abort and tell you exactly what is missing!)*

### 3. Access the Control UI via SSH Tunnel
By default, Docker bypasses standard firewalls (like UFW). To prevent unauthorized access, this setup uses `network_mode: "host"` binding port strictly to your server's true `127.0.0.1`.

Open a new terminal on your local computer and establish an SSH tunnel:
```bash
ssh -L 18789:127.0.0.1:18789 your_user@your_vds_ip
```
Then, access the dashboard at **http://127.0.0.1:18789** using the Auto-Generated Gateway Token printed in your terminal!

---

## 🛠️ Modifying Agent Behavior
The brains of JuniorClaw exist entirely in your `./workspace/` directory.

- **`AGENTS.md`**: The Iron-Law rulebook forcing the AI to orchestrate personas and push to GitHub.
- **`skills/autonomous-developer/SKILL.md`**: The technical workflow forcing the agent to snap screenshots with ImageMagick and run tests in headless environments before talking to you.
