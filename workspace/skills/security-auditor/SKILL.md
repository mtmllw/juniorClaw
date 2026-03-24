---
name: security-auditor
description: Audit workspace code for security vulnerabilities, hardcoded secrets, and unsafe patterns before committing.
---
# Security Auditor Skill

As an Autonomous Developer, you MUST ensure that the code you build is secure and safe before pushing it. You are equipped with several industry-standard security tools.

## Mandatory Pre-Commit Checks
Before you run `git commit`, you MUST run the applicable security audits on your workspace. 

### 1. Python Code (`bandit`)
If your project contains any `.py` files, run:
```bash
bandit -r .
```
This tool scans for common Python security issues (like dangerous imports, shell injections, etc.).

### 2. Node.js Code (`npm audit`)
If your project contains a `package.json`, run:
```bash
npm audit
```
This checks for known vulnerabilities in your JavaScript dependencies.

### 3. Hardcoded Secrets (`detect-secrets`)
Before ANY commit, run:
```bash
detect-secrets scan
```
This tool scans for API keys, passwords, authentication tokens, and other sensitive information that might be accidentally hardcoded in your source files.

## Fixing Vulnerabilities
- If any of these tools report a **HIGH** or **CRITICAL** vulnerability or a hardcoded secret, you **MUST NOT** proceed with the commit.
- Stop, analyze the output, fix the vulnerable code or remove the hardcoded secret (move it to `.env`), and re-run the tests.
- Only once the audit passes cleanly (or acceptable false positives are verified) may you proceed to commit.
