# Molecule systemd Container Troubleshooting Checklist

*Based on ADR-0013: Molecule Container Configuration Best Practices*

## Quick Validation Checklist

Use this checklist when experiencing issues with systemd services in Molecule containers.

### ✅ Configuration Validation

**Run our validation script first:**
```bash
# Validate all scenario configurations
./scripts/validate-molecule-systemd.sh

# Validate specific scenario configuration  
./scripts/validate-molecule-systemd.sh default

# Validate runtime systemd functionality
molecule create -s default
./scripts/validate-molecule-systemd.sh default runtime
```

### ✅ Essential Configuration Items

**1. Container Platform Configuration**
- [ ] ✅ `systemd: always` is set (replaces deprecated tmpfs)
- [ ] ✅ Correct init command: `/usr/sbin/init` or `/sbin/init`
- [ ] ✅ `SYS_ADMIN` capability is included
- [ ] ✅ cgroup mounting: `/sys/fs/cgroup:/sys/fs/cgroup:ro`
- [ ] ✅ Using init-enabled container images (e.g., `ubi9-init`, `rockylinux:9-ubi-init`)

**2. Driver Configuration**
- [ ] ✅ Podman driver is used: `name: podman`
- [ ] ✅ Appropriate podman options are set

### ✅ Runtime Verification

**Manual validation commands:**
```bash
# Check if systemd is running as PID 1
molecule exec -- ps -p 1 -o comm=

# Verify systemd version
molecule exec -- systemctl --version

# Test systemd functionality
molecule exec -- systemctl list-units --type=service

# Check cgroup availability
molecule exec -- test -d /sys/fs/cgroup && echo "cgroups available"

# Verify systemd processes
molecule exec -- ps aux | grep systemd
```

### ❌ Common Problems & Solutions

**Problem 1: "tmpfs wants dict, not list" Error**
```yaml
# ❌ WRONG (Deprecated)
tmpfs:
  - /run
  - /tmp

# ✅ CORRECT (ADR-0013 compliant)
systemd: always
```

**Problem 2: systemd Not Running as PID 1**
```yaml
# ✅ Ensure proper init command
command: "/usr/sbin/init"  # For RHEL/UBI images
# OR
command: "/sbin/init"      # For some CentOS images
```

**Problem 3: "Operation not permitted" Errors**
```yaml
# ✅ Add required capabilities
capabilities:
  - SYS_ADMIN

# ✅ Ensure cgroup mounting
volumes:
  - /sys/fs/cgroup:/sys/fs/cgroup:ro
```

**Problem 4: systemctl Commands Failing**
```yaml
# ✅ Use systemd-enabled images
image: registry.redhat.io/ubi9-init:9.6-1751962289
# OR
image: docker.io/rockylinux/rockylinux:9-ubi-init

# ✅ Enable systemd mode
systemd: always
```

**Problem 5: Container Exits Immediately**
```bash
# Check container logs
podman logs <container_name>

# Verify init process
molecule exec -- ps aux | head -10

# Test manual container creation
podman run -it --rm --systemd=always <image> /usr/sbin/init
```

### ✅ Advanced Troubleshooting

**Debug Container Creation:**
```bash
# Create with verbose output
molecule create -s <scenario> -v

# Check Molecule logs
cat .molecule/<scenario>/podman/*.log

# Inspect running containers
podman ps -a
podman inspect <container_name>
```

**Test systemd Services:**
```bash
# Test service creation
molecule exec -- systemctl --user daemon-reload
molecule exec -- systemctl status

# Test service management
molecule exec -- systemctl start rsyslog || echo "Service start test"
molecule exec -- systemctl status rsyslog || echo "Service status test"
```

### ✅ Image-Specific Notes

| Image | Init Command | Notes |
|-------|-------------|-------|
| `registry.redhat.io/ubi9-init` | `/usr/sbin/init` | ✅ Recommended, fully configured |
| `registry.redhat.io/ubi10-init` | `/usr/sbin/init` | ✅ Latest, fully configured |
| `docker.io/rockylinux:9-ubi-init` | `/usr/sbin/init` | ✅ Good alternative |
| `docker.io/almalinux:9-init` | `/usr/sbin/init` | ✅ Good alternative |
| `quay.io/centos/centos:stream9` | `/sbin/init` | ⚠️  Requires manual systemd setup |

### ✅ Environment-Specific Issues

**SELinux Issues:**
```bash
# Check SELinux status
molecule exec -- getenforce

# If needed, set permissive mode for testing
molecule exec -- setenforce 0
```

**Network Issues:**
```bash
# Check network connectivity
molecule exec -- ping -c 1 8.8.8.8

# Test DNS resolution  
molecule exec -- nslookup google.com
```

**Storage Issues:**
```bash
# Check filesystem
molecule exec -- df -h

# Check mount points
molecule exec -- mount | grep cgroup
```

### ✅ Performance Optimization

**For faster testing:**
```yaml
# Use pre-built images when possible
pre_build_image: true

# Enable pipelining
provisioner:
  config_options:
    ssh_connection:
      pipelining: true

# Use cgroupns_mode for better performance
cgroupns_mode: host
```

### ✅ Validation Workflow

**Complete validation sequence:**
```bash
# 1. Validate configuration
./scripts/validate-molecule-systemd.sh

# 2. Test creation
molecule create

# 3. Validate runtime
./scripts/validate-molecule-systemd.sh default runtime

# 4. Test convergence
molecule converge

# 5. Test idempotency
molecule idempotence

# 6. Cleanup
molecule destroy
```

### 📞 Getting Help

**If issues persist:**

1. **Check ADR-0013** - Review the complete best practices document
2. **Run validation script** - Use `./scripts/validate-molecule-systemd.sh`
3. **Check Molecule docs** - [Molecule Documentation](https://molecule.readthedocs.io/)
4. **Review Podman systemd** - [Podman systemd documentation](https://docs.podman.io/en/latest/markdown/podman-run.1.html)
5. **Test minimal config** - Start with basic working configuration and add complexity

**Minimal working configuration template:**
```yaml
driver:
  name: podman

platforms:
  - name: test-instance
    image: registry.redhat.io/ubi9-init:9.6-1751962289
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN

provisioner:
  name: ansible
  config_options:
    defaults:
      host_key_checking: false
    ssh_connection:
      pipelining: true
```

---

*Last Updated: 2025-07-14*  
*Related: ADR-0013, ADR-0012*  
*Validation Tool: scripts/validate-molecule-systemd.sh*
