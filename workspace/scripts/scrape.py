#!/usr/bin/env python3
import sys
import argparse
import re

try:
    from scrapling import Fetcher
except ImportError:
    print("Error: 'scrapling' module is not installed. Please ensure the Docker container has been rebuilt with it.")
    sys.exit(1)

def clean_html(raw_html):
    # Very basic HTML cleaner to avoid context overflow for the agent
    # It removes script and style tags entirely before stripping other tags
    html_no_scripts = re.sub(r'<script.*?>.*?</script>', '', raw_html, flags=re.DOTALL | re.IGNORECASE)
    html_no_styles = re.sub(r'<style.*?>.*?</style>', '', html_no_scripts, flags=re.DOTALL | re.IGNORECASE)
    
    cleanr = re.compile('<.*?>')
    cleantext = re.sub(cleanr, ' ', html_no_styles)
    return " ".join(cleantext.split())

def main():
    parser = argparse.ArgumentParser(description="Scrape a webpage and return plain text using Scrapling.")
    parser.add_argument("url", help="URL of the webpage to scrape")
    parser.add_argument("--raw", action="store_true", help="Return raw HTML instead of cleaned text")
    args = parser.parse_args()

    try:
        # Use stealth Fetcher
        fetcher = Fetcher(auto_match=True)
        response = fetcher.get(args.url)
        content = response.text
        
        if args.raw:
            print(content)
        else:
            print(clean_html(content))
            
    except Exception as e:
        print(f"Error scraping {args.url}: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
