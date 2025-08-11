# ADR-0012: EPEL Repository Management and GPG Verification Strategy

## Status
Accepted

## Context

The Extra Packages for Enterprise Linux (EPEL) repository provides valuable additional packages for RHEL-compatible distributions like Rocky Linux, AlmaLinux, and CentOS. However, EPEL repositories can experience GPG verification issues in CI/CD environments, particularly in GitHub Actions runners, causing build failures.

### Problems Identified

1. **GPG Verification Failures**: EPEL mirrors sometimes have missing or corrupted GPG signature files (.asc)
2. **CI/CD Environment Issues**: GitHub Actions runners may have pre-configured EPEL with problematic mirror configurations
3. **Network Connectivity**: Some EPEL mirrors may be unreachable or slow in certain geographic regions
4. **Security vs Functionality Trade-off**: GPG verification provides security but can block CI/CD pipelines

### Current Issues

```
Error: Failed to download metadata for repo 'epel': GPG verification is enabled, but GPG signature is not available. This may be an error or the repository does not support GPG verification: Status code: 404 for [mirror-url]/repodata/repomd.xml.asc
```

## Decision

We will implement a **configurable EPEL repository management strategy** with the following components:

### 1. Default Configuration
- **Enable EPEL by default** for access to additional packages
- **Disable GPG verification by default** for CI/CD environments
- **Import GPG keys** for optional future use

### 2. Configuration Variables

```yaml
# EPEL Repository Configuration
enable_epel: true                    # Enable EPEL repository
epel_gpg_check: false               # Disable GPG verification (default)
epel_gpg_import_keys: true          # Import keys for optional use
```

### 3. GitHub Actions Integration

Add workflow input parameter:
```yaml
enable_epel_gpg:
  description: 'Enable GPG verification for EPEL repositories'
  required: false
  default: false
  type: boolean
```

### 4. Ansible Role Implementation

- Create `epel_management.yml` task file in `kvmhost_base` role
- Handle EPEL installation, configuration, and GPG settings
- Provide error handling and fallback mechanisms
- Support both enabled and disabled GPG verification modes

## Consequences

### Positive
- **Improved CI/CD Reliability**: Eliminates GPG verification failures in automated environments
- **Maintained Functionality**: EPEL packages remain available for installation
- **Flexibility**: Users can enable GPG verification when needed
- **Clear Configuration**: Explicit variables control EPEL behavior
- **Documentation**: Clear instructions for different use cases

### Negative
- **Reduced Security**: Disabled GPG verification removes package authenticity checks
- **Potential Risk**: Packages from EPEL may not be verified in default configuration
- **Complexity**: Additional configuration options to manage

### Mitigation Strategies

1. **Clear Documentation**: Provide instructions for enabling GPG verification in production
2. **Environment-Specific Defaults**: Different defaults for CI vs production environments
3. **Manual Verification**: Provide scripts for manual EPEL cleanup and configuration
4. **Monitoring**: Log EPEL configuration status for visibility

## Implementation

### Phase 1: Core Implementation
- [x] Add EPEL configuration variables to role defaults
- [x] Create EPEL management task file
- [x] Update GitHub Actions workflow with optional GPG flag
- [x] Create manual EPEL cleanup script

### Phase 2: Documentation
- [x] Create this ADR
- [ ] Update README with EPEL configuration instructions
- [ ] Add troubleshooting guide for EPEL issues

### Phase 3: Testing
- [ ] Test EPEL configuration in different environments
- [ ] Validate GPG verification enable/disable functionality
- [ ] Test manual cleanup script on various systems

## Configuration Examples

### CI/CD Environment (Default)
```yaml
enable_epel: true
epel_gpg_check: false
epel_gpg_import_keys: true
```

### Production Environment (Secure)
```yaml
enable_epel: true
epel_gpg_check: true
epel_gpg_import_keys: true
```

### Minimal Environment (No EPEL)
```yaml
enable_epel: false
```

## Usage Instructions

### For CI/CD (GitHub Actions)
1. Use default settings (GPG verification disabled)
2. Optionally enable GPG verification via workflow input
3. Run manual cleanup script if issues persist

### For Production Deployments
1. Set `epel_gpg_check: true` in inventory
2. Ensure network connectivity to EPEL mirrors
3. Monitor for GPG verification issues

### Manual EPEL Cleanup
```bash
# Run on problematic systems
sudo ./scripts/fix-epel-on-runner.sh
```

## Related ADRs
- ADR-0001: Package Management Strategy
- ADR-0008: RHEL 9/10 Support Strategy

## References
- [EPEL Documentation](https://docs.fedoraproject.org/en-US/epel/)
- [DNF Configuration Reference](https://dnf.readthedocs.io/en/latest/conf_ref.html)
- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
