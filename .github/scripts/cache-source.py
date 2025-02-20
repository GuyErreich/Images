#!/usr/bin/env python3

import os
import subprocess
import sys

def get_latest_tag(image_name, cache_tag):
    """Fetches the latest tag matching the pattern."""
    try:
        tags = subprocess.check_output(
            ["git", "tag", "-l", f"{image_name}-{cache_tag}", "--sort=-v:refname"],
            text=True
        ).splitlines()
        return tags[0] if tags else "latest"
    except subprocess.CalledProcessError:
        return "latest"

def main():
    image_name = sys.argv[1]  # First argument (IMAGE_NAME)
    
    # Determine cache tag based on GitHub Actions context
    github_base_ref = os.getenv("GITHUB_BASE_REF", "")
    
    if github_base_ref == "dev":
        cache_tag = "v*-dev"
    elif github_base_ref == "staging":
        cache_tag = "v*-staging"
    else:
        cache_tag = "v*"

    # Get latest cache image tag
    cache_image = get_latest_tag(image_name, cache_tag)
    cache_from = f"ghcr.io/{os.getenv('GITHUB_REPOSITORY_OWNER')}/{image_name}:{cache_image}"

    # Save the result to GITHUB_ENV
    with open(os.getenv("GITHUB_ENV"), "a") as env_file:
        env_file.write(f"CACHE_FROM={cache_from}\n")

    print(f"Using Cache from: {cache_from}")

if __name__ == "__main__":
    main()