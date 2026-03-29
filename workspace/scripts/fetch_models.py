#!/usr/bin/env python3
import os
import requests
import sys

def fetch_openai(api_key):
    try:
        headers = {"Authorization": f"Bearer {api_key}"}
        r = requests.get("https://api.openai.com/v1/models", headers=headers, timeout=5)
        if r.status_code == 200:
            models = sorted([m["id"] for m in r.json().get("data", []) if "gpt" in m["id"] or "o1" in m["id"] or "o3" in m["id"]], reverse=True)
            return [f"openai/{m}" for m in models if "vision" not in m and "instruct" not in m and "audio" not in m and "realtime" not in m][:15]
    except Exception as e:
        pass
    return ["openai/gpt-4o", "openai/gpt-4o-mini"]

def fetch_anthropic(api_key):
    try:
        headers = {"x-api-key": api_key, "anthropic-version": "2023-06-01"}
        r = requests.get("https://api.anthropic.com/v1/models", headers=headers, timeout=5)
        if r.status_code == 200:
            models = sorted([m["id"] for m in r.json().get("data", []) if "claude" in m["id"]], reverse=True)
            return [f"anthropic/{m}" for m in models][:10]
    except Exception as e:
        pass
    return ["anthropic/claude-3-7-sonnet-20250219", "anthropic/claude-3-5-sonnet-20241022", "anthropic/claude-3-5-haiku-20241022"]

def fetch_gemini(api_key):
    try:
        r = requests.get(f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}", timeout=5)
        if r.status_code == 200:
            models = sorted([m["name"].replace("models/", "") for m in r.json().get("models", []) if "gemini" in m["name"] and "vision" not in m["name"]], reverse=True)
            return [f"gemini/{m}" for m in models][:10]
    except Exception as e:
        pass
    return ["gemini/gemini-3.1-pro-preview", "gemini/gemini-3.1-flash-preview", "gemini/gemini-2.5-pro", "gemini/gemini-2.5-flash", "gemini/gemini-1.5-pro"]

def fetch_groq(api_key):
    try:
        headers = {"Authorization": f"Bearer {api_key}"}
        r = requests.get("https://api.groq.com/openai/v1/models", headers=headers, timeout=5)
        if r.status_code == 200:
            return sorted([f"groq/{m['id']}" for m in r.json().get("data", [])])[:10]
    except Exception as e:
        pass
    return ["groq/llama3-70b-8192", "groq/mixtral-8x7b-32768"]

if __name__ == "__main__":
    models = []
    
    if os.environ.get("OPENAI_API_KEY"):
        models.extend(fetch_openai(os.environ.get("OPENAI_API_KEY")))
    if os.environ.get("ANTHROPIC_API_KEY"):
        models.extend(fetch_anthropic(os.environ.get("ANTHROPIC_API_KEY")))
    if os.environ.get("GEMINI_API_KEY"):
        models.extend(fetch_gemini(os.environ.get("GEMINI_API_KEY")))
    if os.environ.get("GROQ_API_KEY"):
        models.extend(fetch_groq(os.environ.get("GROQ_API_KEY")))
    
    out = []
    for m in models:
        if m not in out:
            out.append(m)
            
    for o in out:
        print(o)
