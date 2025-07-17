# ADR-0008: RHEL 9 and RHEL 10 Support Strategy

## Status
Accepted - Updated with 2025 Research Findings

## Context
The Qubinode project currently targets RHEL-based systems but needs to ensure compatibility with newer versions of Red Hat Enterprise Linux, specifically RHEL 9 and RHEL 10. These newer versions introduce:

- Updated package management (dnf as default)
- New system service management approaches
- Updated virtualization stack (libvirt, KVM)
- Modified security policies and SELinux contexts
- Changes in default networking configurations
- Updated Python runtime (Python 3.9+ in RHEL 9, Python 3.11+ in RHEL 10)
- Enhanced Ansible compatibility requirements (see [Python 3.11 Compatibility Research](../research/rhel9-python311-ansible-compatibility-2025.md))

The project must maintain backward compatibility while leveraging improvements in newer RHEL versions.

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
| OS Version | Support Level | Default Python | Available Python | Package Manager | Ansible-core Compatibility |
|------------|---------------|----------------|------------------|-----------------|----------------------------|
| RHEL 8.x   | Limited*      | Python 3.6     | 3.6, 3.8, 3.9, 3.11 | DNF         | 2.16 LTS (requires Python 3.11 for 2.17+) |
| RHEL 9.x   | Full Support  | Python 3.9     | 3.9, 3.11, 3.12 | DNF             | 2.17, 2.18 (recommended) |
| Rocky 8.x  | Limited*      | Python 3.6     | 3.6, 3.8, 3.9, 3.11 | DNF         | 2.16 LTS (requires Python 3.11 for 2.17+) |
| Rocky 9.x  | Full Support  | Python 3.9     | 3.9, 3.11, 3.12 | DNF             | 2.17, 2.18 (recommended) |
| RHEL 10.x  | Early Support | Python 3.12    | 3.12, 3.13      | DNF             | 2.18+ |

*Limited support due to Python 3.6 EOL and Ansible compatibility constraints

### Testing Strategy
- CI/CD pipeline tests against multiple OS versions
- Molecule scenarios for each supported version
- Regular testing with CentOS Stream and Rocky Linux

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

## Date
2024-07-11 (Initial)  
2025-07-11 (Updated with Python 3.11 compatibility research)

## Tags
rhel, rocky-linux, compatibility, versioning, package-management, python, operating-systems, python-311, ansible-core
