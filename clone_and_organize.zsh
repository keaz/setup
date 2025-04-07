#!/bin/zsh

set -euo pipefail

# Ensure GITHUB_TOKEN is set
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "[ERROR] GITHUB_TOKEN environment variable is not set."
    exit 1
fi

# Configuration
GITHUB_USERNAME="keaz" # Replace with your GitHub username
DEST_DIR="$HOME/Projects"

# Ensure jq is installed
if ! command -v jq &>/dev/null; then
    echo "[ERROR] 'jq' is required but not installed. Use 'brew install jq'."
    exit 1
fi

# Create base directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Fetch repositories using GitHub API
echo "[INFO] Fetching repositories for $GITHUB_USERNAME..."
repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/users/$GITHUB_USERNAME/repos?per_page=100&type=owner")

# Iterate through each repository
echo "$repos" | jq -c '.[]' | while read -r repo; do
    name=$(echo "$repo" | jq -r '.name')
    clone_url=$(echo "$repo" | jq -r '.clone_url')
    language=$(echo "$repo" | jq -r '.language')

    # Handle unknown/null language
    if [[ -z "$language" || "$language" == "null" ]]; then
        language="Unknown"
    fi

    target_dir="$DEST_DIR/$language"
    repo_path="$target_dir/$name"

    mkdir -p "$target_dir"

    if [[ -d "$repo_path" ]]; then
        echo "[SKIP] $name already exists in $language/"
    else
        echo "[CLONE] $name => $language/"
        git clone "$clone_url" "$repo_path"
    fi
done
