#!/bin/bash

set -euo pipefail  # Exit on error, unset variables, or failed piped commands

# Read arguments
JENKINS_URL="${1:-}"
FOLDER="${2:-}"
REPO_NAME="${3:-}"
JENKINS_USER="${4:-}"
JENKINS_API_TOKEN="${5:-}"
TAG="${6:-}"

# Default retry settings
MAX_ATTEMPTS=5
RETRY_DELAY=2
MAX_DELAY=30  # Prevent excessive delays

# Validate required inputs
validate_inputs() {
  if [[ -z "$JENKINS_URL" || -z "$FOLDER" || -z "$REPO_NAME" || -z "$JENKINS_USER" || -z "$JENKINS_API_TOKEN" || -z "$TAG" ]]; then
    echo "❌ Error: Missing required arguments." >&2
    echo "Usage: $0 <jenkins_url> <job_folder> <repo_name> <jenkins_user> <jenkins_api_token> <tag>" >&2
    exit 1
  fi

  # Ensure curl is installed
  if ! command -v curl &>/dev/null; then
    echo "❌ Error: curl is not installed." >&2
    exit 1
  fi

  # Ensure Jenkins URL is correctly formatted
  if ! [[ "$JENKINS_URL" =~ ^https?:// ]]; then
    echo "❌ Error: Invalid Jenkins URL. Ensure it starts with http:// or https://." >&2
    exit 1
  fi

  echo "✅ All requirements are met."
}

# Construct Jenkins job URL
construct_jenkins_url() {
  echo "$JENKINS_URL/job/$FOLDER/job/$REPO_NAME/view/tags/job/$TAG/build?delay=0sec"
}

# Function to trigger Jenkins build with retry logic
trigger_build() {
  local attempt=1
  local url response_code
  url=$(construct_jenkins_url)

  echo "🚀 Triggering build at: $url"

  while (( attempt <= MAX_ATTEMPTS )); do
    response_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$url" \
      --user "$JENKINS_USER:$JENKINS_API_TOKEN")

    if [[ "$response_code" -ge 200 && "$response_code" -lt 300 ]]; then
      echo "✅ Build triggered successfully on attempt $attempt."
      return 0
    else
      echo "⚠️ Attempt $attempt failed (HTTP $response_code). Retrying in $RETRY_DELAY seconds..."
      sleep "$RETRY_DELAY"
      RETRY_DELAY=$((RETRY_DELAY * 2 > MAX_DELAY ? MAX_DELAY : RETRY_DELAY * 2))  # Capped exponential backoff
    fi

    ((attempt++))
  done

  echo "❌ Failed to trigger build after $MAX_ATTEMPTS attempts."
  return 1
}

# Main execution
main() {
  validate_inputs
  trigger_build
}

main "$@"
