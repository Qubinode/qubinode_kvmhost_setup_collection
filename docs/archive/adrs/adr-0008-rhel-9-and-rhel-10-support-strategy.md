# ADR-0008: RHEL 9 and RHEL 10 Support Strategy

## Status
Implemented

> **Review Note (2026-01-25)**: ADR compliance review confirmed full implementation with
> 9/10 compliance score. Multi-version support strategy is fully implemented with
> RHEL 8/9/10 detection, Python 3.11 compatibility, and version-specific task handling.

## Context
The Qubinode project currently targets RHEL-based systems but needs to ensure compatibility with newer versions of Red Hat Enterprise Linux, specifically RHEL 9 and RHEL 10. These newer versions introduce:

- Updated package management (dnf as default)
- New system service management approaches
- Updated virtualization stack (libvirt, KVM)
- Modified security policies and SELinux contexts
- Changes in default networking configurations
- Updated Python runtime (Python 3.9+ in RHEL 9, Python 3.11+ in RHEL 10)
- Enhanced Ansible compatibility requirements (see [Python 3.11 Compatibility Research](../research/rhel9-python311-ansible-compatibility-2025.md))

### RHEL 10 Critical Architectural Changes

RHEL 10 introduces fundamental architectural shifts that impact remote access capabilities:

1. **Xorg Display Server Deprecation**: RHEL 10 deprecates and removes the X.Org display server in favor of Wayland as the default and only supported display protocol [1][4]. This is a permanent, deliberate architectural decision by Red Hat.

2. **Remote Desktop Package Obsolescence**: Traditional X11-dependent remote access packages (`tigervnc-server`, `xrdp`) are no longer available in RHEL 10 repositories [2][3]. These packages fundamentally depend on Xorg and cannot function in a Wayland-only environment.

3. **New RDP Architecture**: The official Red Hat-supported replacement is `gnome-remote-desktop`, a Wayland-native Remote Desktop Protocol (RDP) implementation [6][8]. This represents a complete paradigm shift from VNC/X11 to RDP/Wayland.

4. **SELinux Compatibility Blocker**: As of this writing, Red Hat Bugzilla 2271661 documents that `gnome-remote-desktop` "Remote Login" (headless) mode is incompatible with SELinux in enforcing mode [10]. This creates a critical blocker for KVM hypervisor deployments where SELinux (sVirt) provides essential security isolation for virtual machines.

The project must maintain backward compatibility while adapting to these fundamental platform changes. For KVM hypervisors, disabling SELinux is not an acceptable workaround due to the security implications for virtual machine isolation.

## Decision
Implement a multi-version support strategy that:

1. **Primary Support**: RHEL 8, RHEL 9, and Rocky Linux equivalents
2. **Future Support**: RHEL 10 compatibility preparation
3. **Version Detection**: Automatic OS version detection and conditional task execution
4. **Package Management**: Standardize on DNF module for all supported versions
5. **Python Compatibility**: Support Python 3.8+ across all versions
6. **Testing Matrix**: Include multiple RHEL versions in CI/CD testing

## Alternatives Considered
1. **Single version support** - Only support latest RHEL version
   - Pros: Simpler maintenance, latest features
   - Cons: Limits adoption, forces upgrades, reduces compatibility

2. **Separate branches per version** - Different code branches for each RHEL version
   - Pros: Version-specific optimizations
   - Cons: Code duplication, maintenance overhead, fragmented development

3. **Container-only deployment** - Only support containerized deployments
   - Pros: Consistent runtime environment
   - Cons: Doesn't address host OS compatibility needs

4. **Manual version handling** - Require users to specify their OS version
   - Pros: Explicit control over version-specific behavior
   - Cons: Error-prone, user burden, inconsistent experience

## Consequences

### Positive
- **Broader compatibility** - Supports multiple RHEL/Rocky Linux versions
- **Future-ready** - Prepared for RHEL 10 when available
- **Automatic detection** - No user intervention required for version differences
- **Consistent experience** - Same automation works across versions
- **Migration path** - Smooth transition between RHEL versions
- **Enterprise adoption** - Supports various enterprise OS strategies
- **Community support** - Compatible with Rocky Linux and CentOS Stream

### Negative
- **Increased complexity** - More conditional logic in roles
- **Testing overhead** - Multiple OS versions to test and validate
- **Maintenance burden** - Need to track changes across multiple OS versions
- **Feature limitations** - May not utilize latest OS features to maintain compatibility

## Implementation

### Version Detection
```yaml
- name: Detect OS version
  set_fact:
    os_major_version: "{{ ansible_distribution_major_version | int }}"
    is_rhel9_plus: "{{ ansible_distribution_major_version | int >= 9 }}"
    is_rhel10_plus: "{{ ansible_distribution_major_version | int >= 10 }}"
```

### Conditional Package Management
```yaml
- name: Install packages (RHEL 8+)
  dnf:
    name: "{{ packages_rhel8_plus }}"
    state: present
  when: os_major_version >= 8

- name: Install RHEL 9 specific packages
  dnf:
    name: "{{ packages_rhel9_specific }}"
    state: present
  when: os_major_version >= 9
```

### Python Compatibility (Updated 2025)
Based on comprehensive research findings:

- **RHEL 8**: Python 3.6 default creates compatibility challenges with Ansible-core 2.17+
- **RHEL 9**: Python 3.9 default with 3.11/3.12 available for enhanced performance
- **Recommended Strategy**: Use Python 3.11 for new deployments on RHEL 9
- **Migration Path**: Install python3.11 package on RHEL 9 for optimal compatibility

```yaml
# Updated Python detection and configuration
- name: Configure Python interpreter (RHEL 9+)
  set_fact:
    ansible_python_interpreter: >-
      {{
        '/usr/bin/python3.11' if (os_major_version >= 9 and 
        python311_available | default(false)) else 
        ansible_python_interpreter | default('/usr/bin/python3')
      }}
  when: os_major_version >= 9

- name: Check Python 3.11 availability
  stat:
    path: /usr/bin/python3.11
  register: python311_check
  
- name: Set Python 3.11 availability fact
  set_fact:
    python311_available: "{{ python311_check.stat.exists }}"
```

### Supported Versions Matrix (Updated 2025)
| OS Version | Support Level | Default Python | Available Python | Package Manager | Ansible-core Compatibility | Remote Desktop |
|------------|---------------|----------------|------------------|-----------------|----------------------------|----------------|
| RHEL 8.x   | Limited*      | Python 3.6     | 3.6, 3.8, 3.9, 3.11 | DNF         | 2.16 LTS (requires Python 3.11 for 2.17+) | VNC/X11 (tigervnc-server, xrdp) |
| RHEL 9.x   | Full Support  | Python 3.9     | 3.9, 3.11, 3.12 | DNF             | 2.17, 2.18 (recommended) | VNC/X11 (tigervnc-server, xrdp) |
| Rocky 8.x  | Limited*      | Python 3.6     | 3.6, 3.8, 3.9, 3.11 | DNF         | 2.16 LTS (requires Python 3.11 for 2.17+) | VNC/X11 (tigervnc-server, xrdp) |
| Rocky 9.x  | Full Support  | Python 3.9     | 3.9, 3.11, 3.12 | DNF             | 2.17, 2.18 (recommended) | VNC/X11 (tigervnc-server, xrdp) |
| RHEL 10.x  | Partial**     | Python 3.12    | 3.12, 3.13      | DNF             | 2.18+ | RDP/Wayland (gnome-remote-desktop) - SELinux blocker [10] |

*Limited support due to Python 3.6 EOL and Ansible compatibility constraints  
**RHEL 10 support blocked for remote desktop features due to SELinux incompatibility (BZ 2271661)

### Remote Desktop Strategy (RHEL 10)

Given the SELinux incompatibility blocker, a two-phase approach is required:

#### Phase 1: Fail-Fast Protection (Immediate)
```yaml
- name: Fail fast on RHEL 10 with remote desktop enabled
  ansible.builtin.fail:
    msg: >
      FATAL: The 'enable_vnc: true' variable is not supported on RHEL 10 / CentOS Stream 10.
      
      This platform deprecates VNC/X11. The new RDP-based architecture ('gnome-remote-desktop')
      is currently blocked by an SELinux bug (Red Hat BZ 2271661) that prevents it
      from running in 'enforcing' mode.
      
      This collection prioritizes hypervisor security and WILL NOT disable SELinux.
      Remote Desktop support for RHEL 10 will be enabled when the SELinux policy is fixed upstream.
      
      WORKAROUND: Set 'enable_vnc: false' in your inventory for RHEL 10 hosts.
  when:
    - enable_vnc | default(true) | bool
    - kvmhost_os_major_version|int >= 10
```

#### Phase 2: Strategic Implementation (Post SELinux Fix)

When the SELinux policy is fixed, implement the complete gnome-remote-desktop automation:

1. **Package Installation**: Install `@Server with GUI`, `gnome-remote-desktop`, `freerdp`
2. **TLS Certificate Generation**: Use `winpr-makecert` to generate RDP certificates
3. **Service Configuration**: Configure via `grdctl --system` commands
4. **Service Enablement**: Enable `gdm.service` and `gnome-remote-desktop.service`
5. **Firewall Configuration**: Open RDP service (port 3389)
6. **SELinux Policy Validation**: Check for fixed `selinux-policy` version before enabling

See [ADR-0015: Remote Desktop Architecture Decision](./adr-0015-remote-desktop-architecture.md) for complete implementation details.

### Testing Strategy
- CI/CD pipeline tests against multiple OS versions
- Molecule scenarios for each supported version
- Regular testing with CentOS Stream and Rocky Linux
- RHEL 10 testing limited to non-remote-desktop features until SELinux fix

## Evidence
### Implementation Artifacts
- OS version detection tasks in role implementations
- Conditional package installation based on OS version
- DNF module usage standardized across all versions
- CI/CD pipeline configuration for multi-version testing

### Research Documentation
- [RHEL 9 Python 3.11 Compatibility Research](../research/rhel9-python311-ansible-compatibility-2025.md) - Comprehensive compatibility analysis
- Updated support matrix based on 2025 ecosystem research
- Ansible-core compatibility validation across RHEL versions
- Performance benchmarking for Python version choices

### Validation Evidence
- ✅ RHEL 9 Python 3.11 packages availability confirmed
- ✅ Ansible-core 2.17/2.18 RHEL 9 compatibility verified
- ⚠️ RHEL 8 requires manual Python 3.11 installation for latest Ansible
- ✅ Rocky Linux maintains full compatibility with RHEL versions

## External References

1. **Xorg Deprecation in RHEL 10**  
   Red Hat Customer Portal - "Major changes in RHEL 10"  
   Confirms removal of X.Org display server in RHEL 10

2. **tigervnc-server Package Unavailability**  
   CentOS Stream 10 AppStream Repository Analysis  
   Package not present in RHEL 10 repositories

3. **xrdp Package Unavailability**  
   CentOS Stream 10 AppStream Repository Analysis  
   Package not present in RHEL 10 repositories

4. **Wayland as Default Display Protocol**  
   Red Hat Documentation - RHEL 10 Desktop Environment  
   Wayland is the only supported display server

6. **gnome-remote-desktop Official Documentation**  
   Red Hat RHEL 10 Documentation - "Enabling remote access via RDP"  
   Official replacement for VNC-based remote access

8. **grdctl Configuration Tool**  
   Red Hat RHEL 10 Documentation - System-level RDP configuration  
   Command-line utility for gnome-remote-desktop setup

10. **Red Hat Bugzilla 2271661**  
    "gnome-remote-desktop system login feature is disallowed in enforcing mode"  
    Critical blocker: SELinux incompatibility with Remote Login mode  
    Status: Open as of November 2025  
    Impact: Prevents secure deployment on KVM hypervisors

18. **RDP Firewall Configuration**  
    RHEL 10 Documentation - Default RDP port 3389  
    Required firewalld configuration for remote desktop access

21. **freerdp Package Analysis**  
    RPM package contents verification  
    Confirms `winpr-makecert` utility provided by freerdp package

22. **grdctl Non-Interactive Usage**  
    Community documentation and testing  
    Non-interactive credential passing for automation

## Date
2024-07-11 (Initial)  
2025-07-11 (Updated with Python 3.11 compatibility research)  
2025-11-14 (Updated with RHEL 10 remote desktop architecture changes and SELinux blocker)

## Tags
rhel, rocky-linux, compatibility, versioning, package-management, python, operating-systems, python-311, ansible-core, rhel-10, wayland, xorg, remote-desktop, vnc, rdp, selinux, security
