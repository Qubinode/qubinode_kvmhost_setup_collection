# Available Init Container Images for Molecule Testing

**Date**: July 13, 2025  
**Related ADR**: [ADR-0012: Use Init Containers for Molecule Testing](../docs/adrs/adr-0012-init-container-vs-regular-container-molecule-testing.md)

## 🐳 Locally Available Init Images

These are the systemd-enabled container images currently available locally and verified working with our Molecule testing framework:

### **Red Hat UBI Init Images** (Recommended)
| Image | Tag | Size | Status | Use Case |
|-------|-----|------|--------|----------|
| `registry.redhat.io/ubi9-init` | `9.6-1751962289` | 237 MB | ✅ Available | RHEL 9 compatible testing |
| `registry.redhat.io/ubi10-init` | `10.0-1751895590` | 236 MB | ✅ Available | RHEL 10 compatible testing |

### **Rocky Linux Init Images**
| Image | Tag | Size | Status | Use Case |
|-------|-----|------|--------|----------|
| `docker.io/rockylinux/rockylinux` | `8-ubi-init` | 228 MB | ✅ Available | RHEL 8 compatible testing |
| `docker.io/rockylinux/rockylinux` | `9-ubi-init` | 275 MB | ✅ Available | RHEL 9 compatible testing |

### **AlmaLinux Init Images**
| Image | Tag | Size | Status | Use Case |
|-------|-----|------|--------|----------|
| `docker.io/almalinux/9-init` | `9.6-20250712` | 186 MB | ✅ Available | RHEL 9 compatible testing |

## 📋 Molecule Configuration Matrix

Based on available images, here's the recommended configuration for each scenario:

### **Standard Testing (molecule/default)**
```yaml
platforms:
  - name: rhel9-test
    image: registry.redhat.io/ubi9-init:9.6-1751962289
    systemd: always
    command: "/usr/sbin/init"
    capabilities: [SYS_ADMIN]
    cgroupns_mode: host
    volumes: ["/sys/fs/cgroup:/sys/fs/cgroup:ro"]
    
  - name: rocky9-test
    image: docker.io/rockylinux/rockylinux:9-ubi-init
    systemd: always
    command: "/usr/sbin/init"
    capabilities: [SYS_ADMIN]
    cgroupns_mode: host
    volumes: ["/sys/fs/cgroup:/sys/fs/cgroup:ro"]
```

### **Idempotency Testing**
```yaml
platforms:
  - name: idempotency-rhel9
    image: registry.redhat.io/ubi9-init:9.6-1751962289
    systemd: always
    command: "/usr/sbin/init"
    capabilities: [SYS_ADMIN]
    cgroupns_mode: host
    
  - name: idempotency-rhel10
    image: registry.redhat.io/ubi10-init:10.0-1751895590
    systemd: always
    command: "/usr/sbin/init"
    capabilities: [SYS_ADMIN]
    cgroupns_mode: host
    
  - name: idempotency-rocky9
    image: docker.io/rockylinux/rockylinux:9-ubi-init
    systemd: always
    command: "/usr/sbin/init"
    capabilities: [SYS_ADMIN]
    cgroupns_mode: host
    
  - name: idempotency-alma9
    image: docker.io/almalinux/9-init:9.6-20250712
    systemd: always
    command: "/usr/sbin/init"
    capabilities: [SYS_ADMIN]
    cgroupns_mode: host
```

## 🔄 Maintenance and Updates

### **When to Update Images**
- **Security Updates**: Monthly check for newer image versions
- **Major Release**: When new RHEL/Rocky/Alma versions are released
- **Tag Updates**: When specific version tags become available

### **How to Update**
1. **Pull New Images**:
   ```bash
   podman pull registry.redhat.io/ubi9-init:latest
   podman pull docker.io/rockylinux/rockylinux:9-ubi-init
   podman pull docker.io/almalinux/9-init:latest
   ```

2. **Update This Documentation**:
   ```bash
   podman images --format "table {{.Repository}}:{{.Tag}} {{.Size}} {{.Created}}" | grep -E "(init|ubi.*init)"
   ```

3. **Update Molecule Configurations**:
   - Replace image tags in `molecule/*/molecule.yml` files
   - Test with `molecule test` before committing

### **Image Verification Commands**
```bash
# Verify systemd is available in image
podman run --rm <image> systemctl --version

# Check init system
podman run --rm <image> ps aux | head -2

# Verify systemd services can be managed
podman run --rm --systemd=always <image> systemctl list-units
```

## 🚫 Images to Avoid (Per ADR-0012)

These images should **NOT** be used as they require complex workarounds:

| Image | Reason to Avoid |
|-------|----------------|
| `quay.io/rockylinux/rockylinux:9` | Regular image, requires manual systemd setup |
| `registry.redhat.io/ubi9/ubi:latest` | Regular image, requires manual systemd setup |
| `quay.io/almalinux/almalinux:9` | Regular image, requires manual systemd setup |
| `registry.fedoraproject.org/fedora:latest` | Regular image, requires manual systemd setup |

## 📖 Related Documentation

- [ADR-0012: Use Init Containers for Molecule Testing](../docs/adrs/adr-0012-init-container-vs-regular-container-molecule-testing.md)
- [ADR-0013: Molecule Container Configuration Best Practices](../docs/adrs/adr-0013-molecule-systemd-configuration-best-practices.md)
- [Research Results: Init vs Regular Container Technical Evaluation](../docs/research/manual-research-results-july-12-2025.md)

---
**Last Updated**: July 13, 2025  
**Next Review**: August 13, 2025  
**Maintainer**: Infrastructure Testing Team
