# CLAUDE.md

## Landmines & Non-Obvious Requirements

### Maven Settings
Builds require `.mvn/settings.xml` (JFrog, GitHub Packages, Sonatype credentials via env vars). CI passes it with `-s .mvn/settings.xml`. `.mvn/maven.config` auto-activates the Polarion version profile.

### Polarion Dependencies
You must extract dependencies from the Polarion installer using [polarion-artifacts-deployer](https://github.com/SchweizerischeBundesbahnen/polarion-artifacts-deployer) before the Maven build will work.

### Local Polarion Installation
Requires `POLARION_HOME` environment variable. Use the `install-to-local-polarion` Maven profile:
```bash
mvn clean install -P install-to-local-polarion
```

### Remote Debugging
Add to Polarion's `config.sh`:
```bash
JAVA_OPTS="$JAVA_OPTS -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
```

### Logging
Polarion logs: `<POLARION_HOME>/polarion/logs/main/*.log`

## Branch & Commit Conventions

- Conventional commits enforced by commitizen (pre-commit hook)
- Feature branches: `feature/<name>`
- Bug fixes: `fix/<name>`
- LTS branches: `release-v*` (e.g., `release-v6`)
