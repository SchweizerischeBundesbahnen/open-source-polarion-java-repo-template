#!/bin/bash

# Script to test GitHub Actions workflows locally using Act
# Created on: April 21, 2025

set -e  # Exit on any error

# Colors for better output readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
info() {
  echo -e "${BLUE}INFO: $1${NC}"
}

success() {
  echo -e "${GREEN}SUCCESS: $1${NC}"
}

warning() {
  echo -e "${YELLOW}WARNING: $1${NC}"
}

error() {
  echo -e "${RED}ERROR: $1${NC}"
}

# Create a log file
LOG_FILE="/tmp/test_workflows_$(date +%Y%m%d_%H%M%S).log"
echo "Starting test workflow script. Log file: $LOG_FILE" | tee -a "$LOG_FILE"

# Check if act is installed
if ! command -v act &> /dev/null; then
  error "Act is not installed. Please install it first:" | tee -a "$LOG_FILE"
  echo "  brew install act" | tee -a "$LOG_FILE"
  exit 1
fi

# Check if Docker is running
if ! docker ps &> /dev/null; then
  error "Docker is not running. Please start Docker Desktop and try again." | tee -a "$LOG_FILE"
  exit 1
else
  info "Docker is running correctly" | tee -a "$LOG_FILE"
fi

# Repository root directory
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$(cd "$(dirname "$0")/../.." && pwd)")"
cd "$REPO_ROOT"

info "Using repository root: $REPO_ROOT" | tee -a "$LOG_FILE"

# Check if we're in the right repository
if [ ! -f ".github/workflows/maven-build.yml" ]; then
  error "Could not find .github/workflows/maven-build.yml. Are you in the right repository?" | tee -a "$LOG_FILE"
  exit 1
else
  info "Found maven-build.yml workflow file" | tee -a "$LOG_FILE"
fi

# Default values
JOB="build"
PREVIEW_ONLY=false
ARCHITECTURE="linux/amd64"  # Default for Mac M1/M2/M3 chips

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --preview)
      PREVIEW_ONLY=true
      shift
      ;;
    --job|-j)
      JOB="$2"
      shift 2
      ;;
    --architecture|-a)
      ARCHITECTURE="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [options]" | tee -a "$LOG_FILE"
      echo "" | tee -a "$LOG_FILE"
      echo "Options:" | tee -a "$LOG_FILE"
      echo "  --preview             Show commands without executing them" | tee -a "$LOG_FILE"
      echo "  --job, -j JOB         Specify the job to run (default: build)" | tee -a "$LOG_FILE"
      echo "  --architecture, -a ARCH  Specify the container architecture (default: linux/amd64)" | tee -a "$LOG_FILE"
      echo "  --help, -h            Show this help message" | tee -a "$LOG_FILE"
      exit 0
      ;;
    *)
      error "Unknown option: $1" | tee -a "$LOG_FILE"
      exit 1
      ;;
  esac
done

# Build command
ACT_CMD="act -j $JOB -s GITHUB_TOKEN=fake_token --container-architecture $ARCHITECTURE"

# Maven settings info
info "This script will test the GitHub Actions workflow with the s4u/maven-settings-action" | tee -a "$LOG_FILE"
info "It will generate a settings.xml file that can be inspected after the test" | tee -a "$LOG_FILE"

# Print job and command information
echo "Job to run: $JOB" | tee -a "$LOG_FILE"
echo "Using architecture: $ARCHITECTURE" | tee -a "$LOG_FILE"
echo "Command: $ACT_CMD" | tee -a "$LOG_FILE"

# Execute or print command
if [ "$PREVIEW_ONLY" = true ]; then
  warning "PREVIEW: Would execute the following command:" | tee -a "$LOG_FILE"
  echo "$ACT_CMD" | tee -a "$LOG_FILE"
  echo "Preview completed successfully. To run for real, remove the --preview flag." | tee -a "$LOG_FILE"
else
  info "Running act with job: $JOB" | tee -a "$LOG_FILE"

  # Run the command and capture both output and exit status
  OUTPUT=$(eval "$ACT_CMD" 2>&1)
  EXIT_STATUS=$?
  echo "$OUTPUT" | tee -a "$LOG_FILE"

  # Check if there are Docker connection errors
  if echo "$OUTPUT" | grep -q "Cannot connect to the Docker daemon"; then
    error "Docker connection failed. Make sure Docker is running and accessible." | tee -a "$LOG_FILE"
    echo "Try running the following command to verify Docker is working:" | tee -a "$LOG_FILE"
    echo "  docker run --rm hello-world" | tee -a "$LOG_FILE"
    EXIT_STATUS=1
  fi

  # Extract settings.xml from the output if it exists
  SETTINGS_XML=$(echo "$OUTPUT" | grep -A 1000 "Print settings.xml" | grep -B 1000 -m 1 "^<settings" | grep -A 1000 "^</settings>")

  # Generate expected settings.xml for comparison
  EXPECTED_SETTINGS_XML_FILE="/tmp/expected_settings_$(date +%s).xml"
  cat > "$EXPECTED_SETTINGS_XML_FILE" << EOF
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <activeProfiles>
    <activeProfile>github</activeProfile>
    <activeProfile>deploy-github-packages</activeProfile>
  </activeProfiles>
  <profiles>
    <profile>
      <id>github</id>
      <repositories>
        <repository>
          <id>s3</id>
          <name>s3.sbb.polarion.maven.repo</name>
          <url>s3://sbb-polarion-maven-repo/polarion.mvn</url>
          <releases>
            <enabled>true</enabled>
            <updatePolicy>never</updatePolicy>
          </releases>
        </repository>
      </repositories>
    </profile>
    <profile>
      <id>deploy-github-packages</id>
      <properties>
        <altDeploymentRepository>github::default::https://maven.pkg.github.com/SchweizerischeBundesbahnen/open-source-polarion-java-repo-template</altDeploymentRepository>
      </properties>
    </profile>
  </profiles>
  <servers>
    <server>
      <id>s3</id>
      <username>\${env.S3_SBB_POLARION_MAVEN_REPO_RW_ACCESS_KEY}</username>
      <password>\${env.S3_SBB_POLARION_MAVEN_REPO_RW_SECRET_ACCESS_KEY}</password>
    </server>
    <server>
      <id>github</id>
      <username>\${env.GITHUB_ACTOR}</username>
      <password>\${env.GITHUB_TOKEN}</password>
    </server>
    <server>
      <id>ossrh</id>
      <username>\${env.COM_SONATYPE_CENTRAL_POLARION_OPENSOURCE_USERNAME}</username>
      <password>\${env.COM_SONATYPE_CENTRAL_POLARION_OPENSOURCE_TOKEN}</password>
    </server>
    <server>
      <id>gpg.passphrase</id>
      <passphrase>\${env.COM_SONATYPE_CENTRAL_POLARION_OPENSOURCE_GPG_PASSPHRASE}</passphrase>
    </server>
  </servers>
  <mirrors/>
  <pluginGroups/>
</settings>
EOF

  # Function to normalize XML for comparison
  normalize_xml() {
    # Save to a temp file
    local xml_content=$1
    local temp_file=$(mktemp)
    echo "$xml_content" > "$temp_file"

    # Remove whitespace, normalize line endings, sort attributes
    xmllint --noblanks --format "$temp_file" 2>/dev/null || echo "$xml_content"
    rm "$temp_file"
  }

  # Check if the act command succeeded based on the exit status
  if [ $EXIT_STATUS -eq 0 ]; then
    success "Act completed successfully!" | tee -a "$LOG_FILE"

    # If this was testing the build job, display and validate the settings.xml
    if [ "$JOB" = "build" ]; then
      if [ -n "$SETTINGS_XML" ]; then
        success "Found settings.xml in the output!" | tee -a "$LOG_FILE"
        echo "==================== ACTUAL SETTINGS.XML CONTENT =====================" | tee -a "$LOG_FILE"
        echo "$SETTINGS_XML" | tee -a "$LOG_FILE"
        echo "===============================================================" | tee -a "$LOG_FILE"

        # Save actual settings.xml to file for comparison
        ACTUAL_SETTINGS_XML_FILE="/tmp/actual_settings_$(date +%s).xml"
        echo "$SETTINGS_XML" > "$ACTUAL_SETTINGS_XML_FILE"

        # Check if xmllint is installed for XML comparison
        if command -v xmllint &> /dev/null; then
          info "Comparing expected settings.xml with actual generated settings.xml..." | tee -a "$LOG_FILE"

          # Normalize both XML files
          NORMALIZED_EXPECTED=$(normalize_xml "$(cat "$EXPECTED_SETTINGS_XML_FILE")")
          NORMALIZED_ACTUAL=$(normalize_xml "$SETTINGS_XML")

          # Compare normalized content
          if [ "$(echo "$NORMALIZED_EXPECTED" | tr -d '[:space:]')" = "$(echo "$NORMALIZED_ACTUAL" | tr -d '[:space:]')" ]; then
            success "VALIDATION PASSED: settings.xml content matches expected template!" | tee -a "$LOG_FILE"
          else
            warning "VALIDATION FAILED: settings.xml content doesn't match expected template." | tee -a "$LOG_FILE"
            echo "Differences between expected and actual settings.xml:" | tee -a "$LOG_FILE"

            # Create diff files for comparison
            NORMALIZED_EXPECTED_FILE="/tmp/normalized_expected_$(date +%s).xml"
            NORMALIZED_ACTUAL_FILE="/tmp/normalized_actual_$(date +%s).xml"
            echo "$NORMALIZED_EXPECTED" > "$NORMALIZED_EXPECTED_FILE"
            echo "$NORMALIZED_ACTUAL" > "$NORMALIZED_ACTUAL_FILE"

            # Show diff
            if command -v diff &> /dev/null; then
              diff -u "$NORMALIZED_EXPECTED_FILE" "$NORMALIZED_ACTUAL_FILE" | tee -a "$LOG_FILE"
            else
              echo "Install 'diff' to see detailed differences" | tee -a "$LOG_FILE"
            fi

            echo "Comparison files saved at:" | tee -a "$LOG_FILE"
            echo "- Expected: $NORMALIZED_EXPECTED_FILE" | tee -a "$LOG_FILE"
            echo "- Actual: $NORMALIZED_ACTUAL_FILE" | tee -a "$LOG_FILE"
          fi
        else
          warning "xmllint not found. Skipping XML comparison. Install xmllint for XML validation:" | tee -a "$LOG_FILE"
          echo "  brew install libxml2" | tee -a "$LOG_FILE"
        fi
      else
        warning "Could not find settings.xml in the output. The Maven settings action might not have executed." | tee -a "$LOG_FILE"
      fi
    fi
  else
    error "Act failed to run the workflow. See above for details." | tee -a "$LOG_FILE"
  fi
fi

# Set exit code for the whole script based on the success of the Act command
SCRIPT_EXIT_STATUS=0
if [ "$PREVIEW_ONLY" = false ] && [ $EXIT_STATUS -ne 0 ]; then
  SCRIPT_EXIT_STATUS=1
  FINAL_STATUS="FAILED"
else
  FINAL_STATUS="COMPLETED"
fi

info "Test $FINAL_STATUS. Log file available at: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================="
echo "TEST SUMMARY:"
echo "-----------------------------------------"
echo "Script executed on: $(date)"
echo "Mode: $([ "$PREVIEW_ONLY" = true ] && echo "PREVIEW" || echo "EXECUTION")"
echo "Job: $JOB"
echo "Architecture: $ARCHITECTURE"
echo "Command: $ACT_CMD"
echo "Status: $FINAL_STATUS"
echo "Log file: $LOG_FILE"
echo "========================================="

exit $SCRIPT_EXIT_STATUS
