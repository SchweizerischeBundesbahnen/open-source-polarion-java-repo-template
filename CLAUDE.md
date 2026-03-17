# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Polarion ALM extension template repository for SBB (Swiss Federal Railways). It provides a standardized structure for creating Java-based Polarion extensions with proper CI/CD pipelines, documentation, and build configurations.

## Development Commands

### Building the Project
```bash
# Basic build
mvn clean package

# Build with tests
mvn clean verify

# Install to local Polarion (requires POLARION_HOME environment variable)
mvn clean install -P install-to-local-polarion
```

### Testing
```bash
# Run all tests
mvn test

# Generate test coverage reports (available in target/site/jacoco)
mvn verify
```

### Code Quality
- The project uses GitHub Actions for CI/CD with SonarCloud integration
- Static analysis tools recommended: Checkstyle, SpotBugs, PMD
- Follow Google Java Style Guide and Oracle Java Code Conventions

## Project Architecture

### Maven Structure
- **Parent POM**: `ch.sbb.polarion.extension.generic:10.1.0` - Provides common configuration for all SBB Polarion extensions
- **Artifact ID**: `ch.sbb.polarion.extension.extension-name` (template placeholder)
- **Java Version**: 17 (Temurin distribution)

### Key Directories
- `src/main/java/ch/sbb/polarion/extension/extension_name/` - Main Java source code
- `src/main/resources/META-INF/` - Extension manifest and configuration
- `src/main/resources/webapp/` - Web application resources and admin interfaces
- `docs/` - OpenAPI documentation (generated via swagger-maven-plugin)

### Extension Architecture
- **REST Controllers**: Located in `rest/controller/` package
- **Web Context**: Configured via `maven-jar-plugin.Extension-Context` property
- **OpenAPI Integration**: Automatically generates API documentation from REST controllers
- **Polarion Integration**: Uses generic extension framework from parent POM

### Dependencies and Build Plugins
- **Core Dependency**: `ch.sbb.polarion.extension.generic.app` - Provides base functionality
- **Key Plugins**: 
  - `swagger-maven-plugin` - Generates OpenAPI documentation
  - `jacoco-maven-plugin` - Code coverage reporting
  - `markdown2html-maven-plugin` - Documentation generation

## Environment Setup

### Prerequisites
- Java JDK 17
- Maven 3.9+
- Active Polarion license (required for all contributors)
- `POLARION_HOME` environment variable set for local installation

### Polarion Dependencies
Extract dependencies from Polarion installer using [polarion-artifacts-deployer](https://github.com/SchweizerischeBundesbahnen/polarion-artifacts-deployer) before building.

## CI/CD Pipeline

### GitHub Actions Workflows
- **maven-build.yml**: Main build and deploy pipeline
  - Builds on Java 17 (Temurin)
  - Uses SBB JFrog repository for dependencies
  - Deploys to Maven Central for releases
  - Deploys to GitHub Packages for main branch
- **Settings**: Uses `.mvn/settings.xml` with environment variables for Java version and distribution

### Branch Strategy
- `main` branch is protected and production-ready
- Feature branches: `feature/<feature-name>`
- Bug fixes: `fix/<bug-name>`

## Extension Development Patterns

### Creating REST Controllers
- Place in `ch.sbb.polarion.extension.extension_name.rest.controller` package
- Configure OpenAPI documentation via `swagger-maven-plugin` resourcePackages
- Follow existing pattern in `OpenAPIInfo.java`

### Configuration Management
- Extension context configured via Maven properties
- Web application name derived from extension context
- Automatic module name follows Java 9+ module conventions

## Debugging

### Remote Debugging Setup
Add to Polarion's `config.sh`:
```bash
JAVA_OPTS="$JAVA_OPTS -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
```

### Logging
- Use Polarion logging system
- Logs available in `<polarion_home>/polarion/logs/main.log`
