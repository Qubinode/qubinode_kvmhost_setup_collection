# EPEL GPG Verification in Container Testing Environments

## Research Overview

**Research Question**: What is the current state of GPG signature availability and verification for EPEL repositories in container testing environments?

**Date**: 2025-01-15  
**Scope**: Investigation of EPEL GPG verification failures in Molecule/Podman testing environments  
**Related ADRs**: ADR-0012 (Container Security), ADR-0011 (Local Testing), ADR-0013 (Testing Evolution)

## Research Methodology

### Primary Investigation Areas
1. **Ansible GPG Key Management Issues**
   - Analysis of rpm_key module behavior in container environments
   - Investigation of repomd.xml signature verification failures
   - Examination of container security constraints affecting key import

2. **Container Environment Analysis**
   - UBI container repository access patterns
   - Podman security model impact on privileged operations
   - Container-in-container CI/CD limitations

3. **Testing Framework Compatibility**
   - Molecule testing scenarios with EPEL repositories
   - Security-enhanced container testing approaches
   - Alternative testing strategies using systemd integration

### Evidence Collection Methods
- Web search analysis of similar issues in Ansible/Podman communities
- Technical documentation review from Red Hat and container security sources
- Community forum analysis for GPG verification workarounds

## Key Findings

### 1. Ansible rpm_key Module Container Issues

**Evidence Gathered**:
- GitHub Issue #20711: "Installing a key with rpm_key does not really import it" shows widespread repomd.xml signature verification failures
- Ansible 2.9.13 introduced breaking changes requiring explicit GPG key handling for EPEL repositories
- Container environments require manual workarounds: `rpm --import URL` or `yum makecache` procedures
- Container testing environments have fundamentally different repository access patterns than traditional systems

**Impact**: Critical testing infrastructure failure affecting EPEL repository validation in UBI containers used by Molecule testing framework.

### 2. UBI Container GPG Key Management Gaps

**Evidence Gathered**:
- Red Hat documentation confirms UBI containers require specific GPG key management for external repositories
- EPEL-8 repositories require RPM-GPG-KEY-EPEL-8, but containers don't auto-import from packagecloud.io sources
- Testing environments consistently show 404 errors for GPG signature verification from EPEL mirrors
- Molecule testing framework with Podman containers systematically fails EPEL repository validation

**Impact**: Testing framework cannot validate EPEL repository packages in security-enhanced containers, creating deployment readiness blockers.

### 3. Container Security Model Conflicts

**Evidence Gathered**:
- Podman rootless containers cannot perform privileged mount operations required for GPG keyring setup
- Docker/Podman seccomp profiles block mount syscalls necessary for repository validation
- Testing frameworks require `--privileged` mode or custom seccomp profiles for proper GPG handling
- Container-in-container scenarios (CI/CD environments like GitHub Actions, CircleCI) face additional privilege escalation restrictions

**Impact**: Security-enhanced testing infrastructure conflicts with repository verification requirements, forcing choice between security and functionality.

### 4. Alternative Testing Approaches

**Evidence Gathered**:
- UBI-init containers with systemd support provide enhanced service management capabilities for testing scenarios
- Podman privileged mode with `--net=host` enables proper repository and service testing when security constraints are relaxed
- Security-enhanced containers require specific volume mounts and capability grants for testing frameworks
- Container testing environments show improved stability with rootless Podman using fuse-overlayfs storage drivers

**Impact**: Enhanced container security through proper init system integration while maintaining testing capabilities, but requires architectural changes to current testing approach.

## Technical Analysis

### Root Cause Assessment
The EPEL GPG verification failures stem from a confluence of factors:

1. **Ansible Changes**: Version 2.9.13+ enforces stricter GPG verification, breaking previously working container configurations
2. **Container Security**: Enhanced security models in UBI containers prevent privileged operations needed for key import
3. **Repository Architecture**: EPEL's distributed mirror system with packagecloud.io shows inconsistent GPG signature availability
4. **Testing Framework Limitations**: Molecule's security-first approach conflicts with repository validation requirements

### Workaround Solutions Identified

#### Immediate Workarounds
1. **Disable GPG Checking**: Add `disable_gpg_check: yes` to package tasks (security risk)
2. **Manual Key Import**: Pre-import EPEL GPG keys in container initialization
3. **Privileged Testing**: Use `--privileged` mode for Molecule containers (reduces security)
4. **Alternative Storage**: Configure `--storage-driver=vfs` for compatibility

#### Strategic Solutions
1. **Enhanced Container Images**: Create custom UBI images with pre-imported EPEL keys
2. **Security Policy Updates**: Develop custom seccomp profiles allowing necessary mount operations
3. **Testing Architecture**: Migrate to systemd-enabled containers with proper service management
4. **Repository Management**: Implement local EPEL mirror with consistent GPG signature availability

## Recommendations

### Short-term Actions
1. **Update Testing Documentation**: Document GPG verification workarounds for immediate use
2. **Container Configuration**: Modify Molecule scenarios to pre-import required GPG keys
3. **Security Assessment**: Evaluate acceptable security trade-offs for testing environments

### Long-term Strategy
1. **Container Architecture**: Transition to systemd-enabled UBI-init containers for enhanced service testing
2. **Security Enhancement**: Develop testing-specific security profiles that balance verification with security
3. **Repository Strategy**: Consider implementing local package mirrors for consistent testing environment

### ADR Impact Assessment
This research directly impacts:
- **ADR-0012**: Container security model needs refinement for testing scenarios
- **ADR-0011**: Local testing procedures require GPG verification workarounds
- **ADR-0013**: Testing evolution strategy should incorporate systematic GPG handling

## Implementation Priority

**High Priority**:
1. Implement immediate GPG key pre-import in testing containers
2. Update testing documentation with verified workaround procedures
3. Modify Molecule scenarios to handle EPEL repository verification

**Medium Priority**:
1. Develop enhanced container images with pre-configured repository keys
2. Create testing-specific security profiles for Podman containers
3. Establish systematic approach to repository mirror management

**Low Priority**:
1. Evaluate alternative testing frameworks with better GPG integration
2. Consider contribution to upstream Ansible for improved container GPG handling
3. Develop automated testing for GPG verification scenarios

## Conclusion

The EPEL GPG verification failures represent a systematic issue at the intersection of container security, repository management, and testing framework evolution. While immediate workarounds exist, a comprehensive solution requires balanced approach between security enhancement and practical testing requirements.

The research demonstrates that container-based testing environments require specialized consideration for GPG verification workflows, and the current ADR framework provides a solid foundation for implementing both immediate fixes and long-term improvements.

**Next Steps**: Implement immediate workarounds for deployment readiness while developing comprehensive container security strategy for future testing architecture.