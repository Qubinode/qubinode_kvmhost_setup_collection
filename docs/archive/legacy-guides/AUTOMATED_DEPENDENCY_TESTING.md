# Automated Dependency Testing Framework

**ADR Reference**: ADR-0009 - GitHub Actions Dependabot Strategy  
**Implementation Status**: ✅ Complete  
**Last Updated**: July 13, 2025

## Overview

This document describes the comprehensive automated dependency testing framework implemented to ensure reliable dependency management and update validation for the Qubinode KVM Host Setup Collection.

## Architecture

### Components

1. **GitHub Actions Workflow** (`.github/workflows/dependency-testing.yml`)
   - Automated CI/CD dependency testing
   - Multi-matrix testing (Python, Ansible, Container images)
   - Security vulnerability scanning
   - Scheduled weekly runs

2. **Local Testing Script** (`scripts/test-dependencies.sh`)
   - Developer-friendly local dependency testing
   - Supports isolated testing of specific dependency types
   - Generates detailed reports

3. **Dependency Update Validation** (`scripts/validate-dependency-updates.sh`)
   - Validates dependency updates before merging
   - Breaking change detection
   - Performance regression testing
   - Comprehensive validation reporting

4. **Dependabot Configuration** (`.github/dependabot.yml`)
   - Automated dependency update PRs
   - Multi-ecosystem support (GitHub Actions, Docker, Python, Ansible)
   - Staged update schedule

## Testing Matrix

### Python Dependencies
- **Python 3.11** (current production)
- **Python 3.12** (future compatibility)
- **Ansible Core 2.17** (current stable)
- **Ansible Core 2.18** (next version)
- **Molecule 25.6.0+** (container testing)

### Container Images
- **RHEL 9** (`registry.redhat.io/ubi9-init:9.6-1751962289`)
- **Rocky Linux 9** (`docker.io/rockylinux/rockylinux:9-ubi-init`)
- **AlmaLinux 9** (`docker.io/almalinux/9-init:9.6-20250712`)

### Security Scanning
- **Safety** - Python dependency vulnerability scanning
- **Bandit** - Static code analysis for Python security issues
- **Automated vulnerability reporting**

## Usage

### Local Development

#### Test All Dependencies
```bash
# Run comprehensive dependency testing
./scripts/test-dependencies.sh

# Test specific dependency type
./scripts/test-dependencies.sh python
./scripts/test-dependencies.sh ansible
./scripts/test-dependencies.sh docker
./scripts/test-dependencies.sh security
```

#### Clean Environment Testing
```bash
# Clean virtual environments and run fresh tests
./scripts/test-dependencies.sh --clean full

# Test with specific Python version
./scripts/test-dependencies.sh --python-version 3.12 python
```

#### Validate Dependency Updates
```bash
# Validate dependency updates in current branch
./scripts/validate-dependency-updates.sh

# Validate specific PR
./scripts/validate-dependency-updates.sh --pr-number 123

# Fast validation with early exit on failure
./scripts/validate-dependency-updates.sh --fail-fast --verbose
```

### CI/CD Integration

#### Automatic Triggers
- **Pull Requests** affecting dependency files
- **Weekly Schedule** (Fridays at 10:00 UTC)
- **Manual Dispatch** with configurable scope

#### Test Scopes
- **Full** - All dependency types and security scans
- **Python-only** - Python and Ansible dependencies
- **Ansible-only** - Ansible collections and role compatibility
- **Docker-only** - Container image availability and Molecule tests

### Dependabot Integration

#### Update Schedule
- **Monday**: GitHub Actions workflows
- **Tuesday**: Docker images (Molecule testing)
- **Wednesday**: Python dependencies
- **Thursday**: Ansible Galaxy dependencies

#### Automatic Validation
All Dependabot PRs trigger:
1. Dependency compatibility testing
2. Breaking change detection
3. Security vulnerability scanning
4. Performance regression testing

## Configuration

### Environment Variables

#### Local Testing
```bash
export PYTHON_VERSION="3.11"              # Python version to test
export ANSIBLE_CORE_VERSION="2.17"        # Ansible Core version
export MOLECULE_VERSION="25.6.0"          # Molecule version
export VENV_DIR="./venvs"                 # Virtual environment directory
```

#### CI/CD Variables
```bash
GITHUB_TOKEN                               # GitHub API access
PR_NUMBER                                  # Pull request number
BASE_BRANCH                                # Base branch for comparison
```

### Customization

#### Adding New Python Versions
Update the matrix in `.github/workflows/dependency-testing.yml`:
```yaml
PYTHON_MATRIX='{"include":[
  {"python-version":"3.11","name":"current"},
  {"python-version":"3.12","name":"next"},
  {"python-version":"3.13","name":"future"}
]}'
```

#### Adding New Container Images
Update the Docker matrix:
```yaml
DOCKER_MATRIX='{"include":[
  {"image":"registry.redhat.io/ubi10-init:latest","name":"rhel-10"},
  {"image":"existing-images...","name":"existing-names"}
]}'
```

#### Custom Security Checks
Extend the security scanning in `test-dependencies.sh`:
```bash
# Add custom security tools
pip install custom-security-tool
custom-security-tool scan . >> "$report_file"
```

## Reporting

### Report Types

#### Local Testing Reports
Generated in `dependency-reports/`:
- `python-dependencies-TIMESTAMP.txt` - Python dependency freeze
- `ansible-dependencies-TIMESTAMP.txt` - Ansible version and collections
- `container-dependencies-TIMESTAMP.txt` - Container image status
- `security-dependencies-TIMESTAMP.txt` - Security scan results

#### Validation Reports
Generated in `dependency-validation/reports/`:
- `validation-report-TIMESTAMP.json` - Machine-readable validation results
- `validation-summary-TIMESTAMP.txt` - Human-readable summary
- Individual test logs for detailed debugging

### Sample Validation Report
```json
{
  "validation_run": {
    "timestamp": "2025-07-13T10:00:00Z",
    "pr_number": "123",
    "base_branch": "main",
    "commit_sha": "abc123...",
    "status": "passed"
  },
  "tests": {
    "dependency_compatibility": {
      "status": "passed",
      "details": "All dependency compatibility tests passed",
      "timestamp": "2025-07-13T10:05:00Z"
    },
    "breaking_changes": {
      "status": "passed",
      "details": "No breaking changes detected",
      "timestamp": "2025-07-13T10:10:00Z"
    },
    "security_scans": {
      "status": "passed",
      "details": "No security vulnerabilities detected",
      "timestamp": "2025-07-13T10:15:00Z"
    }
  },
  "summary": {
    "total_tests": 4,
    "passed": 4,
    "failed": 0,
    "skipped": 0
  }
}
```

## Integration with Development Workflow

### Pre-commit Testing
Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Run dependency tests before commit
./scripts/test-dependencies.sh security
if [[ $? -ne 0 ]]; then
    echo "Dependency security tests failed. Commit aborted."
    exit 1
fi
```

### PR Validation
Automatic validation on all PRs:
1. Dependency change detection
2. Compatibility testing
3. Breaking change analysis
4. Security vulnerability scanning
5. Performance regression testing

### Release Validation
Before releases:
```bash
# Full dependency validation
./scripts/validate-dependency-updates.sh --base-branch stable-1.0

# Performance baseline testing
./scripts/test-dependencies.sh --clean full
```

## Troubleshooting

### Common Issues

#### Python Version Not Found
```bash
# Install required Python version (RHEL/Rocky/AlmaLinux)
sudo yum install -y python3.11 python3.11-devel python3.11-pip
```

#### Container Runtime Issues
```bash
# Ensure Podman/Docker is running
sudo systemctl start podman

# Check container runtime
podman --version
```

#### Virtual Environment Conflicts
```bash
# Clean virtual environments
rm -rf venvs/
./scripts/test-dependencies.sh --clean
```

#### Permission Issues
```bash
# Ensure scripts are executable
chmod +x scripts/test-dependencies.sh
chmod +x scripts/validate-dependency-updates.sh
```

### Debug Mode
Enable verbose output for detailed debugging:
```bash
./scripts/test-dependencies.sh --verbose
./scripts/validate-dependency-updates.sh --verbose
```

## Performance Optimization

### Testing Speed
- **Parallel Testing** - Multiple dependency types tested concurrently
- **Incremental Validation** - Only test changed dependencies
- **Cached Environments** - Reuse virtual environments when possible
- **Fast-fail Mode** - Exit early on critical failures

### Resource Usage
- **Isolated Environments** - Prevent dependency conflicts
- **Cleanup Automation** - Automatic cleanup of temporary files
- **Report Compression** - Efficient storage of test results

## Security Considerations

### Vulnerability Management
- **Automated Scanning** - Regular security vulnerability checks
- **Severity Filtering** - Focus on high and critical vulnerabilities
- **Update Prioritization** - Security updates get higher priority
- **Audit Trail** - Complete history of security scan results

### Access Control
- **Token Security** - GitHub tokens with minimal required permissions
- **Environment Isolation** - Separate test environments
- **Report Privacy** - Sensitive information filtered from reports

## Future Enhancements

### Planned Features
- [ ] **Dependency License Compliance** - Automatic license compatibility checking
- [ ] **Breaking Change Prediction** - ML-based breaking change detection
- [ ] **Performance Benchmarking** - Automated performance regression detection
- [ ] **Rollback Automation** - Automatic dependency rollback on failures

### Integration Opportunities
- [ ] **Slack/Teams Integration** - Notification system for dependency updates
- [ ] **JIRA Integration** - Automatic ticket creation for security vulnerabilities
- [ ] **Grafana Dashboards** - Visual dependency health monitoring
- [ ] **SonarQube Integration** - Code quality impact analysis

## Compliance and Governance

### ADR Alignment
This implementation fully satisfies ADR-0009 requirements:
- ✅ Automated dependency tracking across multiple ecosystems
- ✅ Breaking change detection and validation
- ✅ Security vulnerability scanning and reporting
- ✅ Performance regression testing
- ✅ Comprehensive validation pipeline

### Quality Gates
- **100% Test Coverage** - All dependency types tested
- **Zero-Tolerance Security** - Critical vulnerabilities block merges
- **Performance Baseline** - No regression beyond acceptable thresholds
- **Documentation Currency** - All changes documented and validated

## Support and Maintenance

### Team Responsibilities
- **DevOps Team** - CI/CD pipeline maintenance and optimization
- **Security Team** - Vulnerability management and security policy updates
- **Development Team** - Local testing compliance and issue resolution

### Maintenance Schedule
- **Weekly** - Review automated test results and dependency updates
- **Monthly** - Update testing matrices and security policies
- **Quarterly** - Comprehensive framework review and optimization

---

**Related Documentation**:
- [ADR-0009: GitHub Actions Dependabot Strategy](../adrs/adr-0009-github-actions-dependabot-strategy.md)
- [Local Molecule Testing Guide](./MANDATORY_LOCAL_TESTING.md)
- [Developer Workflow Guide](./development.md)

**Contact**: DevOps Team  
**Last Review**: July 13, 2025
