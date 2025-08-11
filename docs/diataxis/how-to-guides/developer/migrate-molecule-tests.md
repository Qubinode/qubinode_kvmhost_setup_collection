# How to Migrate Molecule Test Configurations

This guide helps you migrate existing Molecule configurations from deprecated patterns to current best practices following ADR-0013 systemd configuration standards.

## 🎯 Goal

Migrate Molecule test configurations to:
- Remove deprecated `tmpfs` configurations
- Implement proper systemd container support
- Use current container images and best practices
- Ensure compatibility with latest Molecule versions
- Follow ADR-0013 systemd configuration standards

## 📋 Prerequisites

- Existing Molecule test scenarios to migrate
- Understanding of Molecule configuration
- Access to container registries (Red Hat, Docker Hub)
- Molecule 6.0+ installed

## 🔍 Step 1: Identify Configurations to Migrate

### Run Migration Assessment
```bash
# Check all scenarios for compliance
./scripts/validate-molecule-systemd.sh

# Manual check for deprecated patterns
grep -r "tmpfs:" roles/*/molecule/*/molecule.yml
grep -r "privileged: true" roles/*/molecule/*/molecule.yml
grep -r "centos:" roles/*/molecule/*/molecule.yml
```

### Common Deprecated Patterns
Look for these patterns that need migration:
- `tmpfs:` configurations
- `privileged: true` without proper justification
- Old container images (CentOS 7, outdated UBI)
- Missing `systemd: always` configuration
- Incorrect volume mounts for systemd

## 🔧 Step 2: Update Container Images

### Image Migration Map
| Old Image | New Image | Notes |
|-----------|-----------|-------|
| `centos:7` | `registry.redhat.io/ubi9-init:latest` | CentOS 7 EOL |
| `centos:8` | `registry.redhat.io/ubi9-init:latest` | CentOS 8 EOL |
| `ubi8-init:8.6` | `registry.redhat.io/ubi9-init:latest` | Use latest UBI 9 |
| `rockylinux:8` | `docker.io/rockylinux/rockylinux:9-ubi-init` | Use init variant |

### Update Image References
```yaml
# Before
platforms:
  - name: instance
    image: docker.io/centos:7

# After  
platforms:
  - name: instance
    image: registry.redhat.io/ubi9-init:latest
```

## ⚙️ Step 3: Remove Deprecated tmpfs Configuration

### Transform tmpfs to Proper systemd

#### Before (Deprecated)
```yaml
platforms:
  - name: instance
    image: docker.io/centos:7
    privileged: true
    tmpfs:
      - /run
      - /tmp
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    security_opts:
      - seccomp=unconfined
```

#### After (ADR-0013 Compliant)
```yaml
platforms:
  - name: instance
    image: registry.redhat.io/ubi9-init:latest
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    pre_build_image: false
    dockerfile: ../default/Dockerfile.rhel
```

## 🐳 Step 4: Create Proper Dockerfiles

### Create Standardized Dockerfile
Create `molecule/default/Dockerfile.rhel`:

```dockerfile
ARG BASE_IMAGE=registry.redhat.io/ubi9-init:latest
FROM ${BASE_IMAGE}

# Install systemd and basic tools
RUN dnf -y update && \
    dnf -y install \
        systemd \
        sudo \
        python3 \
        python3-pip \
        which \
        hostname \
        iproute \
        && \
    dnf clean all

# Configure systemd
RUN systemctl mask \
    dev-hugepages.mount \
    sys-fs-fuse-connections.mount \
    systemd-logind.service \
    getty.target \
    console-getty.service

# Create test user
RUN useradd -m -s /bin/bash testuser && \
    echo 'testuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/testuser

VOLUME ["/sys/fs/cgroup"]
CMD ["/usr/sbin/init"]
```

## 🔄 Step 5: Update Molecule Configuration

### Complete Modern Configuration
```yaml
dependency:
  name: galaxy
  options:
    requirements-file: requirements.yml

driver:
  name: podman

platforms:
  - name: rhel9-instance
    image: registry.redhat.io/ubi9-init:latest
    dockerfile: ../default/Dockerfile.rhel
    pre_build_image: false
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    environment:
      ANSIBLE_USER: testuser
      ANSIBLE_BECOME_METHOD: sudo

provisioner:
  name: ansible
  env:
    ANSIBLE_FORCE_COLOR: "true"
    ANSIBLE_VERBOSITY: "2"
  config_options:
    defaults:
      callback_whitelist: profile_tasks, timer
      stdout_callback: yaml
  inventory:
    host_vars:
      rhel9-instance:
        ansible_user: testuser
        ansible_become: true
        ansible_become_method: sudo

verifier:
  name: testinfra
  options:
    verbose: true
```

## 🧪 Step 6: Update Test Scripts

### Modernize Test Infrastructure
```python
# In molecule/default/tests/test_default.py
import pytest

def test_systemd_is_running(host):
    """Test that systemd is properly running in container."""
    systemd = host.service("systemd")
    assert systemd.is_running

def test_sudo_access(host):
    """Test that test user has sudo access."""
    cmd = host.run("sudo whoami")
    assert cmd.rc == 0
    assert cmd.stdout.strip() == "root"

def test_python_available(host):
    """Test that Python is available for Ansible."""
    cmd = host.run("python3 --version")
    assert cmd.rc == 0
    assert "Python 3" in cmd.stdout
```

## ✅ Step 7: Validate Migration

### Test Migrated Configuration
```bash
# Test the migrated scenario
cd roles/your_role
molecule test --scenario-name default

# Verify systemd functionality
molecule create
molecule login
# Inside container:
systemctl status
systemctl list-units --type=service
```

### Run Compliance Check
```bash
# Verify ADR-0013 compliance
./scripts/validate-molecule-systemd.sh

# Should show all green checkmarks
```

## 🔧 Advanced Migration Scenarios

### Multi-Platform Testing
```yaml
platforms:
  - name: rhel8-instance
    image: registry.redhat.io/ubi8-init:latest
    dockerfile: ../default/Dockerfile.rhel8
    # ... systemd configuration
    
  - name: rhel9-instance  
    image: registry.redhat.io/ubi9-init:latest
    dockerfile: ../default/Dockerfile.rhel9
    # ... systemd configuration
    
  - name: rocky9-instance
    image: docker.io/rockylinux/rockylinux:9-ubi-init
    dockerfile: ../default/Dockerfile.rocky
    # ... systemd configuration
```

### Performance Testing Configuration
```yaml
platforms:
  - name: performance-test
    image: registry.redhat.io/ubi9-init:latest
    systemd: always
    capabilities:
      - SYS_ADMIN
      - NET_ADMIN
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    environment:
      PERFORMANCE_TEST: "true"
    memory: "4g"
    cpus: "2"
```

## 📋 Migration Checklist

### Pre-Migration
- [ ] Backup existing configurations
- [ ] Document current test scenarios
- [ ] Identify deprecated patterns
- [ ] Plan migration timeline

### During Migration
- [ ] Update container images
- [ ] Remove tmpfs configurations
- [ ] Add systemd configuration
- [ ] Create proper Dockerfiles
- [ ] Update test scripts

### Post-Migration
- [ ] Test all scenarios
- [ ] Verify systemd functionality
- [ ] Run compliance validation
- [ ] Update documentation
- [ ] Clean up old files

## 🚨 Common Migration Issues

### Issue: Container Won't Start
**Symptoms**: Molecule create fails with systemd errors
**Solution**:
```yaml
# Ensure proper systemd configuration
systemd: always
command: "/usr/sbin/init"
capabilities:
  - SYS_ADMIN
volumes:
  - /sys/fs/cgroup:/sys/fs/cgroup:ro
```

### Issue: Services Won't Start in Container
**Symptoms**: systemctl commands fail
**Solution**:
```dockerfile
# In Dockerfile, mask problematic services
RUN systemctl mask \
    dev-hugepages.mount \
    sys-fs-fuse-connections.mount \
    systemd-logind.service
```

### Issue: Permission Denied Errors
**Symptoms**: Ansible tasks fail with permission errors
**Solution**:
```yaml
# Ensure proper user configuration
inventory:
  host_vars:
    instance:
      ansible_user: testuser
      ansible_become: true
      ansible_become_method: sudo
```

## 🔗 Related Documentation

- **Testing Setup**: [Set Up Local Testing](setup-local-testing.md)
- **Molecule Tests**: [Run Molecule Tests](run-molecule-tests.md)
- **ADR Reference**: [ADR-0013 Systemd Configuration](../../explanations/architecture-decisions/adr-0013-molecule-systemd-configuration.md)
- **Container Testing**: [Container Testing Guide](container-testing.md)

---

*This guide covered Molecule configuration migration. For setting up new test scenarios, see the testing setup guides.*
