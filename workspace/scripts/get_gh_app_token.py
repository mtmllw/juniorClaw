#!/usr/bin/env python3
import os
import sys
import time
import jwt
import requests

def main():
    app_id = os.environ.get("GH_APP_ID")
    if not app_id:
        print(os.environ.get("GITHUB_TOKEN", ""))
        return

    installation_id = os.environ.get("GH_APP_INSTALLATION_ID")
    pem_path = os.environ.get("GH_APP_PRIVATE_KEY_PATH", "/root/.openclaw/github-app.pem")

    if not installation_id or not pem_path:
        print("Error: GH_APP_INSTALLATION_ID and GH_APP_PRIVATE_KEY_PATH must be set.", file=sys.stderr)
        sys.exit(1)

    try:
        with open(pem_path, 'rb') as f:
            private_key = f.read()
    except Exception as e:
        print(f"Error reading PEM file from {pem_path}: {e}", file=sys.stderr)
        sys.exit(1)

    now = int(time.time())
    payload = {
        "iat": now - 60,
        "exp": now + (10 * 60),
        "iss": app_id
    }
    
    try:
        encoded_jwt = jwt.encode(payload, private_key, algorithm="RS256")
    except Exception as e:
        print(f"Error encoding JWT: {e}", file=sys.stderr)
        sys.exit(1)
        
    headers = {
        "Authorization": f"Bearer {encoded_jwt}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
    
    resp = requests.post(url, headers=headers)
    if resp.status_code != 201:
        print(f"Error generating token: {resp.status_code} {resp.text}", file=sys.stderr)
        sys.exit(1)
        
    token = resp.json().get("token")
    if token:
        print(token)
    else:
        print("Error: Token not found in response.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
