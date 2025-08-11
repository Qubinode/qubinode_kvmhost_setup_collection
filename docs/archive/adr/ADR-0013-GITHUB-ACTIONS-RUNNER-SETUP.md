# ADR-0013: GitHub Actions Self-Hosted Runner Setup for RHEL-Based Systems

## Status
Accepted

## Context

This collection requires GitHub Actions self-hosted runners to execute CI/CD pipelines, including Molecule testing, ansible-lint, and security scanning. The runner system must be properly configured to support the collection's requirements while maintaining reliability and security.

### Key Requirements

1. **Package Management**: Reliable access to required packages and repositories
2. **Python Environment**: Python 3.11+ with proper SELinux bindings
3. **Container Runtime**: Podman for Molecule testing
4. **EPEL Repository**: Access to additional packages without GPG verification issues
5. **System Compatibility**: Support for RHEL-compatible distributions

### Current Implementation

- **Primary Target**: Rocky Linux 9.x (recommended)
- **Alternative Options**: AlmaLinux, RHEL, CentOS Stream
- **Architecture**: x86_64
- **Container Runtime**: Podman (not Docker)

## Decision

We will provide **comprehensive setup guidance** for GitHub Actions self-hosted runners on RHEL-based systems, with specific considerations for different distributions.

## Implementation

### Recommended Runner Configuration

#### Primary Recommendation: Rocky Linux 9.x

**Why Rocky Linux?**
- ✅ Free and open-source
- ✅ RHEL-compatible without subscription requirements
- ✅ Reliable EPEL repository access
- ✅ Active community support
- ✅ Predictable release cycle

**Setup Script**: `scripts/setup-github-runner-rocky.sh`

#### Alternative Options

| Distribution | Pros | Cons | Special Considerations |
|-------------|------|------|----------------------|
| **AlmaLinux 9.x** | Free, RHEL-compatible, stable | Smaller community | Same as Rocky Linux setup |
| **RHEL 9.x** | Official support, enterprise features | Requires subscription | Subscription management needed |
| **CentOS Stream 9** | Upstream of RHEL, latest features | Rolling release, less stable | More frequent updates required |

### Distribution-Specific Setup Instructions

#### Rocky Linux 9.x (Recommended)

```bash
# Use the provided setup script
sudo ./scripts/setup-github-runner-rocky.sh

# Key features:
# - Automatic EPEL configuration with --nogpgcheck for reliability
# - Python 3.11 installation and configuration
# - Podman setup for Molecule testing
# - SELinux configuration for CI environments
# - GPG verification bypass for Rocky Linux systems
```

#### AlmaLinux 9.x

```bash
# AlmaLinux uses identical setup to Rocky Linux
sudo ./scripts/setup-github-runner-rocky.sh

# Verify AlmaLinux-specific repositories
sudo dnf repolist enabled
```

#### RHEL 9.x

```bash
# Prerequisites: Active RHEL subscription
sudo subscription-manager register
sudo subscription-manager attach --auto

# Enable required repositories
sudo subscription-manager repos --enable rhel-9-for-x86_64-baseos-rpms
sudo subscription-manager repos --enable rhel-9-for-x86_64-appstream-rpms
sudo subscription-manager repos --enable codeready-builder-for-rhel-9-x86_64-rpms

# Install EPEL (requires CodeReady Builder)
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Continue with standard setup
sudo ./scripts/setup-github-runner.sh
```

#### CentOS Stream 9

```bash
# Enable EPEL repository
sudo dnf install -y epel-release

# Note: CentOS Stream is a rolling release
# More frequent system updates may be required
sudo dnf update -y

# Continue with standard setup
sudo ./scripts/setup-github-runner.sh
```

### Required System Specifications

#### Minimum Requirements
- **CPU**: 2 cores
- **RAM**: 4 GB
- **Storage**: 20 GB free space
- **Network**: Reliable internet connection

#### Recommended Specifications
- **CPU**: 4+ cores
- **RAM**: 8+ GB
- **Storage**: 50+ GB free space (for container images and build artifacts)
- **Network**: High-speed internet connection

### EPEL Repository Configuration

#### Default Configuration (CI-Optimized)
```yaml
# Inventory configuration
enable_epel: true
epel_gpg_check: false  # Disabled for CI reliability
epel_gpg_import_keys: true
```

#### Production Configuration (Security-Enhanced)
```yaml
# For production runners (if needed)
enable_epel: true
epel_gpg_check: true   # Enabled for security
epel_gpg_import_keys: true
```

#### Manual EPEL Cleanup (If Issues Occur)
```bash
# Run the EPEL cleanup script
sudo ./scripts/fix-epel-on-runner.sh
```

### Security Considerations

#### SELinux Configuration
- **Default**: Enforcing mode maintained
- **CI Adjustments**: Minimal policy adjustments for container operations
- **Python Bindings**: Proper SELinux Python bindings installed

#### Container Security
- **Runtime**: Podman (rootless when possible)
- **Images**: Official UBI images for RHEL compatibility
- **Isolation**: Proper container isolation maintained

#### Network Security
- **Firewall**: Maintain firewall rules
- **Updates**: Regular security updates
- **Access**: Restrict runner access appropriately

### Troubleshooting Guide

#### Common Issues and Solutions

1. **EPEL GPG Verification Failures**
   ```bash
   # Solution 1: Run EPEL cleanup script (uses --nogpgcheck for Rocky Linux)
   sudo ./scripts/fix-epel-on-runner.sh

   # Solution 2: Manual fix for Rocky Linux
   sudo dnf install -y --nogpgcheck epel-release
   ```

2. **Python SELinux Binding Issues**
   ```bash
   # Solution: Reinstall SELinux bindings
   sudo dnf reinstall python3-libselinux libselinux-python3
   ```

3. **Podman Permission Issues**
   ```bash
   # Solution: Configure rootless Podman
   sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 github-runner
   ```

4. **Subscription Issues (RHEL only)**
   ```bash
   # Solution: Verify and refresh subscription
   sudo subscription-manager refresh
   sudo subscription-manager list --available
   ```

### Maintenance Procedures

#### Regular Maintenance
- **Weekly**: System updates (`sudo dnf update`)
- **Monthly**: Container image cleanup (`podman system prune`)
- **Quarterly**: Runner software updates

#### Monitoring
- **Disk Space**: Monitor `/var/lib/containers` and `/tmp`
- **Memory Usage**: Monitor during test execution
- **Network**: Monitor for connectivity issues

## Migration Guide

### From Other Distributions

#### From CentOS 7/8 to Rocky Linux 9
1. Plan for major version upgrade
2. Backup runner configuration
3. Fresh installation recommended
4. Restore runner registration

#### From Ubuntu to Rocky Linux
1. Export GitHub runner token
2. Fresh Rocky Linux installation
3. Run setup script
4. Re-register runner

### Runner Registration
```bash
# Download and configure GitHub Actions runner
./config.sh --url https://github.com/your-org/your-repo --token YOUR_TOKEN

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
```

## Related ADRs
- ADR-0001: Package Management Strategy
- ADR-0008: RHEL 9/10 Support Strategy
- ADR-0012: EPEL Repository Management

## References
- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Rocky Linux Documentation](https://docs.rockylinux.org/)
- [AlmaLinux Documentation](https://wiki.almalinux.org/)
- [RHEL Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9)
