# OpenClaw Docker Environment (VDS Optimized)

This project provides a fast, containerized installation of OpenClaw, specifically optimized and secured for deployment on a Virtual Dedicated Server (VDS) or VPS.

## Security Considerations for VDS

By default, Docker bypasses standard firewalls (like UFW) when publishing ports. To prevent unauthorized access to your OpenClaw Control UI over the public internet, this setup binds the gateway port **strictly to `127.0.0.1` (localhost)** on your server.

This means the dashboard is **not** publicly accessible by default. You must use SSH tunneling to access it securely.

## 🚀 Installation & Setup

### 1. Configure Environment

First, edit the `.env` file and add your provider API keys.
If you don't have a `.env` file yet, copy it from the example (the setup script will also do this):
```bash
cp .env.example .env
nano .env
```

### 2. Run the Setup Script

Execute the provided setup script. It will run the OpenClaw onboarding process (generating your gateway token) and start the services in the background.

```bash
chmod +x setup.sh
./setup.sh
```

### 3. Access the Control UI via SSH Tunnel

To access the UI securely from your local machine, open a new terminal on your computer and establish an SSH tunnel to your VDS:

```bash
# Run this from your LOCAL COMPUTER, not the VDS
ssh -L 18789:127.0.0.1:18789 your_user@your_vds_ip
```
*(Keep this terminal open while you want to use the dashboard.)*

Then, open your web browser and go to:
**http://127.0.0.1:18789**

---

## Useful Commands

- **View Logs**: `docker compose logs -f openclaw-gateway`
- **Stop Services**: `docker compose down`
- **Restart Services**: `docker compose restart`
- **Open Dashboard CLI**: `docker compose run --rm openclaw-cli npx openclaw dashboard --no-open`
- **Add Telegram Channel**: `docker compose run --rm openclaw-cli npx openclaw channels add --channel telegram --token "<bot_token>"`
