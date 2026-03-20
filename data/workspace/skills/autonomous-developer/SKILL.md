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
