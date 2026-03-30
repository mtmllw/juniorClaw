---
name: autonomous-developer
description: Write, test, and commit code autonomously. Supports headless desktop and web testing.
---
# Autonomous Developer Skill

You are operating as a Junior Developer on a headless server. You have the ability to write code, test it locally, and push the results using Git. Your workspace is located at `{baseDir}`.

## Writing Code
1. Your ultimate root directory is `/home/node/.openclaw/workspace`, but **you MUST read and strictly follow `/home/node/.openclaw/workspace/AGENTS.md` before starting any coding work.** Every project must be in its own subfolder.
2. Ensure you initialize the project properly inside its isolated folder (e.g. `npm init`, `python -m venv venv`, etc.).
3. Write modular, highly tested code.

## Headless Testing
The server is running headless (no physical monitor). However, you have `xvfb` installed to simulate an X server.

- **CLI Tests**: Run normally (e.g., `npm run test` or `pytest`).
- **Web/Desktop Tests**: If you are testing a desktop application (Tkinter, PyQt) or a browser automation script (Playwright, Puppeteer), you MUST wrap the command with `xvfb-run` to prevent "Cannot connect to display" errors.
  
  Example:
  ```bash
  xvfb-run -a npm run test:e2e
  xvfb-run -a python3 main.py
  ```

## Committing Code (Git)
Once you have written code and verified it runs successfully via tests, you must commit it.

1. Ensure the workspace is a Git repository (`git init`).
2. Add the files: `git add .`
3. Commit with a descriptive message: `git commit -m "feat: your helpful commit message"`
4. If a remote is configured and you are asked to push: `git push origin HEAD`

*Important*: If you encounter issues pushing, check if a GitHub Personal Access Token (PAT) was provided by the user in the prompt or environment.

## 🧾 4. Sending Proof of Work (Terminal & Screenshots)
Before ending your task, you **MUST** provide visual and technical proof to the user that the project successfully runs in a headless environment.

1. **Terminal Proof**: First, copy the exact STDOUT test results (e.g. from `npm test` or the server boot logs) and format them in a markdown code block inside your final message. Do not summarize them; show the raw proof.
2. **Visual Screenshot Proof**:
   Since the server runs headless, use `xvfb` and `imagemagick` to capture what the screen actually looks like:
   - Start your app inside `xvfb-run` in the background (e.g. `xvfb-run -a -s "-screen 0 1280x720x24" python3 app.py &`).
   - Wait 3 seconds for the UI to render.
   - Capture the X11 Display buffer: `DISPLAY=:99 import -window root proof.png`
   - Upload the screenshot directly to the user by explicitly utilizing your built-in `message` tool. DO NOT try to use raw `curl` or markdown `![img]()` links to send images. 
     *Example Tool Call:* Action: `send`, `filePath` (must be the absolute path to `proof.png`), and a helpful `caption`.
   - Kill the background app process when finished.
