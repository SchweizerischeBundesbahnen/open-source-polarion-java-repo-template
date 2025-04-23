# Testing GitHub Actions Workflows Locally

This document provides guidance on how to test GitHub Actions workflows locally using the `act` tool with Docker as the container runtime.

## Requirements

- Docker
- Act CLI tool (installation instructions below)
- A local clone of the repository

## Installation

### Installing Act with Homebrew

On macOS, the easiest way to install Act is using Homebrew:

```bash
# Install Homebrew if you don't have it already
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Act
brew install act
```

To verify the installation:

```bash
act --version
```

For other operating systems or alternative installation methods, visit the [Act GitHub Repository](https://github.com/nektos/act).

### Docker Requirements

Make sure Docker is installed and running on your system. On macOS, Docker Desktop or Rancher Desktop are common options.

To verify Docker is running:

```bash
docker info
```

If you're using Rancher Desktop, the Docker socket will typically be at `~/.rd/docker.sock`.

## Quick Start

The simplest way to test a workflow is to use the provided `testing_workflows.sh` script:

```bash
# Navigate to the repository root
cd /path/to/repository

# Run with default settings (push event)
./src/test/act/testing_workflows.sh

# Test a pull request event with specific base and head branches
./src/test/act/testing_workflows.sh --event=pull_request --pr-base=main --pr-head=feature-branch

# Run with specific options using named parameters
./src/test/act/testing_workflows.sh --workflow=.github/workflows/maven-build.yml --job=build --event=push

# Get help for available options
./src/test/act/testing_workflows.sh --help
```

All parameters are optional and use sensible defaults:
```
Options:
  --workflow=FILE     Workflow file to test (default: .github/workflows/maven-build.yml)
  --job=NAME          Job name to test (default: build)
  --event=TYPE        Event type to trigger (default: push)
  --pr-base=BRANCH    Base branch for pull_request event (default: main)
  --pr-head=BRANCH    Head branch for pull_request event (default: feature-branch)
  -h, --help          Show this help message
```

## Manual Testing Commands

If you prefer to run commands manually, here are the key commands to use:

### Check Act Installation

```bash
act --version
```

### List All Jobs in a Workflow

```bash
act -l -W .github/workflows/maven-build.yml
```

### Running Workflows with Docker

```bash
# Get Docker socket path
DOCKER_SOCKET=$(docker context inspect rancher-desktop -f '{{.Endpoints.docker.Host}}' 2>/dev/null || echo "unix:///var/run/docker.sock")

# Run dry-run
act -n push -W .github/workflows/maven-build.yml -j build --container-daemon-socket "$DOCKER_SOCKET" --secret-file src/test/act/secrets.env

# Run the workflow
act push -W .github/workflows/maven-build.yml -j build --container-daemon-socket "$DOCKER_SOCKET" --secret-file src/test/act/secrets.env
```

### Testing Different Event Types

GitHub Actions workflows can be triggered by different events. To test a specific event type:

```bash
# Get Docker socket path
DOCKER_SOCKET=$(docker context inspect rancher-desktop -f '{{.Endpoints.docker.Host}}' 2>/dev/null || echo "unix:///var/run/docker.sock")

# Test a workflow_dispatch event
act workflow_dispatch -W .github/workflows/maven-build.yml -j build --container-daemon-socket "$DOCKER_SOCKET" --secret-file src/test/act/secrets.env

# Test a pull_request event (basic)
act pull_request -W .github/workflows/maven-build.yml -j build --container-daemon-socket "$DOCKER_SOCKET" --secret-file src/test/act/secrets.env

# Test a pull_request event with custom event payload
cat > src/test/act/pr-event.json << EOF
{
  "pull_request": {
    "head": {
      "ref": "feature-branch",
      "sha": "$(git rev-parse HEAD)",
      "repo": {
        "full_name": "SchweizerischeBundesbahnen/open-source-polarion-java-repo-template"
      }
    },
    "base": {
      "ref": "main",
      "sha": "$(git rev-parse HEAD~1)",
      "repo": {
        "full_name": "SchweizerischeBundesbahnen/open-source-polarion-java-repo-template"
      }
    },
    "number": 123,
    "title": "Test PR for local workflow testing"
  },
  "repository": {
    "full_name": "SchweizerischeBundesbahnen/open-source-polarion-java-repo-template"
  },
  "action": "opened"
}
EOF

act pull_request -W .github/workflows/maven-build.yml -j build -e src/test/act/pr-event.json --container-daemon-socket "$DOCKER_SOCKET" --secret-file src/test/act/secrets.env
```

### Testing Pull Request-related Workflows

Pull request events are particularly important for CI/CD workflows. The script now provides enhanced support for testing pull request events with the following features:

1. **Specify base and head branches**:
   ```bash
   ./src/test/act/testing_workflows.sh --event=pull_request --pr-base=main --pr-head=feature-branch
   ```

2. **Automatically generates PR context**: The script creates an event.json file with realistic PR data including:
   - Current repository information
   - Branch references for base and head
   - Commit SHA values
   - PR number and title

3. **Proper cleanup**: Temporary event files are automatically removed after testing

This makes it much easier to test workflows that depend on PR-specific context, such as:
- Workflows that run different jobs based on the PR target branch
- Code that uses the GitHub context to fetch PR information
- Conditional steps that run only for certain PR patterns

## Configuration Files

### Secrets File

Workflows often require secrets. Create or modify the `src/test/act/secrets.env` file with the following format:

```
KEY1=value1
KEY2=value2
```

For this repository, you'll need secrets like:

```
GITHUB_TOKEN=fake_github_token
S3_SBB_POLARION_MAVEN_REPO_RW_ACCESS_KEY=fake_s3_access_key
S3_SBB_POLARION_MAVEN_REPO_RW_SECRET_ACCESS_KEY=fake_s3_secret_key
SONAR_TOKEN=fake_sonar_token
COM_SONATYPE_CENTRAL_POLARION_OPENSOURCE_GPG_PRIVATE_KEY=fake_gpg_key
COM_SONATYPE_CENTRAL_POLARION_OPENSOURCE_USERNAME=fake_sonatype_username
COM_SONATYPE_CENTRAL_POLARION_OPENSOURCE_TOKEN=fake_sonatype_token
COM_SONATYPE_CENTRAL_POLARION_OPENSOURCE_GPG_PASSPHRASE=fake_gpg_passphrase
```

### Act Configuration File

The `src/test/act/.actrc` file contains configuration for Act:

```
--container-architecture=linux/amd64
-P ubuntu-latest=catthehacker/ubuntu:act-latest
```

This specifies that Act should use Linux/AMD64 architecture for containers and a specific Docker image for the ubuntu-latest runner.

Both configuration files are automatically created by the `testing_workflows.sh` script if they don't exist.

## Common Issues and Solutions

### Docker Connection Issues

Make sure Docker is running and you have the correct socket path:

```bash
# Check if Docker is running
docker info

# Check Docker context
docker context inspect
```

For Rancher Desktop users, the socket path is usually: `unix:///Users/username/.rd/docker.sock`

### Missing Secrets

If your workflow fails due to missing secrets, ensure your `src/test/act/secrets.env` file includes all required secrets.

### Authentication Issues

When running GitHub Actions locally, you may encounter authentication errors when the workflow tries to clone GitHub repositories. This is expected behavior in a local testing environment.

If you need to resolve these issues, you can:

1. Provide a valid GitHub token in your secrets file
2. Configure Git credential helper for HTTPS authentication
3. Use SSH authentication for GitHub

### Platform/Architecture Issues

Some actions might not work locally due to platform differences. In these cases, you can modify the `src/test/act/.actrc` file to include appropriate platform settings.

## Additional Tips

- Add `-v` flag for verbose output
- Use `--bind` flag to mount additional directories
- For complex workflows, consider testing one job at a time
- When testing PR workflows, ensure your local git repository has at least one commit history
- The PR base and head branches don't need to actually exist locally - they're just references used in the event payload

## Debugging Workflows

To debug a failing workflow:

1. Run with verbose output: `act -v ...`
2. Check the logs for errors
3. Test jobs individually
4. Modify your workflow temporarily to add debug steps

## References

- [Act GitHub Repository](https://github.com/nektos/act)
- [Act Documentation](https://nektosact.com/)
- [Docker Documentation](https://docs.docker.com/)
