# Testing Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Molecule Testing](#molecule-testing)
3. [Integration Testing](#integration-testing)
4. [CI/CD Pipeline Testing](#cicd-pipeline-testing)
5. [Container-based Testing](#container-based-testing)
6. [Security-Enhanced Testing](#security-enhanced-testing)
7. [Local Testing Validation](#local-testing-validation)
8. [Performance Testing](#performance-testing)
9. [Continuous Integration](#continuous-integration)
10. [Migration Guide](#migration-guide)
11. [References & Documentation](#references--documentation)

## Prerequisites

Before running tests, ensure you have:

1. **Python 3.11+** (recommended for RHEL 9+ compatibility)
2. **Ansible-core 2.17+** (recommended with Python 3.11)
3. **Molecule and Podman plugin**:
   ```bash
   pip install molecule molecule-podman
   ```
4. **Podman installed and running** (preferred over Docker for RHEL 9 integration)
5. **Rootless Podman configured** (recommended for security):
   ```bash
   podman system migrate
   podman info --debug
   ```

## Molecule Testing

### Available Test Scenarios
The project includes multiple Molecule scenarios for comprehensive testing:

1. **default** - Primary test scenario with RHEL 9/10 compatible containers
2. **idempotency** - Validates that roles can be run multiple times safely
3. **modular** - Tests modular role execution and dependencies
4. **rhel8** - RHEL 8 compatibility testing
5. **validation** - Schema and configuration validation testing

### Running Tests

**Single Scenario**:
```bash
# Run default scenario
molecule test

# Run specific scenario
molecule test -s idempotency
```

**All Scenarios**:
```bash
# Test all scenarios sequentially
for scenario in default idempotency modular rhel8 validation; do
  echo "Testing scenario: $scenario"
  molecule test -s $scenario
done
```

### Test Scenarios Detail

#### 1. **Default Scenario** - Primary Testing
- **Platforms**: Rocky Linux 9, AlmaLinux 9, RHEL 9, RHEL 10
- **Focus**: Complete role functionality
- **Container Type**: systemd-enabled init containers (per ADR-0012)

#### 2. **Idempotency Testing** 
- **Purpose**: Validates ADR-0004 (Idempotent Task Design Pattern)
- **Verification**: Runs roles twice, ensures no changes on second run

#### 3. **Modular Testing**
- **Purpose**: Tests role-based modular architecture (ADR-0002)
- **Focus**: Role dependencies and interaction patterns

### Viewing Results
Test results are displayed in the terminal. Detailed logs available in:
- `molecule/<scenario>/logs/`
- `molecule/<scenario>/reports/`

## Local Testing
```bash
# Quick syntax validation
ansible-playbook -i inventories/test/hosts test.yml --syntax-check

# Dry run (check mode)
ansible-playbook -i inventories/test/hosts test.yml --check

# Full execution
ansible-playbook -i inventories/test/hosts test.yml
```

## Integration Testing

### Running Integration Tests
```bash
ansible-playbook tests/integration.yml -i inventories/test/hosts
```

### Test Coverage
- Role dependencies and execution order
- Variable validation and inheritance
- System configuration verification
- Service status and functionality validation
- Network connectivity and bridge configuration
- Storage pool creation and management

## CI/CD Pipeline Testing

### Triggering Tests
1. Push to main branch
2. Create pull request
3. Manual workflow dispatch

### Test Matrix (Updated per ADR-0008)
- **Python versions**: 3.9, 3.10, 3.11 (recommended for RHEL 9+)
- **Ansible versions**: 2.13, 2.14, 2.15, 2.17 (recommended for Python 3.11)
- **Container Runtime**: Podman (preferred for RHEL 9 integration)
- **Platforms**: RHEL 8, RHEL 9, RHEL 10, Rocky Linux, AlmaLinux

## Container-based Testing

### Building Test Container
```bash
podman build -t kvmhost-test -f Dockerfile .
```

### Running Tests in Container (Legacy - Privileged)
⚠️ **Security Warning**: This approach uses privileged containers and should be migrated.

```bash
podman run --privileged \
  -v ${PWD}:/ansible \
  kvmhost-test \
  ansible-playbook tests/integration.yml
```

### Debugging in Container (Legacy)
```bash
podman run -it --privileged \
  -v ${PWD}:/ansible \
  kvmhost-test \
  /bin/bash
```

## Security-Enhanced Testing

### Recommended Approach (per ADR-0012)

**Security-Enhanced Container Execution**:
```bash
# Enhanced security approach with rootless Podman
podman run --systemd=true \
  --cap-add SYS_ADMIN \
  --user-ns=auto \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v ${PWD}:/ansible \
  kvmhost-test \
  ansible-playbook tests/integration.yml
```

**Security Benefits**:
- **Rootless Podman**: Enhanced host security through user namespaces
- **Specific Capabilities**: Only SYS_ADMIN instead of full privileged access
- **User Namespace Isolation**: Container root mapped to unprivileged host user
- **Reduced Attack Surface**: Minimized privilege escalation risks

### Container Security Configuration

**Molecule Security Configuration** (molecule.yml):
```yaml
platforms:
  - name: rhel-9-secure
    image: registry.redhat.io/ubi9-init:latest
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    # Avoid privileged: true - use rootless Podman instead
    cgroupns_mode: host
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
```

## Local Testing Validation

### Pre-commit Testing (per ADR-0011)

**Recommended local testing script**:
```bash
#!/bin/bash
# scripts/test-local-molecule.sh

set -e

echo "🧪 Running local Molecule validation..."

# Environment check
echo "📋 Checking environment..."
python3 --version
ansible --version
molecule --version
podman --version

# Syntax validation
echo "🔍 Syntax validation..."
ansible-playbook --syntax-check test.yml

# Molecule testing
echo "🚀 Running Molecule tests..."
molecule test -s default

# Security validation
echo "🔒 Security validation..."
molecule test -s validation

echo "✅ Local validation complete!"
```

**Usage**:
```bash
chmod +x scripts/test-local-molecule.sh
./scripts/test-local-molecule.sh
```

## Performance Testing

### Resource Usage Monitoring

Monitor system resource consumption during role execution:

```bash
# Monitor CPU and memory usage during testing
top -p $(pgrep -f molecule)

# Monitor disk usage for storage operations
iostat -x 1 10

# Monitor network during package installations
netstat -i
```

### Timing Benchmarks

Standard execution times for reference:

| Role Component | Expected Duration | Test Environment |
|---|---|---|
| Base packages | 2-5 minutes | Standard VM, good network |
| KVM/libvirt setup | 3-7 minutes | Depending on system resources |
| Storage configuration | 1-3 minutes | Varies by disk type |
| User configuration | <1 minute | Minimal overhead |
| Network setup | 1-2 minutes | Standard configuration |

### Load Testing

For production deployment validation:

```bash
# Test multiple concurrent installations
for i in {1..3}; do
  podman run -d --name test-load-$i \
    -e ANSIBLE_ROLES_PATH=/opt/ansible/roles \
    -v $(pwd):/opt/ansible \
    registry.redhat.io/ubi9-init:latest \
    sleep 3600
done

# Run parallel executions
parallel -j 3 "molecule test --scenario-name default -- --host test-load-{}" ::: 1 2 3
```

### Memory and Storage Requirements

**Minimum Testing Environment:**
- RAM: 4GB (8GB recommended for concurrent testing)
- Storage: 20GB free space
- CPU: 2 cores (4 cores recommended)

**Container Resource Limits:**
```yaml
# molecule.yml resource constraints for testing
platforms:
  - name: instance
    memory: 2048m
    cpus: 2
```

## Continuous Integration

### GitHub Actions Integration

The collection includes automated testing workflows:

```yaml
# .github/workflows/molecule.yml example structure
name: Molecule CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        distro: [ubi9, ubi10, rocky9]
        scenario: [default, idempotency]
```

### Pre-commit Hooks

Set up development environment with pre-commit validation:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run all hooks manually
pre-commit run --all-files
```

### Quality Gates

Automated quality checks before merge:

1. **Syntax Validation**: All YAML/Ansible syntax checked
2. **Linting**: ansible-lint validation
3. **Security Scanning**: Basic security policy compliance
4. **Idempotency**: All changes must be idempotent
5. **Documentation**: Role documentation must be current

## Migration Guide

### From Previous Versions

**Version 1.x to 2.x Migration:**

1. **Container Runtime Change**: Docker → Podman (ADR-0012)
   ```bash
   # Remove Docker dependency
   pip uninstall molecule-docker
   
   # Install Podman support
   pip install molecule-podman
   ```

2. **Python Version Upgrade**: 3.9+ → 3.11+ (recommended)
   ```bash
   # Update virtual environment
   python3.11 -m venv venv
   source venv/bin/activate
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

3. **Ansible Core Upgrade**: 2.15+ → 2.17+
   ```bash
   pip install 'ansible-core>=2.17'
   ```

### Breaking Changes

- **Container Security**: Privileged containers → Capability-specific (security enhancement)
- **Image Requirements**: Standard containers → systemd-enabled init containers
- **Python Support**: Python 3.8 deprecated, 3.11+ recommended
- **RHEL Support**: Added RHEL 10, deprecated CentOS 8

## References & Documentation

### Architectural Decision Records (ADRs)

- **ADR-0008**: RHEL 9/10 Support Strategy
- **ADR-0011**: Mandatory Local Testing Requirements  
- **ADR-0012**: Container Security Migration (Podman + Rootless)
- **ADR-0013**: Testing Framework Evolution

### External Documentation

- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Podman Testing Guide](https://podman.io/getting-started/)
- [Ansible Collection Development](https://docs.ansible.com/ansible/latest/dev_guide/developing_collections.html)
- [RHEL Container Development](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/building_running_and_managing_containers/)

### Support & Community

- **Issue Tracking**: Use GitHub Issues for bug reports and feature requests
- **Discussions**: GitHub Discussions for community support and questions
- **Contributing**: See CONTRIBUTING.md for development guidelines
- **Security**: See SECURITY.md for security policy and reporting

---

*Last Updated: $(date '+%Y-%m-%d') - Security Enhanced Testing Implementation*
*Version: 2.1.0 with ADR-0012/0013 compliance*
