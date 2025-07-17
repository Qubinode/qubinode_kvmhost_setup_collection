# Enhanced Dependency Vulnerability Scanning

## Overview

The Enhanced Dependency Vulnerability Scanner provides comprehensive security scanning for all project dependencies as specified in [ADR-0009: GitHub Actions Dependabot Auto-Updates Strategy](../docs/adrs/adr-0009-github-actions-dependabot-auto-updates-strategy.md).

## Features

- **Multi-Platform Scanning**: Python packages, Ansible collections, Docker images, and GitHub Actions
- **Multiple Output Formats**: Table, JSON, and SARIF formats
- **Severity Filtering**: Low, medium, high, and critical severity levels
- **CI/CD Integration**: Automated scanning with failure thresholds
- **Comprehensive Reporting**: Detailed reports with remediation guidance

## Installation

The scanner automatically installs required tools when first run:

- `safety` - Python dependency vulnerability scanner
- `pip-audit` - Official PyPA auditing tool  
- `bandit` - Python security static analysis
- `semgrep` - Multi-language security scanner

## Usage

### Basic Scanning

```bash
# Scan all dependencies
./scripts/enhanced-dependency-scanner.sh

# Scan specific dependency types
./scripts/enhanced-dependency-scanner.sh --python
./scripts/enhanced-dependency-scanner.sh --ansible
./scripts/enhanced-dependency-scanner.sh --docker
./scripts/enhanced-dependency-scanner.sh --github-actions
```

### Output Formats

```bash
# Table format (default)
./scripts/enhanced-dependency-scanner.sh --format table

# JSON output for CI/CD
./scripts/enhanced-dependency-scanner.sh --format json

# SARIF format for security tools
./scripts/enhanced-dependency-scanner.sh --format sarif
```

### Severity Filtering

```bash
# Show only critical vulnerabilities
./scripts/enhanced-dependency-scanner.sh --severity critical

# Show high and critical vulnerabilities
./scripts/enhanced-dependency-scanner.sh --severity high

# Show all vulnerabilities
./scripts/enhanced-dependency-scanner.sh --severity low
```

### CI Mode

```bash
# CI mode with strict exit codes
./scripts/enhanced-dependency-scanner.sh --ci --severity critical

# Generate reports for CI artifacts
./scripts/enhanced-dependency-scanner.sh --ci --report-dir ./security-reports/
```

## Exit Codes

- `0` - No vulnerabilities found
- `1` - Script error or configuration issue
- `2` - Low severity vulnerabilities found
- `3` - Medium severity vulnerabilities found
- `4` - High severity vulnerabilities found
- `5` - Critical vulnerabilities found

## CI/CD Integration

The scanner is integrated into the GitHub Actions workflow at `.github/workflows/dependency-testing.yml`:

```yaml
- name: Run enhanced dependency vulnerability scan
  run: |
    chmod +x ./scripts/enhanced-dependency-scanner.sh
    ./scripts/enhanced-dependency-scanner.sh --format json --output-dir security-reports/
```

### Failure Thresholds

- **Critical vulnerabilities**: Build fails immediately
- **High vulnerabilities**: Warning if > 5 found
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
