#!/bin/bash
# Script to test GitHub Actions workflows using act with Docker
# Usage: ./test_workflows.sh [--workflow=FILE] [--job=NAME] [--event=TYPE] [--pr-base=BRANCH] [--pr-head=BRANCH]
# Example: ./test_workflows.sh --workflow=.github/workflows/maven-build.yml --job=build --event=pull_request --pr-base=main --pr-head=feature-branch

set -e

# Default values
WORKFLOW_FILE=".github/workflows/maven-build.yml"
JOB_NAME="build"
EVENT_TYPE="push"
PR_BASE="main"
PR_HEAD="feature-branch"

# Parse named parameters
for i in "$@"; do
  case $i in
    --workflow=*)
      WORKFLOW_FILE="${i#*=}"
      ;;
    --job=*)
      JOB_NAME="${i#*=}"
      ;;
    --event=*)
      EVENT_TYPE="${i#*=}"
      ;;
    --pr-base=*)
      PR_BASE="${i#*=}"
      ;;
    --pr-head=*)
      PR_HEAD="${i#*=}"
      ;;
    -h|--help)
      echo "Usage: $0 [--workflow=FILE] [--job=NAME] [--event=TYPE] [--pr-base=BRANCH] [--pr-head=BRANCH]"
      echo "Options:"
      echo "  --workflow=FILE    Workflow file to test (default: .github/workflows/maven-build.yml)"
      echo "  --job=NAME         Job name to test (default: build)"
      echo "  --event=TYPE       Event type to trigger (default: push)"
      echo "  --pr-base=BRANCH   Base branch for pull_request event (default: main)"
      echo "  --pr-head=BRANCH   Head branch for pull_request event (default: feature-branch)"
      echo "  -h, --help         Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $i"
      echo "Use $0 --help for usage information"
      exit 1
      ;;
  esac
done

# Configuration
REPO_ROOT="$(git rev-parse --show-toplevel)"
SECRETS_FILE="${REPO_ROOT}/src/test/act/secrets.env"
ACT_CONFIG="${REPO_ROOT}/src/test/act/.actrc"
WORKFLOW_PATH="${REPO_ROOT}/${WORKFLOW_FILE}"
EVENT_JSON="${REPO_ROOT}/src/test/act/event.json"

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Set Docker socket
DOCKER_SOCKET=$(docker context inspect rancher-desktop -f '{{.Endpoints.docker.Host}}' 2>/dev/null || echo "unix:///var/run/docker.sock")
CONTAINER_ARGS="--container-daemon-socket \"$DOCKER_SOCKET\""

# Set trap to ensure cleanup happens even if script exits early
trap cleanup EXIT

# Cleanup function to remove temporary files
cleanup() {
  echo -e "\n${YELLOW}Cleaning up temporary files...${NC}"
  if [ -f "$SECRETS_FILE" ]; then
    rm -f "$SECRETS_FILE"
    echo -e "${GREEN}Secrets file removed for security.${NC}"
  fi
  if [ -f "$EVENT_JSON" ]; then
    rm -f "$EVENT_JSON"
    echo -e "${GREEN}Event JSON file removed.${NC}"
  fi
}

# Print header
echo -e "${GREEN}===== GitHub Actions Workflow Test =====${NC}"
echo -e "Repository: ${YELLOW}${REPO_ROOT}${NC}"
echo -e "Workflow: ${YELLOW}${WORKFLOW_FILE}${NC}"
echo -e "Workflow Path: ${YELLOW}${WORKFLOW_PATH}${NC}"
echo -e "Job: ${YELLOW}${JOB_NAME}${NC}"
echo -e "Event: ${YELLOW}${EVENT_TYPE}${NC}"
if [[ "$EVENT_TYPE" == "pull_request" ]]; then
  echo -e "PR Base Branch: ${YELLOW}${PR_BASE}${NC}"
  echo -e "PR Head Branch: ${YELLOW}${PR_HEAD}${NC}"
fi
echo -e "Docker socket: ${YELLOW}${DOCKER_SOCKET}${NC}"
echo -e "Secrets file: ${YELLOW}${SECRETS_FILE}${NC}"
echo -e "Act config: ${YELLOW}${ACT_CONFIG}${NC}"
echo -e "${GREEN}=======================================${NC}\n"

# Verify docker is running
echo -e "${YELLOW}Checking Docker status...${NC}"
if ! docker info > /dev/null 2>&1; then
  echo -e "${RED}ERROR: Docker is not running. Please start Docker and try again.${NC}"
  exit 1
fi
echo -e "${GREEN}Docker is running.${NC}\n"

# Verify act is installed
echo -e "${YELLOW}Checking act installation...${NC}"
if ! command -v act &> /dev/null; then
  echo -e "${RED}ERROR: act is not installed. Please install act with 'brew install act' and try again.${NC}"
  exit 1
fi
echo -e "${GREEN}act $(act --version) is installed.${NC}\n"

# Check if secrets file exists
if [ ! -f "$SECRETS_FILE" ]; then
  echo -e "${YELLOW}INFO: Creating template secrets file with placeholders at ${SECRETS_FILE}${NC}"
  cat > "$SECRETS_FILE" << EOF
GITHUB_TOKEN=fake_github_token
S3_SBB_POLARION_MAVEN_REPO_RW_ACCESS_KEY=fake_s3_access_key
S3_SBB_POLARION_MAVEN_REPO_RW_SECRET_ACCESS_KEY=fake_s3_secret_key
SONAR_TOKEN=fake_sonar_token
COM_SONATYPE_CENTRAL_POLARION_OPENSOURCE_GPG_PRIVATE_KEY=fake_gpg_key
COM_SONATYPE_CENTRAL_POLARION_OPENSOURCE_USERNAME=fake_sonatype_username
COM_SONATYPE_CENTRAL_POLARION_OPENSOURCE_TOKEN=fake_sonatype_token
COM_SONATYPE_CENTRAL_POLARION_OPENSOURCE_GPG_PASSPHRASE=fake_gpg_passphrase
EOF
  echo -e "${YELLOW}Secrets file contents:${NC}"
  cat "$SECRETS_FILE"
  echo ""
fi

# Check if Act config file exists
if [ ! -f "$ACT_CONFIG" ]; then
  echo -e "${YELLOW}INFO: Creating default Act config file at ${ACT_CONFIG}${NC}"
  cat > "$ACT_CONFIG" << EOF
--container-architecture=linux/amd64
-P ubuntu-latest=catthehacker/ubuntu:act-latest
EOF
  echo -e "${YELLOW}Act config file contents:${NC}"
  cat "$ACT_CONFIG"
  echo ""
fi

# Create event JSON for pull request event if needed
if [[ "$EVENT_TYPE" == "pull_request" ]]; then
  echo -e "${YELLOW}INFO: Creating pull request event JSON file at ${EVENT_JSON}${NC}"
  # Get current git details
  CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "unknown")
  REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
  OWNER_NAME=$(git remote get-url origin 2>/dev/null | sed -n 's/.*github.com[:/]\([^/]*\).*/\1/p' || echo "SchweizerischeBundesbahnen")

  # Create pull request event JSON
  cat > "$EVENT_JSON" << EOF
{
  "pull_request": {
    "head": {
      "ref": "${PR_HEAD}",
      "sha": "$(git rev-parse HEAD)",
      "repo": {
        "full_name": "${OWNER_NAME}/${REPO_NAME}"
      }
    },
    "base": {
      "ref": "${PR_BASE}",
      "sha": "$(git rev-parse HEAD~1 2>/dev/null || git rev-parse HEAD)",
      "repo": {
        "full_name": "${OWNER_NAME}/${REPO_NAME}"
      }
    },
    "number": 123,
    "title": "Test PR for local workflow testing"
  },
  "repository": {
    "full_name": "${OWNER_NAME}/${REPO_NAME}"
  },
  "action": "opened"
}
EOF
  echo -e "${YELLOW}Event JSON file contents:${NC}"
  cat "$EVENT_JSON"
  echo ""

  # Additional arguments for pull request event
  EVENT_ARGS="-e ${EVENT_JSON}"
else
  EVENT_ARGS=""
fi

# Build the act command
if [[ "$EVENT_TYPE" == "pull_request" ]]; then
  DRY_RUN_CMD="act -n pull_request -W \"$WORKFLOW_PATH\" -j \"$JOB_NAME\" $CONTAINER_ARGS $EVENT_ARGS --secret-file \"$SECRETS_FILE\""
  RUN_CMD="act pull_request -W \"$WORKFLOW_PATH\" -j \"$JOB_NAME\" $CONTAINER_ARGS $EVENT_ARGS --secret-file \"$SECRETS_FILE\""
else
  DRY_RUN_CMD="act -n \"$EVENT_TYPE\" -W \"$WORKFLOW_PATH\" -j \"$JOB_NAME\" $CONTAINER_ARGS --secret-file \"$SECRETS_FILE\""
  RUN_CMD="act \"$EVENT_TYPE\" -W \"$WORKFLOW_PATH\" -j \"$JOB_NAME\" $CONTAINER_ARGS --secret-file \"$SECRETS_FILE\""
fi

# Run dry-run first to check configuration
echo -e "${YELLOW}Running dry-run to validate configuration...${NC}"
eval $DRY_RUN_CMD

# Ask for confirmation before running the actual workflow
echo -e "\n${YELLOW}Do you want to run the actual workflow? (y/N)${NC}"
read -r CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo -e "${GREEN}Running the workflow...${NC}"
  eval $RUN_CMD
else
  echo -e "${YELLOW}Workflow run cancelled.${NC}"
fi

# Note about other options
echo -e "\n${GREEN}===== Additional Options =====${NC}"
echo -e "To run with verbose output: add -v to the act command"
echo -e "To run a specific event type examples:"
echo -e "  ${YELLOW}$0 --event=workflow_dispatch${NC}"
echo -e "  ${YELLOW}$0 --event=pull_request --pr-base=main --pr-head=feature-branch${NC}"
echo -e "To list all jobs in the workflow: ${YELLOW}act -l -W $WORKFLOW_PATH${NC}"
echo -e "${GREEN}===========================${NC}"
