#!/bin/bash

set -euo pipefail

if ! command -v jq &>/dev/null; then
    echo "Error: jq is not installed" >&2
    exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if [[ ! $BRANCH =~ ^release/.*$ ]]; then
    echo "Releasing PROD must be from the release branch"
    exit 1
fi

VERSION=$(jq -r '.version' "manifest.json")
echo "Current version: $VERSION"

if git rev-parse "refs/tags/$VERSION" >/dev/null 2>&1; then
    echo "Tag $VERSION already exists. Deleting..."
    git tag -d "$VERSION"
    git push --delete origin "$VERSION"
    echo "Deleted existing tag: $VERSION"
fi

echo "Creating and pushing tag: $VERSION"
git tag "$VERSION"
git push origin "$VERSION"

echo "Tag $VERSION created and pushed successfully."
echo "release_version=$VERSION" >> "$GITHUB_OUTPUT"
