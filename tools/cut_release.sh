#!/bin/bash

set -euo pipefail

BUMP_VERSION='./tools/bump_version.sh'

check_requirements() {
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is not installed" >&2
        exit 1
    fi

    if [[ ! -x $BUMP_VERSION ]]; then
        echo "Error: $BUMP_VERSION is not executable" >&2
        exit 1
    fi
}

bump_version_on_master() {
    local bump_type="$1"
    CURRENT_VERSION=$(jq -r '.version' manifest.json)
    NEW_VERSION="$($BUMP_VERSION "$CURRENT_VERSION" "$bump_type")"

    echo "Current version: $CURRENT_VERSION"
    echo "New version ($bump_type bump): $NEW_VERSION"

    jq --arg version "$NEW_VERSION" '.version = $version' manifest.json > manifest.tmp && mv manifest.tmp manifest.json
    git add manifest.json
    git commit -m "chore: bump version to $NEW_VERSION"
    git push origin master
}

delete_yesterday_branch() {
    local yesterday_branch
    yesterday_branch="release/$(date -d "yesterday" +'%Y.%m.%d') "
    echo "Deleting branch: $yesterday_branch"
    git push origin --delete "$yesterday_branch" || echo "Branch $yesterday_branch not found on remote"
}

handle_master_branch() {
    if [[ $GITHUB_EVENT_NAME == "workflow_dispatch" ]]; then
        echo "Cut-off on master should not be done manually"
        exit 1
    fi

    if git ls-remote --exit-code --heads origin "$RELEASE_BRANCH" &>/dev/null; then
        echo "Release branch '$RELEASE_BRANCH' already exists. Bumping patch version on master and updating release branch..."
        git pull origin master
        bump_version_on_master "patch"
        git fetch origin "$RELEASE_BRANCH"
        git checkout "$RELEASE_BRANCH"
        git reset --hard master
        git push --force origin "$RELEASE_BRANCH"
        git checkout master
        echo "Release branch '$RELEASE_BRANCH' has been updated."
    else
        delete_yesterday_branch
        echo "Creating a new release branch: $RELEASE_BRANCH"
        git pull origin master
        bump_version_on_master "minor"
        git checkout -b "$RELEASE_BRANCH"
        git push origin "$RELEASE_BRANCH"
        echo "Release branch '$RELEASE_BRANCH' has been created and pushed."
    fi
}

handle_release_branch() {
    echo "On release branch '$BRANCH'. Bumping patch version on master and updating release branch..."
    git fetch origin master
    git checkout master
    git pull origin master
    bump_version_on_master "patch"
    git checkout "$BRANCH"
    git reset --hard master
    git push --force origin "$BRANCH"
    echo "Release branch '$BRANCH' has been updated."
}

# Main execution
check_requirements

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
TODAY_DATE=$(date +'%Y.%m.%d')
RELEASE_BRANCH="release/$TODAY_DATE"
GITHUB_EVENT_NAME=$1

if [[ $BRANCH == "master" ]]; then
    handle_master_branch
elif [[ $BRANCH == release/* ]]; then
    handle_release_branch
else
    echo "Error: You must be on the master or a release branch to run this script."
    exit 1
fi
