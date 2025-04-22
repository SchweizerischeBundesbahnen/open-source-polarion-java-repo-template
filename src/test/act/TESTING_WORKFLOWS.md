# Testing GitHub Actions Workflows Locally

This document provides guidance on how to test GitHub Actions workflows locally using the `act` tool.

## Requirements

- Docker (Rancher Desktop or Docker Desktop)
- Act CLI tool (`brew install act`)
- A local clone of the repository

## Quick Start

The simplest way to test a workflow is to use the provided `testing_workflows.sh` script:

```bash
# Navigate to the repository root
cd /path/to/repository

# For Rancher Desktop with Docker (Moby) engine
export DOCKER_HOST=unix://$HOME/.rd/docker.sock
# or forcing Act to use the Docker CLI directly
export ACT_CONTAINER_RUNTIME=docker

# Run the script with default settings (tests maven-build.yml, build job)
./src/test/act/testing_workflows.sh

# Or specify a specific workflow file, job, and event type
./src/test/act/testing_workflows.sh .github/workflows/custom-workflow.yml job-name workflow_dispatch
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

### Dry Run a Workflow Job

Dry run lets you see what would happen without actually executing the workflow:

```bash
act -n push -W .github/workflows/maven-build.yml -j build --container-daemon-socket $(docker context inspect rancher-desktop -f '{{.Endpoints.docker.Host}}') --secret-file src/test/act/secrets.env
```

### Run a Workflow Job for Real

```bash
act push -W .github/workflows/maven-build.yml -j build --container-daemon-socket $(docker context inspect rancher-desktop -f '{{.Endpoints.docker.Host}}') --secret-file src/test/act/secrets.env
```

### Testing Different Event Types

GitHub Actions workflows can be triggered by different events. To test a specific event type:

```bash
# Test a workflow_dispatch event
act workflow_dispatch -W .github/workflows/maven-build.yml -j build --container-daemon-socket $(docker context inspect rancher-desktop -f '{{.Endpoints.docker.Host}}') --secret-file src/test/act/secrets.env

# Test a pull_request event
act pull_request -W .github/workflows/maven-build.yml -j build --container-daemon-socket $(docker context inspect rancher-desktop -f '{{.Endpoints.docker.Host}}') --secret-file src/test/act/secrets.env
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

The `.actrc` file contains configuration for Act:

```
--container-architecture=linux/amd64
-P ubuntu-latest=catthehacker/ubuntu:act-latest
```

This specifies that Act should use Linux/AMD64 architecture for containers and a specific Docker image for the ubuntu-latest runner.

Both configuration files are automatically created by the `testing_workflows.sh` script if they don't exist.

## Common Issues and Solutions

### Docker Connection Issues

If using Rancher Desktop, make sure to specify the correct socket path:

```bash
--container-daemon-socket $(docker context inspect rancher-desktop -f '{{.Endpoints.docker.Host}}')
```

### Missing Secrets

If your workflow fails due to missing secrets, ensure your `src/test/act/secrets.env` file includes all required secrets.

### Platform/Architecture Issues

Some actions might not work locally due to platform differences. In these cases, you can modify the `.actrc` file to include appropriate platform settings.

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
