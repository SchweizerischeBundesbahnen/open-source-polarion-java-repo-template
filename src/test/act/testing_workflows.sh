#!/bin/bash
# Script to test GitHub Actions workflows using act
# Usage: ./test_workflows.sh [workflow_file] [job_name]
# Example: ./test_workflows.sh .github/workflows/maven-build.yml build

set -e

# Configuration
REPO_ROOT="$(git rev-parse --show-toplevel)"
DOCKER_SOCKET=$(docker context inspect rancher-desktop -f '{{.Endpoints.docker.Host}}')
SECRETS_FILE="${REPO_ROOT}/src/test/act/secrets.env"
ACT_CONFIG="${REPO_ROOT}/.actrc"

# Default values
WORKFLOW_FILE="${1:-.github/workflows/maven-build.yml}"
JOB_NAME="${2:-build}"
EVENT_TYPE="${3:-push}"

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print header
echo -e "${GREEN}===== GitHub Actions Workflow Test =====${NC}"
echo -e "Repository: ${YELLOW}${REPO_ROOT}${NC}"
echo -e "Workflow: ${YELLOW}${WORKFLOW_FILE}${NC}"
echo -e "Job: ${YELLOW}${JOB_NAME}${NC}"
echo -e "Event: ${YELLOW}${EVENT_TYPE}${NC}"
echo -e "Docker socket: ${YELLOW}${DOCKER_SOCKET}${NC}"
echo -e "Secrets file: ${YELLOW}${SECRETS_FILE}${NC}"
echo -e "Act config: ${YELLOW}${ACT_CONFIG}${NC}"
echo -e "${GREEN}=======================================${NC}\n"

# Verify Docker is running
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

# Run dry-run first to check configuration
echo -e "${YELLOW}Running dry-run to validate configuration...${NC}"
act -n "$EVENT_TYPE" -W "$WORKFLOW_FILE" -j "$JOB_NAME" --container-daemon-socket "$DOCKER_SOCKET" --secret-file "$SECRETS_FILE"

# Ask for confirmation before running the actual workflow
echo -e "\n${YELLOW}Do you want to run the actual workflow? (y/N)${NC}"
read -r CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo -e "${GREEN}Running the workflow...${NC}"
  act "$EVENT_TYPE" -W "$WORKFLOW_FILE" -j "$JOB_NAME" --container-daemon-socket "$DOCKER_SOCKET" --secret-file "$SECRETS_FILE"
else
  echo -e "${YELLOW}Workflow run cancelled.${NC}"
fi

# Note about other options
echo -e "\n${GREEN}===== Additional Options =====${NC}"
echo -e "To run with verbose output: add -v flag"
echo -e "To run a specific event: ${YELLOW}$0 $WORKFLOW_FILE $JOB_NAME workflow_dispatch${NC}"
echo -e "To list all jobs in the workflow: ${YELLOW}act -l -W $WORKFLOW_FILE"
echo -e "${GREEN}===========================${NC}"
