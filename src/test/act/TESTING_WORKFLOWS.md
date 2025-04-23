# Testing GitHub Actions Workflows Locally

This document provides guidance on how to test GitHub Actions workflows locally using the `act` tool. The script supports both Podman and Docker, with Podman as the default container runtime.

## Requirements

- Podman or Docker
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

### Installing Podman (Alternative to Docker)

If you prefer to use Podman instead of Docker, you can install it on macOS using Homebrew:

```bash
# Install Podman
brew install podman

# Initialize Podman machine (only needed once)
podman machine init

# Start Podman machine
podman machine start
```

To verify the installation:

```bash
podman --version
podman info
```

For other operating systems or alternative installation methods, visit the [Podman Installation Guide](https://podman.io/getting-started/installation).

## Quick Start

The simplest way to test a workflow is to use the provided `testing_workflows.sh` script:

```bash
# Navigate to the repository root
cd /path/to/repository

# Run with default settings (uses Podman by default)
./src/test/act/testing_workflows.sh

# Run with specific options using named parameters
./src/test/act/testing_workflows.sh --workflow=.github/workflows/maven-build.yml --job=build --event=push --container=docker

# Get help for available options
./src/test/act/testing_workflows.sh --help
```

All parameters are optional and use sensible defaults:
```
Options:
  --workflow=FILE     Workflow file to test (default: .github/workflows/maven-build.yml)
  --job=NAME          Job name to test (default: build)
  --event=TYPE        Event type to trigger (default: push)
  --container=RUNTIME Container runtime to use (podman or docker, default: podman)
  -h, --help          Show this help message
```

You can still override the container runtime with an environment variable if preferred:
```bash
ACT_CONTAINER_RUNTIME=docker ./src/test/act/testing_workflows.sh
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

### Using Podman (Default)

```bash
# Set container runtime to podman
export ACT_CONTAINER_RUNTIME=podman

# Run dry-run
act -n push -W .github/workflows/maven-build.yml -j build --secret-file src/test/act/secrets.env

# Run the workflow
act push -W .github/workflows/maven-build.yml -j build --secret-file src/test/act/secrets.env
```

### Using Docker

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
# Test a workflow_dispatch event
act workflow_dispatch -W .github/workflows/maven-build.yml -j build --secret-file src/test/act/secrets.env

# Test a pull_request event
act pull_request -W .github/workflows/maven-build.yml -j build --secret-file src/test/act/secrets.env
```

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

### Container Runtime Connection Issues

#### Podman Issues

If using Podman, make sure the Podman machine is running:

```bash
# Check if Podman machine is running
podman machine list

# Start the Podman machine if it's not running
podman machine start
```

#### Docker Issues

If using Docker, make sure Docker is running and you have the correct socket path:

```bash
# Check if Docker is running
docker info

# Check Docker context
docker context inspect
```

For Rancher Desktop users, the socket path is usually: `unix:///Users/username/.rd/docker.sock`

### Missing Secrets

If your workflow fails due to missing secrets, ensure your `src/test/act/secrets.env` file includes all required secrets.

### Platform/Architecture Issues

Some actions might not work locally due to platform differences. In these cases, you can modify the `src/test/act/.actrc` file to include appropriate platform settings.

## Additional Tips

- Add `-v` flag for verbose output
- Use `--bind` flag to mount additional directories
- For complex workflows, consider testing one job at a time

## Debugging Workflows

To debug a failing workflow:

1. Run with verbose output: `act -v ...`
2. Check the logs for errors
3. Test jobs individually
4. Modify your workflow temporarily to add debug steps

## References

- [Act GitHub Repository](https://github.com/nektos/act)
- [Act Documentation](https://nektosact.com/)
