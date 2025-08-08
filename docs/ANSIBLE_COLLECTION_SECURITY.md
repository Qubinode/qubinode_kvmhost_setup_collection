# Ansible Collection Security Scanning

## Overview

The Ansible Collection Security Check provides focused security scanning for Ansible collections as specified in [ADR-0009: GitHub Actions Dependabot Auto-Updates Strategy](../docs/adrs/adr-0009-github-actions-dependabot-auto-updates-strategy.md).

This approach is specifically designed for Ansible collections and focuses on project requirements rather than scanning the entire system environment.

## Features

- **Focused Scanning**: Only scans project requirements.txt and requirements-dev.txt
- **Ansible Collection Optimized**: Excludes system packages and external roles
- **Dependency Vulnerability Detection**: Uses safety for Python package vulnerabilities
- **Static Code Analysis**: Uses bandit for security issues in our code only
- **CI/CD Integration**: Simple pass/fail with appropriate thresholds for collections
- **Fast Execution**: Lightweight approach with minimal false positives

## Installation

The scanner automatically installs required tools when first run:

- `safety` - Python dependency vulnerability scanner
- `bandit` - Python security static analysis

## Usage

### Basic Scanning

```bash
# Run focused security check for Ansible collections
./scripts/ansible-collection-security-check.sh
```

This script will:
1. Check requirements.txt for known vulnerabilities
2. Check requirements-dev.txt for known vulnerabilities
3. Run bandit static analysis on our code (excluding external roles)
4. Generate a summary report

### What Gets Scanned

The focused security check scans:
- **requirements.txt** - Production dependencies
- **requirements-dev.txt** - Development dependencies
- **Our code only** - roles/kvmhost_setup and plugins directories
- **Excludes** - System packages, external roles, linux-system-roles.*

### What Gets Excluded

To reduce false positives, the scanner excludes:
- System-installed packages (managed by OS)
- External roles (linux-system-roles.network, etc.)
- Test directories and molecule configurations
- Development tools that don't affect production security

## Exit Codes

- `0` - No critical vulnerabilities found (success)
- `1` - Critical vulnerabilities found (failure)

## CI/CD Integration

The security check is integrated into GitHub Actions workflows:

```yaml
- name: Run Ansible collection security check
  run: |
    ./scripts/ansible-collection-security-check.sh
```

### Failure Thresholds

- **Critical vulnerabilities**: Build fails immediately
- **High vulnerabilities**: Logged but do not fail build (appropriate for collections)
- **Medium/Low vulnerabilities**: Logged but do not fail build

## Configuration

### Environment Variables

- `VERBOSE=true` - Enable verbose output
- `SCAN_TIMEOUT=300` - Set scan timeout in seconds
- `CACHE_ENABLED=true` - Enable result caching

### Custom Patterns

Add custom security patterns by modifying the scanner configuration:

```bash
# Add custom pattern file
./scripts/enhanced-dependency-scanner.sh --patterns ./custom-security-patterns.yml
```

## Reports

Reports are generated in the `security-reports/` directory:

- `summary.json` - Overall vulnerability summary
- `python-scan.json` - Python dependency results
- `ansible-scan.json` - Ansible collection results
- `docker-scan.json` - Docker image results
- `github-actions-scan.json` - GitHub Actions results

## Developer Workflow

### Local Development

1. **Before committing**: Run quick scan for critical issues
   ```bash
   ./scripts/enhanced-dependency-scanner.sh --severity critical
   ```

2. **Weekly security review**: Run comprehensive scan
   ```bash
   ./scripts/enhanced-dependency-scanner.sh --format json --output-dir ./security-reports/
   ```

3. **Before releases**: Full security audit
   ```bash
   ./scripts/enhanced-dependency-scanner.sh --ci --severity medium
   ```

### Integration with Pre-commit Hooks

Add to `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: local
    hooks:
      - id: dependency-security-scan
        name: Enhanced Dependency Security Scan
        entry: ./scripts/enhanced-dependency-scanner.sh
        args: [--severity, critical, --ci]
        language: system
        pass_filenames: false
```

## Troubleshooting

### Common Issues

1. **Missing tools**: The scanner auto-installs required tools
2. **Permission errors**: Ensure script is executable (`chmod +x`)
3. **Network timeouts**: Increase timeout with `SCAN_TIMEOUT=600`
4. **False positives**: Use severity filtering to focus on critical issues

### Debug Mode

```bash
VERBOSE=true ./scripts/enhanced-dependency-scanner.sh --python
```

## Best Practices

1. **Regular Scanning**: Run weekly automated scans
2. **Severity Prioritization**: Address critical and high severity first
3. **Documentation**: Document accepted risks for medium/low findings
4. **Updates**: Keep scanner tools updated regularly
5. **Integration**: Include in CI/CD pipeline with appropriate thresholds

## Security Policy Compliance

This scanner implements the security requirements from:

- [ADR-0009: GitHub Actions Dependabot Auto-Updates Strategy](../docs/adrs/adr-0009-github-actions-dependabot-auto-updates-strategy.md)
- [Project Security Policy](../SECURITY.md)
- [Dependency Management Guidelines](../docs/DEPENDENCY_MANAGEMENT.md)

## Contributing

To contribute improvements to the scanner:

1. Test changes with multiple dependency types
2. Ensure backward compatibility with existing CI/CD
3. Update documentation for new features
4. Follow the project's security guidelines

For issues or feature requests, please see [CONTRIBUTING.md](../CONTRIBUTING.md).
