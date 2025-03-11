#!/bin/bash

set -euo pipefail # Exit on error, unset variables, or failed piped commands

# Function to check requirements
check_requirements() {
    echo "🔍 Checking system requirements..."
    if ! command -v jq &>/dev/null; then
        echo "❌ Error: jq is not installed." >&2
        exit 1
    fi
    echo "✅ All requirements are met."
}

# Function to validate the current branch
validate_branch() {
    local branch
    branch="$(git rev-parse --abbrev-ref HEAD)"

    if [[ ! $branch =~ ^release/.*$ ]]; then
        echo "❌ Error: Releasing PROD must be done from a release branch." >&2
        exit 1
    fi
    echo "✅ Valid branch detected: $branch"
}

# Function to get the current version from manifest.json
get_version() {
    if [[ ! -f "manifest.json" ]]; then
        echo "❌ Error: manifest.json not found!" >&2
        exit 1
    fi

    jq -r '.version' "manifest.json"
}

# Function to delete an existing tag if it exists
delete_existing_tag() {
    local version="$1"

    if git rev-parse "refs/tags/$version" >/dev/null 2>&1; then
        echo "⚠️ Tag $version already exists. Deleting..."
        git tag -d "$version"
        git push --delete origin "$version" || echo "⚠️ Warning: Could not delete tag $version from remote."
        echo "✅ Deleted existing tag: $version"
    fi
}

# Function to create and push a new tag
create_and_push_tag() {
    local version="$1"

    echo "🏷️ Creating and pushing tag: $version"
    git tag "$version"
    git push origin "$version"
    echo "🎉 Tag $version created and pushed successfully."

    # Output release version for GitHub Actions
    echo "release_version=$version" >> "$GITHUB_OUTPUT"
}

# Main script execution
main() {
    check_requirements
    validate_branch

    local version
    version=$(get_version)

    delete_existing_tag "$version"
    create_and_push_tag "$version"
}

main "$@"
