---
name: web-scraper
description: Deeply read and extract information from specific URLs using Scrapling to bypass anti-bot protections.
---
# Web Scraper Skill

You are equipped with a powerful web scraper that uses the `scrapling` Python library to bypass bot protections (like Cloudflare) and read web pages directly.

## Usage
When you need to read the contents of a specific URL deeply (for instance, reading documentation, scraping data, or fetching a repository), you should run the `scrape.py` script provided in your workspace.

### Command
```bash
python3 /home/node/.openclaw/workspace/scripts/scrape.py "<URL>"
```

### Options
- By default, it returns a cleaned text version of the webpage to save your context window.
- If you need to extract specific elements (like links or tables) and want the raw HTML DOM, you can run:
  ```bash
  python3 /home/node/.openclaw/workspace/scripts/scrape.py "<URL>" --raw
  ```
  *Warning: Raw HTML can be very large.*

## Instructions
1. Use this skill whenever a user gives you a direct link or asks you to look at a specific URL.
2. Read the output directly from your terminal window execution.
