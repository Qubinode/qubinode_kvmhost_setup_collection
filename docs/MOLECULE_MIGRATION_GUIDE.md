# Molecule Configuration Migration Guide - ADR-0013

*Migration from Legacy tmpfs Configuration to systemd Best Practices*

## Overview

This guide helps migrate existing Molecule configurations from deprecated `tmpfs` syntax to ADR-0013 compliant systemd configuration patterns.

## Quick Migration Steps

### 1. Automated Migration Check

First, use our validation tool to identify configurations that need updates:

```bash
# Check all scenarios for compliance
./scripts/validate-molecule-systemd.sh

# The script will identify any deprecated tmpfs configurations
```

### 2. Configuration Transformations

#### Transform A: Remove Deprecated tmpfs Configuration

**❌ OLD (Broken in recent Molecule versions):**
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

**✅ NEW (ADR-0013 Compliant):**
```yaml
platforms:
  - name: instance
    image: registry.redhat.io/ubi9-init:9.6-1751962289
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    cgroupns_mode: host
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
```

#### Transform B: Update Image Selection

**❌ OLD (Non-init images):**
```yaml
platforms:
  - name: instance
    image: docker.io/centos:7        # No systemd support
    # OR
    image: docker.io/centos:stream9   # Requires manual setup
```

**✅ NEW (Init-enabled images):**
```yaml
platforms:
  - name: instance
    # For RHEL 9 compatibility:
    image: registry.redhat.io/ubi9-init:9.6-1751962289
    # OR for RHEL 10:
    image: registry.redhat.io/ubi10-init:10.0-1751895590
    # OR for Rocky Linux:
    image: docker.io/rockylinux/rockylinux:9-ubi-init
    # OR for AlmaLinux:
    image: docker.io/almalinux/almalinux:9-init
```

#### Transform C: Improve Provisioner Configuration

**❌ OLD (Basic configuration):**
```yaml
provisioner:
  name: ansible
  config_options:
    defaults:
      host_key_checking: false
```

**✅ NEW (Optimized configuration):**
```yaml
provisioner:
  name: ansible
  config_options:
    defaults:
      interpreter_python: auto_silent
      callback_whitelist: profile_tasks, timer, yaml
      host_key_checking: false
      deprecation_warnings: false
    ssh_connection:
      pipelining: true  # Better performance
```

## Migration Examples

### Example 1: Simple Legacy Config Migration

**Before (molecule/example/molecule.yml):**
```yaml
---
driver:
  name: podman

platforms:
  - name: test-instance
    image: docker.io/centos:7
    privileged: true
    tmpfs:
      - /run
      - /tmp
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN

provisioner:
  name: ansible
```

**After (ADR-0013 compliant):**
```yaml
---
driver:
  name: podman
  options:
    podman_binary: /usr/bin/podman
    podman_extra_args: --log-level=info

platforms:
  - name: test-instance
    image: registry.redhat.io/ubi9-init:9.6-1751962289
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    cgroupns_mode: host
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro

provisioner:
  name: ansible
  config_options:
    defaults:
      interpreter_python: auto_silent
      callback_whitelist: profile_tasks, timer, yaml
      host_key_checking: false
      deprecation_warnings: false
    ssh_connection:
      pipelining: true
```

### Example 2: Multi-Platform Legacy Config Migration

**Before:**
```yaml
platforms:
  - name: centos7
    image: docker.io/centos:7
    privileged: true
    tmpfs: ["/run", "/tmp"]
    command: "/usr/sbin/init"
    
  - name: centos8
    image: docker.io/centos:8
    privileged: true  
    tmpfs: ["/run", "/tmp"]
    command: "/usr/sbin/init"
```

**After:**
```yaml
platforms:
  - name: rhel9-rocky
    image: docker.io/rockylinux/rockylinux:9-ubi-init
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    groups:
      - rhel9_compatible
    
  - name: rhel9-alma
    image: docker.io/almalinux/almalinux:9-init
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    groups:
      - rhel9_compatible
      
  - name: rhel10-ubi
    image: registry.redhat.io/ubi10-init:10.0-1751895590
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    groups:
      - rhel10_compatible
```

## Step-by-Step Migration Process

### Step 1: Backup Current Configuration
```bash
# Create backup of current molecule configurations
cp -r molecule/ molecule-backup-$(date +%Y%m%d)
```

### Step 2: Update Each Scenario

For each `molecule/*/molecule.yml` file:

1. **Remove deprecated elements:**
   - `tmpfs:` lists
   - `privileged: true` (unless specifically needed)
   - `security_opts:` (unless specifically needed)

2. **Add required elements:**
   - `systemd: always`
   - `cgroupns_mode: host` (recommended)
   - Updated container images with `-init` suffix

3. **Update images to init-enabled versions:**
   ```bash
   # Use our image selection matrix from ADR-0013
   registry.redhat.io/ubi9-init:9.6-1751962289      # RHEL 9
   registry.redhat.io/ubi10-init:10.0-1751895590    # RHEL 10  
   docker.io/rockylinux/rockylinux:9-ubi-init       # Rocky 9
   docker.io/almalinux/almalinux:9-init             # Alma 9
   ```

### Step 3: Validate Migration
```bash
# Test configuration syntax
./scripts/validate-molecule-systemd.sh

# Test actual container creation
molecule create -s <scenario>
molecule converge -s <scenario>

# Test systemd functionality  
./scripts/validate-molecule-systemd.sh <scenario> runtime

# Cleanup
molecule destroy -s <scenario>
```

### Step 4: Update CI/CD (if applicable)

If using GitHub Actions or other CI/CD systems, ensure they support:
- Updated container images
- Podman with systemd support
- Proper container capabilities

## Troubleshooting Migration Issues

### Common Migration Problems

**Problem: "tmpfs wants dict, not list" Error**
```
# This error indicates incomplete migration
# Solution: Ensure ALL tmpfs configurations are removed
grep -r "tmpfs:" molecule/
```

**Problem: Container Exits Immediately After Update**
```bash
# Check if init command is correct for the image
molecule create -s <scenario>
podman logs <container_name>

# Verify image supports systemd
podman run -it --rm --systemd=always <image> /usr/sbin/init
```

**Problem: systemctl Commands Still Fail**
```bash
# Verify systemd is running as PID 1
molecule exec -s <scenario> -- ps -p 1 -o comm=

# Should return: systemd
```

### Validation Commands

**Pre-migration validation:**
```bash
# Identify all tmpfs usage
find molecule/ -name "molecule.yml" -exec grep -l "tmpfs" {} \;

# List all container images in use
grep -r "image:" molecule/ | grep -v "pre_build_image"
```

**Post-migration validation:**
```bash
# Verify no tmpfs configurations remain
! grep -r "tmpfs:" molecule/

# Verify all use systemd: always
grep -r "systemd: always" molecule/

# Run comprehensive validation
./scripts/validate-molecule-systemd.sh
```

## Best Practices for New Configurations

### 1. Always Use Init Images
```yaml
# ✅ Preferred: Official Red Hat UBI init images
image: registry.redhat.io/ubi9-init:9.6-1751962289

# ✅ Alternative: Community init images  
image: docker.io/rockylinux/rockylinux:9-ubi-init
```

### 2. Standard Platform Template
```yaml
platforms:
  - name: <scenario>-<distro>-<version>
    image: <init-enabled-image>
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    cgroupns_mode: host
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    groups:
      - <compatibility_group>
```

### 3. Optimized Provisioner
```yaml
provisioner:
  name: ansible
  config_options:
    defaults:
      interpreter_python: auto_silent
      callback_whitelist: profile_tasks, timer, yaml
      host_key_checking: false
      deprecation_warnings: false
    ssh_connection:
      pipelining: true
```

## Verification Checklist

After migration, verify:

- [ ] ✅ No `tmpfs:` configurations remain
- [ ] ✅ All platforms use `systemd: always`
- [ ] ✅ All images are init-enabled (contain `-init` suffix)
- [ ] ✅ Correct init commands are specified
- [ ] ✅ SYS_ADMIN capability is present
- [ ] ✅ cgroup mounting is configured
- [ ] ✅ Validation script passes: `./scripts/validate-molecule-systemd.sh`
- [ ] ✅ Runtime validation passes for all scenarios
- [ ] ✅ Molecule test sequence completes successfully

## Additional Resources

- **ADR-0013**: Complete best practices documentation  
- **Validation Tool**: `scripts/validate-molecule-systemd.sh`
- **Troubleshooting**: `docs/MOLECULE_SYSTEMD_TROUBLESHOOTING.md`
- **Image Registry**: `molecule/AVAILABLE_INIT_IMAGES.md`

---

*Migration Guide Version: 1.0*  
*Last Updated: 2025-07-14*  
*Compatible with: Molecule 3.x+, Podman 3.x+*
