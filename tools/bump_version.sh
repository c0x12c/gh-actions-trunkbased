#!/bin/bash

set -euo pipefail  # Exit on error, unset variables, or failed piped commands

# Function to extract and split the version number
extract_version_parts() {
  local version="$1"
  local version_number="${version#v}"  # Remove 'v' prefix if present

  # Validate version format (must be numeric X.Y.Z)
  if ! [[ "$version_number" =~ ^[0-9]+(\.[0-9]+){2}$ ]]; then
    echo "❌ Error: Invalid version format '$version'. Expected 'vX.Y.Z' or 'X.Y.Z'." >&2
    exit 1
  fi

  IFS='.' read -r MAJOR MINOR PATCH <<< "$version_number"
}

# Function to increment the version based on bump type
bump_version() {
  local bump_type="$1"

  case "$bump_type" in
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
      echo "❌ Error: Invalid bump type '$bump_type'. Use 'patch', 'minor', or 'major'." >&2
      exit 1
      ;;
  esac
}

# Main script execution
main() {
  local current_version="${1:-"v0.0.0"}"
  local bump_type="${2:-"patch"}" # Default to "patch" if not specified

  extract_version_parts "$current_version"
  bump_version "$bump_type"

  # Should be the last line, the output
  echo "v$MAJOR.$MINOR.$PATCH"
}

# Run the script
main "$@"
