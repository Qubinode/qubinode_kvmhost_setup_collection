# ADR-0012: Use Init Containers for Molecule Testing with systemd Services

## Status
Implemented

> **Review Note (2026-01-25)**: ADR compliance review confirmed full implementation with
> 9/10 compliance score. Init containers with systemd-enabled base images are standard
> across all Molecule testing with custom RHEL Dockerfiles for package manager compatibility.

## Context
During our work with Molecule testing framework for Ansible roles, we discovered a critical issue where containers without systemd init support fail when testing roles that manage systemd services. Our research revealed fundamental differences between init containers and regular containers that impact testing reliability.

**Note**: In the context of this ADR, "init containers" refers to systemd-enabled base images (e.g., `registry.redhat.io/ubi9-init`) designed to run systemd as PID 1, not Kubernetes initContainer objects.

### Research Findings

1. **systemd Requirement**: Many Ansible roles manage systemd services, requiring systemd to be running as PID 1 in containers
2. **Container Image Types**:
   - **Systemd-enabled base images** (e.g., `registry.redhat.io/ubi9-init`, `registry.redhat.io/ubi10-init`) - Specifically designed to run systemd as PID 1
   - **Regular containers** (e.g., `registry.fedoraproject.org/fedora:latest`) - Typically use bash/shell as default command, requiring complex workarounds

3. **Performance and Reliability Evidence**: 
   - **Systemd-enabled images**: 90-98% success rate, 1.5-3 min test duration, fewer failure modes
   - **Regular containers with workarounds**: 70-85% success rate, 2-5 min test duration, prone to D-Bus and cgroup issues
   - **Primary bottleneck**: Molecule orchestration, not systemd or containerization overhead

4. **Security Analysis**: 
   - **Privileged containers**: High security risk with host compromise potential
   - **Rootless Podman + User namespaces**: Optimal balance of functionality and security
   - **Fine-grained capabilities**: SYS_ADMIN with user namespaces preferred over privileged mode

5. **Red Hat Ecosystem Integration**: 
   - **Podman's native systemd support**: `--systemd=true` flag automatically handles tmpfs and cgroup mounting
   - **UBI-init images**: Purpose-built for systemd as PID 1, officially supported by Red Hat
   - **Reduced complexity**: Eliminates need for manual systemd workarounds

### Package Manager Compatibility Issue (2025-07-19)

During CI/CD pipeline testing, we discovered a critical issue where Molecule's auto-generated Dockerfiles were using Debian/Ubuntu package management commands (`apt-get`) on RHEL-based container images. This caused container build failures with errors like:

```
RUN if [ $(command -v apt-get) ]; then export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y python3 sudo bash ca-certificates iproute2 python3-apt aptitude && apt-get clean && rm -rf /var/lib/apt/lists/*;
```

**Root Cause**: Molecule's default Dockerfile template assumes Debian-based systems and generates package installation commands using `apt-get`, which fails on RHEL/CentOS/Rocky Linux/AlmaLinux systems that use `dnf`/`yum`.

**Impact**: All RHEL-based container platforms failed during the container build phase, preventing any Molecule tests from running.

**Resolution**: Implemented custom `Dockerfile.rhel` templates for all RHEL-based platforms with proper package manager detection and configuration.

## Decision
We will standardize on using systemd-enabled base images (init containers) for all Molecule testing scenarios in this collection.

### Specific Implementation:
1. **Use Official Systemd-Enabled Images**:
   - RHEL 9: `registry.redhat.io/ubi9-init:latest` 
   - RHEL 10: `registry.redhat.io/ubi10-init:latest`
   - CentOS Stream 9: `quay.io/centos/centos:stream9` (with manual systemd setup)
   - Rocky Linux 9: `docker.io/rockylinux/rockylinux:9-ubi-init`

2. **Avoid Non-Init Images**: 
   - Regular Fedora, AlmaLinux, or CentOS images without init support
   - Community images without proven systemd support

3. **Container Configuration**:
   - Use `command: "/usr/sbin/init"` or equivalent
   - Mount `/sys/fs/cgroup:/sys/fs/cgroup:ro`
   - **Avoid `privileged: true`** - Use rootless Podman with user namespaces instead
   - Use `capabilities: [SYS_ADMIN]` with user namespace virtualization
   - Leverage `systemd: always` parameter for automatic configuration

4. **Security Best Practices**:
   - **Prioritize rootless Podman** for enhanced security
   - **Implement user namespaces** to virtualize SYS_ADMIN capabilities
   - **Apply custom Seccomp profiles** tailored to systemd requirements
   - **Avoid privileged mode** except when absolutely necessary

## Consequences

### Positive:
- **Reliable Testing**: systemd services work consistently across test runs (90-98% success rate)
- **Real-world Accuracy**: Tests more closely mirror production environments
- **Reduced Debugging**: Fewer mysterious test failures related to systemd
- **Official Support**: Using Red Hat's official init containers provides better support
- **Performance Efficiency**: 1.5-3 minute test cycles vs 2-5 minutes for workarounds
- **Enhanced Security**: Reduced attack surface with rootless Podman and user namespaces
- **Podman Integration**: Native systemd support simplifies configuration

### Negative:
- **Larger Images**: Init containers are larger than minimal containers (UBI-init ~1.7GB)
- **Resource Usage**: Higher memory and CPU usage for tests (100-300MB vs <50MB)
- **Download Time**: Initial pull of init containers takes longer

### Mitigation:
- Use container image caching in CI/CD pipelines
- Run tests in parallel to amortize download costs
- Use local testing with pre-pulled images for development
- Implement resource limits to prevent host resource exhaustion

## Implementation Notes

### Recommended Configuration (Secure):
```yaml
platforms:
  - name: rhel-9
    image: registry.redhat.io/ubi9-init:latest
    dockerfile: Dockerfile.rhel  # Custom Dockerfile for RHEL-based systems
    pre_build_image: false       # Force use of custom Dockerfile
    systemd: always              # Podman native systemd support
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    # Avoid privileged: true - use rootless Podman instead
    cgroupns_mode: host
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    groups:
      - rhel9_compatible

driver:
  name: podman
  options:
    podman_extra_args: --systemd=true --log-level=info
```

### Custom Dockerfile for RHEL-based Systems:
To resolve package manager compatibility issues, all RHEL-based platforms now use a custom `Dockerfile.rhel`:

```dockerfile
# Molecule managed Dockerfile for RHEL-based containers
# Supports RHEL 9, RHEL 10, Rocky Linux, AlmaLinux, and compatible distributions

# Use ARG to make the base image configurable (Molecule passes this automatically)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Install essential packages using dnf (RHEL package manager)
RUN if [ $(command -v dnf) ]; then \
        dnf update -y && \
        dnf install -y \
            python3 \
            python3-pip \
            sudo \
            bash \
            ca-certificates \
            iproute \
            openssh-clients \
            systemd \
            procps-ng \
            which \
            tar \
            gzip \
        && dnf clean all; \
    elif [ $(command -v yum) ]; then \
        yum update -y && \
        yum install -y \
            python3 \
            python3-pip \
            sudo \
            bash \
            ca-certificates \
            iproute \
            openssh-clients \
            systemd \
            procps-ng \
            which \
            tar \
            gzip \
        && yum clean all; \
    fi

# Create molecule user with sudo privileges
RUN useradd -m -s /bin/bash molecule && \
    echo "molecule ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/molecule && \
    chmod 0440 /etc/sudoers.d/molecule

# Set up Python symlinks if needed
RUN if [ ! -e /usr/bin/python ]; then ln -sf /usr/bin/python3 /usr/bin/python; fi

# Set working directory
WORKDIR /tmp

# Default command for systemd init
CMD ["/usr/sbin/init"]
```

### Key Configuration Requirements:
1. **Custom Dockerfile**: Use `dockerfile: Dockerfile.rhel` for all RHEL-based platforms
2. **Disable Pre-built Images**: Set `pre_build_image: false` to force custom Dockerfile usage
3. **Package Manager Detection**: Dockerfile automatically detects and uses appropriate package manager (`dnf` or `yum`)
4. **Base Image Flexibility**: Uses ARG to accept any RHEL-compatible base image

### Security-Enhanced Configuration:
```yaml
platforms:
  - name: rhel-9-secure
    image: registry.redhat.io/ubi9-init:latest
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN  # Virtualized via user namespaces
    user_namespace_mode: auto
    security_opts:
      - seccomp:systemd-seccomp-profile.json
    groups:
      - rhel9_compatible
```

### Testing Validation:
- Verify systemd is running as PID 1: `ps aux | head -n 2`
- Test service management: `systemctl status`
- Confirm cgroup access: `ls -la /sys/fs/cgroup`
- Validate security context: `podman exec <container> id`

### Performance Monitoring:
- Container startup time: Target <300ms
- systemd userspace boot: Target <3s
- Memory usage: Monitor 100-300MB baseline
- Test cycle duration: Target 1.5-3 minutes

### Security Validation:
- Verify user namespace mapping: `podman unshare cat /proc/self/uid_map`
- Check capability restrictions: `podman exec <container> capsh --print`
- Validate Seccomp profile: `podman exec <container> grep Seccomp /proc/self/status`

## Compliance and Enterprise Considerations

### FIPS Compliance:
- **Host Requirement**: FIPS mode must be configured on the host system before container runtime installation
- **Container Runtime**: Podman/CRI-O must support and propagate FIPS settings to containers
- **Image Selection**: Use FIPS-validated UBI images when available

### STIG Compliance:
- Implement automated STIG compliance checks in CI/CD pipelines using Ansible Lint, Checkov, or KICS
- Use Molecule for validating STIG-compliant system behavior through Testinfra assertions
- Document security configuration deviations when systemd functionality requires specific permissions

### Resource Management:
- **CPU Limits**: Define explicit CPU limits (e.g., `cpus: 1`) to prevent resource monopolization
- **Memory Limits**: Set memory constraints (e.g., `memory: 1G`) based on service requirements
- **Monitoring**: Implement resource usage monitoring with alerts for threshold breaches

## Production Implementation

### GitHub Actions Workflow Configuration
The following configuration demonstrates ADR-compliant implementation in our RHEL Compatibility Matrix workflow:

```yaml
# .github/workflows/rhel-compatibility-matrix.yml
# Uses only images currently available on the target machine
platforms:
  - name: rhel${{ matrix.rhel_version }}-test
    image: >-
      {%- if matrix.rhel_version == '8' -%}
      docker.io/rockylinux/rockylinux:8-ubi-init
      {%- elif matrix.rhel_version == '9' -%}
      registry.redhat.io/ubi9-init:latest
      {%- elif matrix.rhel_version == '10' -%}
      registry.redhat.io/ubi10-init:latest
      {%- else -%}
      registry.redhat.io/ubi9-init:latest
      {%- endif -%}
    systemd: always
    command: /usr/sbin/init
    capabilities:
      - SYS_ADMIN
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
```

### Container Validation Testing
For direct container testing in CI/CD pipelines:

```bash
# Start ADR-compliant systemd-enabled containers
podman run -d --name ubi9-init --systemd=always \
  --cap-add SYS_ADMIN \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  registry.redhat.io/ubi9-init:latest /usr/sbin/init

podman run -d --name ubi8-init --systemd=always \
  --cap-add SYS_ADMIN \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  registry.redhat.io/ubi8-init:latest /usr/sbin/init
```

### Verified Compatible Images
The following images have been tested and verified in production CI/CD environments with custom RHEL Dockerfile support:

| Image | Version | systemd Support | Package Manager | Dockerfile Status |
|-------|---------|-----------------|-----------------|------------------|
| `registry.redhat.io/ubi9-init:latest` | 9.6-1751962289 | ✅ Built-in | `dnf` | ✅ Dockerfile.rhel |
| `registry.redhat.io/ubi10-init:latest` | 10.0-1751895590 | ✅ Built-in | `dnf` | ✅ Dockerfile.rhel |
| `docker.io/rockylinux/rockylinux:8-ubi-init` | 8.x | ✅ Built-in | `dnf`/`yum` | ✅ Dockerfile.rhel |
| `docker.io/rockylinux/rockylinux:9-ubi-init` | 9.x | ✅ Built-in | `dnf` | ✅ Dockerfile.rhel |
| `docker.io/almalinux/9-init:latest` | 9.6-20250712 | ✅ Built-in | `dnf` | ✅ Dockerfile.rhel |
| `quay.io/centos/centos:stream9-init` | Stream 9 | ✅ Built-in | `dnf` | ✅ Dockerfile.rhel |

**Package Manager Compatibility**: All RHEL-based images now use the custom `Dockerfile.rhel` which automatically detects and uses the appropriate package manager (`dnf` for modern systems, `yum` for legacy systems).

**Migration Note**: Existing molecule configurations **must** be updated to include:
- `dockerfile: Dockerfile.rhel` 
- `pre_build_image: false`

**Note**: CentOS Stream images are intentionally excluded from production use due to stability and enterprise support considerations.

## References
- [Red Hat Blog: Developing and Testing Ansible Roles with Molecule and Podman](https://www.redhat.com/en/blog/developing-and-testing-ansible-roles-with-molecule-and-podman-part-1)
- [Ansible Forum: Podman container w/ systemd for molecule doesn't run init](https://forum.ansible.com/t/podman-container-w-systemd-for-molecule-doesnt-run-init/3529)
- [Medium: Testing Ansible role of a systemd-based service using Molecule and Docker](https://medium.com/@TomaszKlosinski/testing-ansible-role-of-a-systemd-based-service-using-molecule-and-docker-4b3608a10ef0)
- [Sysbee Blog: Testing Ansible playbooks with Molecule](https://www.sysbee.net/blog/testing-ansible-playbooks-with-molecule/)
- [GitHub Issue: Molecule tmpfs wants dict, not list](https://github.com/ansible/molecule/issues/4140)
- [Research Validation Report: Init Container vs Regular Container Technical Evaluation](../research/manual-research-results-july-12-2025.md)
- [Production Implementation: RHEL Compatibility Matrix Workflow](../../.github/workflows/rhel-compatibility-matrix.yml)

## Decision Date
2025-01-12 (Initial)  
2025-07-12 (Updated with research validation)  
2025-07-19 (Package manager compatibility fix)

## Decision Makers
- Ansible Collection Development Team
- Infrastructure Testing Team
