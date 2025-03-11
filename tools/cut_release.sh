#!/bin/bash

set -euo pipefail # Exit on error, unset variables, or failed piped commands

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
TODAY_DATE=$(date +'%Y.%m.%d')
RELEASE_BRANCH="release/$TODAY_DATE"
GITHUB_EVENT_NAME=$1
BUMP_VERSION="$GITHUB_ACTION_PATH/../../tools/bump_version.sh"

# Function to check requirements
check_requirements() {
    echo "🔍 Checking system requirements..."

    if ! command -v jq &>/dev/null; then
        echo "❌ Error: jq is not installed" >&2
        exit 1
    fi

    if [[ ! -x $BUMP_VERSION ]]; then
        echo "⚙️ Making $BUMP_VERSION executable..."
        chmod +x "$BUMP_VERSION"
    fi

    echo "✅ All requirements are met."
}

# Function to commit a bump commit to master
bump_version_on_master() {
    local bump_type="$1"

    echo "🔄 Retrieving current version..."
    CURRENT_VERSION=$(jq -r '.version' manifest.json)

    echo "📈 Bumping version ($bump_type) from $CURRENT_VERSION..."
    NEW_VERSION="$($BUMP_VERSION "$CURRENT_VERSION" "$bump_type")"

    echo "🔢 New version: $NEW_VERSION"

    jq --arg version "$NEW_VERSION" '.version = $version' manifest.json > manifest.tmp && mv manifest.tmp manifest.json

    echo "📂 Staging version update..."
    git add manifest.json

    echo "📝 Committing version update..."
    git commit -m "chore: bump version to $NEW_VERSION"

    echo "🚀 Pushing updated version to master..."
    git push origin master

    echo "✅ Version bump to $NEW_VERSION completed."
}

# Function to delete all old release branches
delete_old_release_branches() {
    echo "🧹 Cleaning up old release branches..."

    # Fetch latest branches
    git fetch --prune

    # Get list of remote branches under 'release/'
    branches=$(git branch -r | grep 'release/' | grep -v "origin/HEAD" | sed 's/origin\///')

    for branch in $branches; do
        echo "❌ Deleting branch: $branch"
        git push origin --delete "$branch" || echo "⚠️ Failed to delete $branch"
    done

    echo "✅ All old release branches have been removed."
}

# Handle the case that this script is running on master branch
handle_master_branch() {
    if [[ $GITHUB_EVENT_NAME == "workflow_dispatch" ]]; then
        # TODO: Should we support it?
        echo "🚫 Cut-off on master should not be done manually"
        exit 1
    fi

    if git ls-remote --exit-code --heads origin "$RELEASE_BRANCH" &>/dev/null; then
        # TODO: Should we support it?
        echo "⚠️ Release branch '$RELEASE_BRANCH' already exists. Please re-cut on it."
        exit 1
    fi

    echo "🧹 Cleaning up old release branches..."
    delete_old_release_branches

    echo "🚀 Creating a new release branch: '$RELEASE_BRANCH'"
    git pull origin master

    echo "📈 Bumping minor version on master..."
    bump_version_on_master "minor"

    echo "🔀 Checking out new release branch '$RELEASE_BRANCH'..."
    git checkout -b "$RELEASE_BRANCH"

    echo "🚢 Pushing new release branch to remote..."
    git push origin "$RELEASE_BRANCH"

    echo "🔙 Switching back to master..."
    git checkout master

    echo "🎉 Release branch '$RELEASE_BRANCH' has been created and pushed successfully!"
}

# Handle the case that this script is running on release/* branch
handle_release_branch() {
    echo "🚀 On release branch '$BRANCH'. Bumping patch version on master and updating release branch..."

    echo "🔄 Fetching latest changes from origin/master..."
    git fetch origin master

    echo "🔀 Switching to master and pulling latest updates..."
    git checkout master
    git pull origin master

    echo "📌 Bumping patch version on master..."
    bump_version_on_master "patch"

    echo "🔀 Switching back to release branch '$BRANCH'..."
    git checkout "$BRANCH"

    echo "⚡ Resetting release branch to match master..."
    git reset --hard master

    echo "🚢 Pushing updated release branch '$BRANCH' to remote..."
    git push --force origin "$BRANCH"

    echo "✅ Release branch '$BRANCH' has been updated."
}

# Main execution
main() {
    check_requirements
    if [[ $BRANCH == "master" ]]; then
        handle_master_branch
    elif [[ $BRANCH == release/* ]]; then
        handle_release_branch
    else
        echo "❌ Error: You must be on the master or a release branch to run this script."
        exit 1
    fi
}

main "@"
