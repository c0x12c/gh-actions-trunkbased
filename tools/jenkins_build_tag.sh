#!/bin/bash

# Read arguments
JENKINS_URL="$1"
GH_ORG="$2"
GH_REPO="$3"
JENKINS_USER="$4"
JENKINS_API_TOKEN="$5"
TAG="$6"

# Default retry delay
RETRY_DELAY=2

# Jenkins job URL
JENKINS_JOB_URL="$JENKINS_URL/job/$GH_ORG/job/$GH_REPO/view/tags/job/$TAG/build?delay=0sec"

# Function to trigger Jenkins build with retry
trigger_build() {
  local attempt=0
  local max_attempts=5
  local response_code

  while [ $attempt -lt $max_attempts ]; do
    response_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$JENKINS_JOB_URL" \
      --user "$JENKINS_USER:$JENKINS_API_TOKEN")

    if [ "$response_code" -ge 200 ] && [ "$response_code" -lt 300 ]; then
       echo "Build triggered successfully."
       return 0
    else
      echo "Attempt $((attempt+1)) failed with HTTP code $response_code. Retrying in $RETRY_DELAY seconds..."
      sleep "$RETRY_DELAY"
    fi

    attempt=$((attempt + 1))
  done
  echo "Failed to trigger build after $max_attempts attempts."
  return 1
}

# Execute the function
trigger_build