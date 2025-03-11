#!/bin/bash

# Get the current version from argument or use default
CURRENT_VERSION=${1:-"v0.0.0"}
BUMP_TYPE=${2:-"patch"} # Default to patch if not specified

# Extract the numeric version (remove 'v' prefix)
VERSION_NUMBER=${CURRENT_VERSION#v}

# Split into major, minor, and patch
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_NUMBER"

# Increment the specified version part
case "$BUMP_TYPE" in
  "patch")
    PATCH=$((PATCH + 1))
    ;;
  "minor")
    MINOR=$((MINOR + 1))
    PATCH=0 # Reset patch when bumping minor
    ;;
  "major")
    MAJOR=$((MAJOR + 1))
    MINOR=0 # Reset minor when bumping major
    PATCH=0 # Reset patch when bumping major
    ;;
  *)
    echo "Invalid bump type. Use 'patch', 'minor', or 'major'."
    exit 1
    ;;
esac

# Construct the new version
NEW_VERSION="v$MAJOR.$MINOR.$PATCH"

# Output the new version
echo "$NEW_VERSION"
