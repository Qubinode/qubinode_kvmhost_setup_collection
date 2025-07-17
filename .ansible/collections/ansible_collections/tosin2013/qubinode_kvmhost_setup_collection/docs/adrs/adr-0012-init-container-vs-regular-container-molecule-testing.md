# ADR-0012: Use Init Containers for Molecule Testing with systemd Services

## Status
Accepted - Updated with Research Validation (2025-07-12)

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
    systemd: always  # Podman native systemd support
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

## References
- [Red Hat Blog: Developing and Testing Ansible Roles with Molecule and Podman](https://www.redhat.com/en/blog/developing-and-testing-ansible-roles-with-molecule-and-podman-part-1)
- [Ansible Forum: Podman container w/ systemd for molecule doesn't run init](https://forum.ansible.com/t/podman-container-w-systemd-for-molecule-doesnt-run-init/3529)
- [Medium: Testing Ansible role of a systemd-based service using Molecule and Docker](https://medium.com/@TomaszKlosinski/testing-ansible-role-of-a-systemd-based-service-using-molecule-and-docker-4b3608a10ef0)
- [Sysbee Blog: Testing Ansible playbooks with Molecule](https://www.sysbee.net/blog/testing-ansible-playbooks-with-molecule/)
- [GitHub Issue: Molecule tmpfs wants dict, not list](https://github.com/ansible/molecule/issues/4140)
- [Research Validation Report: Init Container vs Regular Container Technical Evaluation](../research/manual-research-results-july-12-2025.md)

## Decision Date
2025-01-12 (Initial)  
2025-07-12 (Updated with research validation)

## Decision Makers
- Ansible Collection Development Team
- Infrastructure Testing Team
