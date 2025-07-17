# ADR-0013: Molecule Container Configuration Best Practices for systemd Testing

## Status
Accepted

## Context
Based on extensive research and testing experience with Molecule and systemd containers, we need to establish standardized configuration patterns to avoid common pitfalls and ensure consistent test environments.

### Research-Based Problems Identified

1. **tmpfs Configuration Issues**:
   - Molecule plugin expects `tmpfs` as dictionary, not list
   - Inconsistent documentation across guides
   - Breaking changes in recent Molecule versions

2. **systemd Mounting Requirements**:
   - `/sys/fs/cgroup` must be properly mounted
   - Privilege escalation needed for systemd
   - Init command variations across distributions

3. **Image Selection Complexity**:
   - Different init commands per distribution (`/usr/sbin/init` vs `/sbin/init`)
   - Varying default configurations across base images
   - Community vs official image reliability

## Decision
We will standardize our Molecule configuration patterns to ensure reliable systemd testing across all platforms.

### Standard Configuration Patterns

#### 1. Container Platform Configuration
```yaml
platforms:
  # RHEL/UBI Pattern
  - name: rhel-9
    image: registry.redhat.io/ubi9-init:9.6-1751962289
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    security_opts:
      - seccomp=unconfined
    groups:
      - rhel9_compatible

  # Alternative: Use systemd Parameter (Recommended)
  - name: fedora-latest  
    image: registry.fedoraproject.org/fedora:latest
    systemd: always  # Automatically handles tmpfs and cgroup mounting
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    groups:
      - fedora_latest
```

#### 2. Provisioner Configuration
```yaml
provisioner:
  name: ansible
  config_options:
    defaults:
      interpreter_python: auto_silent
      callback_whitelist: profile_tasks, timer, yaml
      host_key_checking: false
      depreciation_warnings: false
    ssh_connection:
      pipelining: true  # Enable for better performance
```

#### 3. Driver Configuration  
```yaml
driver:
  name: podman
  options:
    podman_binary: /usr/bin/podman
    podman_extra_args: --log-level=info
```

### Anti-Patterns to Avoid

#### 1. **Manual tmpfs Configuration** (Deprecated)
```yaml
# DON'T DO THIS - Causes "tmpfs wants dict, not list" errors
platforms:
  - name: instance
    tmpfs:
      - /run
      - /tmp
```

#### 2. **Missing systemd Requirements**
```yaml
# DON'T DO THIS - systemd won't work
platforms:
  - name: instance
    image: docker.io/centos:7
    # Missing: privileged, volumes, capabilities
```

#### 3. **Wrong Init Commands**
```yaml
# DON'T DO THIS - Wrong init command for image type
platforms:
  - name: instance
    image: registry.redhat.io/ubi9-init
    command: "/bin/bash"  # Should be /usr/sbin/init
```

## Implementation Guidelines

### 1. Image Selection Matrix
| Distribution | Recommended Image | Init Command | systemd Support |
|-------------|------------------|--------------|-----------------|
| RHEL 9 | `registry.redhat.io/ubi9-init` | `/usr/sbin/init` | ✅ Built-in |
| RHEL 10 | `registry.redhat.io/ubi10-init` | `/usr/sbin/init` | ✅ Built-in |
| Rocky 9 | `docker.io/rockylinux/rockylinux:9-ubi-init` | `/usr/sbin/init` | ✅ Built-in |
| CentOS Stream 9 | `quay.io/centos/centos:stream9` | `/sbin/init` | ⚠️ Manual setup |
| Fedora Latest | `registry.fedoraproject.org/fedora:latest` | `/usr/sbin/init` | ⚠️ Manual setup |

### 2. Testing Validation Script
```bash
#!/bin/bash
# Validate systemd container configuration
molecule create
molecule converge

# Test systemd functionality
molecule exec -- systemctl --version
molecule exec -- systemctl list-units --type=service
molecule exec -- ps aux | grep systemd
```

### 3. Troubleshooting Checklist
- ✅ Is systemd running as PID 1?
- ✅ Are cgroups properly mounted?
- ✅ Do containers have SYS_ADMIN capability?
- ✅ Is the correct init command specified?
- ✅ Are privileges properly escalated?

## Migration Path

### From Legacy tmpfs Configuration:
```yaml
# OLD (Broken)
platforms:
  - name: instance
    tmpfs:
      - /run
      - /tmp

# NEW (Working)  
platforms:
  - name: instance
    systemd: always  # Handles tmpfs automatically
```

### From Regular Containers:
```yaml
# OLD (Unreliable)
platforms:
  - name: instance
    image: docker.io/centos:7

# NEW (Reliable)
platforms:
  - name: instance  
    image: registry.redhat.io/ubi9-init
    systemd: always
```

## Consequences

### Positive:
- **Standardized Approach**: Consistent configuration across all scenarios
- **Future-Proof**: Works with latest Molecule versions
- **Reduced Support Burden**: Fewer configuration-related issues
- **Clear Migration Path**: Easy upgrade from legacy configurations

### Negative:  
- **Configuration Complexity**: More parameters to understand
- **Breaking Changes**: Existing configurations need updates
- **Learning Curve**: Team needs training on new patterns

### Risk Mitigation:
- Document all configuration patterns clearly
- Provide migration scripts for existing setups
- Test configurations across different environments
- Maintain backward compatibility where possible

## References
- [Ansible Forum Discussion on systemd Configuration](https://forum.ansible.com/t/podman-container-w-systemd-for-molecule-doesnt-run-init/3529)
- [GitHub Issue: Molecule tmpfs Configuration](https://github.com/ansible/molecule/issues/4140)
- [Podman Documentation: systemd Flag](https://docs.podman.io/en/latest/markdown/podman-run.1.html)
- [Red Hat UBI Documentation](https://catalog.redhat.com/software/containers/ubi8/ubi-init/5c359b97d70cc534b3a378c8)

## Decision Date
2025-01-12

## Decision Makers
- Ansible Collection Development Team
- Infrastructure Testing Team
- DevOps Engineering Team
