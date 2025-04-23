#!/bin/bash
# Script to test GitHub Actions workflows using act
# Usage: ./test_workflows.sh [--workflow=FILE] [--job=NAME] [--event=TYPE] [--container=RUNTIME]
# Example: ./test_workflows.sh --workflow=.github/workflows/maven-build.yml --job=build --container=docker

set -e

# Default values
WORKFLOW_FILE=".github/workflows/maven-build.yml"
JOB_NAME="build"
EVENT_TYPE="push"
export ACT_CONTAINER_RUNTIME="${ACT_CONTAINER_RUNTIME:-podman}"

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
    --container=*)
      export ACT_CONTAINER_RUNTIME="${i#*=}"
      ;;
    -h|--help)
      echo "Usage: $0 [--workflow=FILE] [--job=NAME] [--event=TYPE] [--container=RUNTIME]"
      echo "Options:"
      echo "  --workflow=FILE    Workflow file to test (default: .github/workflows/maven-build.yml)"
      echo "  --job=NAME         Job name to test (default: build)"
      echo "  --event=TYPE       Event type to trigger (default: push)"
      echo "  --container=RUNTIME Container runtime to use (podman or docker, default: podman)"
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

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Set container-specific variables
if [[ "$ACT_CONTAINER_RUNTIME" == "docker" ]]; then
  DOCKER_SOCKET=$(docker context inspect rancher-desktop -f '{{.Endpoints.docker.Host}}' 2>/dev/null || echo "unix:///var/run/docker.sock")
  CONTAINER_DAEMON_SOCK="$DOCKER_SOCKET"
  CONTAINER_ARGS="--container-daemon-socket \"$DOCKER_SOCKET\""
else
  # For Podman, we need to set the correct socket path
  # Get the podman socket path
  PODMAN_SOCKET=$(podman info --format '{{.Host.RemoteSocket.Path}}' 2>/dev/null || echo "unix:///run/podman/podman.sock")
  CONTAINER_DAEMON_SOCK="$PODMAN_SOCKET"
  CONTAINER_ARGS="--container-daemon-socket \"$PODMAN_SOCKET\""
  # Make sure to set the environment variable for act
  export DOCKER_HOST="$PODMAN_SOCKET"
fi

# Set trap to ensure cleanup happens even if script exits early
trap cleanup EXIT

# Cleanup function to remove secrets file
cleanup() {
  echo -e "\n${YELLOW}Cleaning up secrets file...${NC}"
  if [ -f "$SECRETS_FILE" ]; then
    rm -f "$SECRETS_FILE"
    echo -e "${GREEN}Secrets file removed for security.${NC}"
  fi
}

# Print header
echo -e "${GREEN}===== GitHub Actions Workflow Test =====${NC}"
echo -e "Repository: ${YELLOW}${REPO_ROOT}${NC}"
echo -e "Workflow: ${YELLOW}${WORKFLOW_FILE}${NC}"
echo -e "Workflow Path: ${YELLOW}${WORKFLOW_PATH}${NC}"
echo -e "Job: ${YELLOW}${JOB_NAME}${NC}"
echo -e "Event: ${YELLOW}${EVENT_TYPE}${NC}"
echo -e "Container Runtime: ${YELLOW}${ACT_CONTAINER_RUNTIME}${NC}"
if [[ "$ACT_CONTAINER_RUNTIME" == "docker" ]]; then
  echo -e "Docker socket: ${YELLOW}${CONTAINER_DAEMON_SOCK}${NC}"
else
  echo -e "Podman socket: ${YELLOW}${CONTAINER_DAEMON_SOCK}${NC}"
fi
echo -e "Secrets file: ${YELLOW}${SECRETS_FILE}${NC}"
echo -e "Act config: ${YELLOW}${ACT_CONFIG}${NC}"
echo -e "${GREEN}=======================================${NC}\n"

# Verify container runtime is running
echo -e "${YELLOW}Checking ${ACT_CONTAINER_RUNTIME} status...${NC}"
if [[ "$ACT_CONTAINER_RUNTIME" == "docker" ]]; then
  if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Docker is not running. Please start Docker and try again.${NC}"
    exit 1
  fi
  echo -e "${GREEN}Docker is running.${NC}\n"
else
  if ! podman info > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Podman is not running. Please start Podman machine with 'podman machine start' and try again.${NC}"
    exit 1
  fi
  echo -e "${GREEN}Podman is running.${NC}\n"
fi

# Verify act is installed
echo -e "${YELLOW}Checking act installation...${NC}"
if ! command -v act &> /dev/null; then
  echo -e "${RED}ERROR: act is not installed. Please install act with 'brew install act' and try again.${NC}"
  exit 1
fi
echo -e "${GREEN}act $(act --version) is installed.${NC}\n"

# Check if secrets file exists
if [ ! -f "$SECRETS_FILE" ]; then
  echo -e "${RED}WARNING: Secrets file ${SECRETS_FILE} not found. Creating a template file with placeholders.${NC}"
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
  echo -e "${YELLOW}Created template secrets file at ${SECRETS_FILE}${NC}\n"
fi

# Check if Act config file exists
if [ ! -f "$ACT_CONFIG" ]; then
  echo -e "${RED}WARNING: Act config file ${ACT_CONFIG} not found. Creating a default config file.${NC}"
  cat > "$ACT_CONFIG" << EOF
--container-architecture=linux/amd64
-P ubuntu-latest=catthehacker/ubuntu:act-latest
EOF
  echo -e "${YELLOW}Created default Act config file at ${ACT_CONFIG}${NC}\n"
fi

# Build the act command based on container runtime
DRY_RUN_CMD="act -n \"$EVENT_TYPE\" -W \"$WORKFLOW_PATH\" -j \"$JOB_NAME\" $CONTAINER_ARGS --secret-file \"$SECRETS_FILE\""
RUN_CMD="act \"$EVENT_TYPE\" -W \"$WORKFLOW_PATH\" -j \"$JOB_NAME\" $CONTAINER_ARGS --secret-file \"$SECRETS_FILE\""

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
echo -e "To use Docker instead of Podman: ${YELLOW}$0 --container=docker${NC}"
echo -e "To run a specific event: ${YELLOW}$0 --event=workflow_dispatch${NC}"
echo -e "To list all jobs in the workflow: ${YELLOW}act -l -W $WORKFLOW_PATH${NC}"
echo -e "${GREEN}===========================${NC}"
