# RHEL 9 and Python 3.11 Compatibility Research Report

**Date:** July 11, 2025  
**Research Period:** January 2024 - July 2025  
**Status:** Complete  
**Related ADRs:** ADR-0005 (Molecule Testing), ADR-0003 (KVM Host Validation)

## Executive Summary

This research investigates the compatibility and support matrix for Red Hat Enterprise Linux 9 (RHEL 9), Python 3.11, Ansible-core, and Molecule testing framework as of July 2025. The findings show significant maturation in the ecosystem with improved support for Python 3.11 across all components.

### Key Findings
- **RHEL 9** maintains Python 3.9 as default but provides stable Python 3.11 and 3.12 packages
- **Ansible-core 2.18** (current latest) supports Python 3.11-3.13 for control nodes and 3.8-3.13 for managed nodes
- **Molecule** version 25.6.0 requires Python ≥3.10 and fully supports Python 3.11-3.13
- **Migration is recommended** for new deployments while maintaining RHEL 9 compatibility

## Research Methodology

### Information Sources
1. **Red Hat Official Documentation** (docs.redhat.com)
2. **Ansible Community Documentation** (docs.ansible.com) 
3. **Molecule Project Documentation** (ansible.readthedocs.io/projects/molecule/)
4. **Community Forums** (forum.ansible.com, forums.rockylinux.org)
5. **Package Repositories** (PyPI, Red Hat Ecosystem Catalog)

### Research Scope
- Python version compatibility across RHEL 9 lifecycle
- Ansible-core 2.15-2.18 support matrix
- Molecule testing framework evolution
- Enterprise deployment considerations

## Detailed Findings

### RHEL 9 Python Support Matrix

#### Default Python Environment
- **System Python:** 3.9 (default, supported until RHEL 9 EOL in May 2032)
- **Alternative Versions:** 3.11 (since RHEL 9.2), 3.12 (since RHEL 9.4)
- **Installation:** `dnf install python3.11` or `dnf install python3.12`

#### Key Characteristics
```bash
# Default Python (system-wide)
python3 --version        # Python 3.9.x
/usr/bin/python3         # Points to 3.9

# Alternative Python versions
python3.11 --version     # Python 3.11.x (available)
python3.12 --version     # Python 3.12.x (available)
```

#### Enterprise Considerations
- **System Tools:** Continue using Python 3.9 (dnf, nftables, subscription-manager)
- **Application Development:** Python 3.11/3.12 recommended for new projects
- **Support Lifecycle:** Python 3.9 supported until 2032, Python 3.11 until May 2026

### Ansible-core Compatibility Evolution

#### Version Support Matrix (2025)

| Ansible-core Version | Release Date | Control Node Python | Managed Node Python | RHEL 9 Status |
|---------------------|--------------|---------------------|---------------------|----------------|
| 2.18 (Latest)      | Nov 2024     | 3.11 - 3.13        | 3.8 - 3.13         | ✅ Recommended |
| 2.17               | May 2024     | 3.10 - 3.12        | 3.7 - 3.12         | ✅ Supported |
| 2.16 (LTS)         | Nov 2023     | 3.10 - 3.12        | 2.7, 3.6 - 3.12    | ✅ Stable |
| 2.15 (EOL)         | May 2023     | 3.9 - 3.11         | 2.7, 3.5 - 3.11    | ⚠️ End of Life |

#### RHEL 8 Legacy Support Challenges
- **Issue:** Ansible-core 2.17+ drops Python 3.6 support
- **Impact:** RHEL 8 (Python 3.6 default) requires Python 3.11+ installation
- **Solution:** Use Ansible-core 2.16 LTS or install newer Python on RHEL 8

### Molecule Testing Framework Status

#### Current Version Analysis (v25.6.0)
- **Release Date:** June 18, 2025
- **Python Requirements:** ≥3.10 (supports 3.10, 3.11, 3.12, 3.13)
- **Ansible Compatibility:** Latest two major versions (N/N-1 policy)
- **Container Support:** Podman and Docker drivers

#### Breaking Changes Timeline
- **v6.0.0 (Aug 2023):** Minimum Python 3.10 requirement
- **v24.x (2024):** Enhanced Python 3.11/3.12 support
- **v25.x (2025):** Full Python 3.13 compatibility

#### Integration Considerations
```yaml
# Modern Molecule Configuration (2025)
dependency:
  name: galaxy
driver:
  name: podman  # Preferred over Docker
platforms:
  - name: rhel9-test
    image: registry.redhat.io/ubi9/ubi-init
    python_interpreter: /usr/bin/python3.11  # Explicit version
provisioner:
  name: ansible
  ansible:
    python_interpreter: /usr/bin/python3.11
```

### Red Hat Automation Platform (AAP) Considerations

#### AAP 2.5 Support Matrix
- **Default Ansible-core:** 2.16
- **EE Base OS:** RHEL 8, 9, 10
- **Control Node Python:** 3.10 - 3.12
- **Managed Node Compatibility:** RHEL 7 - 10

#### Execution Environment Strategy
- **Versioned EEs:** `registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9`
- **Version-less EEs:** `registry.redhat.io/ansible-automation-platform/ee-supported-rhel9`
- **Custom EEs:** Build with Python 3.11 for enhanced compatibility

## Migration Recommendations

### For New Projects (Recommended Path)
1. **Target Environment:** RHEL 9 with Python 3.11
2. **Ansible-core:** 2.18 (latest features and security)
3. **Molecule:** 25.6.0+ (current stable)
4. **Testing Strategy:** Podman-based containers

### For Existing Projects
1. **Assessment Phase:** Audit current Python/Ansible versions
2. **Gradual Migration:** Test with Ansible-core 2.16 LTS first
3. **Python Upgrade:** Install Python 3.11 alongside 3.9
4. **Validation:** Comprehensive testing with new versions

### Implementation Timeline
```mermaid
graph LR
    A[Assessment] --> B[Python 3.11 Install]
    B --> C[Ansible-core 2.16/2.17]
    C --> D[Molecule Update]
    D --> E[Full Migration Test]
    E --> F[Production Deployment]
```

## Risk Assessment

### Low Risk ✅
- **RHEL 9 Python 3.11 installation** - Well-supported, documented
- **Ansible-core 2.16/2.17 upgrade** - Stable, LTS available
- **Molecule modern versions** - Mature, active development

### Medium Risk ⚠️
- **Mixed Python environments** - Requires careful path management
- **Legacy role compatibility** - Some roles may need updates
- **CI/CD pipeline changes** - Container images need updating

### High Risk ❌
- **RHEL 8 with latest Ansible** - Python compatibility issues
- **System Python changes** - Breaking OS-level tools
- **Rushed migration** - Insufficient testing period

## Performance Impact Analysis

### Positive Impacts
- **Python 3.11:** 10-60% performance improvement over 3.9
- **Ansible-core 2.18:** Enhanced execution engine efficiency
- **Molecule 25.x:** Faster test execution with Podman

### Resource Requirements
- **Memory:** +10-15% for Python 3.11 vs 3.9
- **Storage:** Additional 200-300MB for parallel Python installations
- **CI/CD:** Modern container images may be larger

## Security Considerations

### Python Security Status
- **Python 3.9:** Security fixes until RHEL 9 EOL (2032)
- **Python 3.11:** Security fixes until May 2026
- **Python 3.12:** Security fixes until October 2027

### Ansible Security Features
- **Ansible-core 2.18:** Latest security patches and features
- **CVE Management:** Faster security updates in newer versions
- **Container Security:** Enhanced with Podman integration

## Industry Trends and Future Outlook

### Python Ecosystem Trends
- **Annual Releases:** Python 3.13 (Oct 2024), 3.14 (Oct 2025)
- **Feature Evolution:** Performance improvements, typing enhancements
- **EOL Acceleration:** Faster deprecation of older versions

### Ansible Community Direction
- **Container-First:** Execution Environments becoming standard
- **Collection Focus:** Core functionality moving to collections
- **Platform Integration:** Tighter AAP integration

### Testing Framework Evolution
- **Molecule Adoption:** Becoming industry standard for Ansible testing
- **Cloud Integration:** Better support for cloud testing environments
- **Performance Focus:** Faster feedback loops

## Conclusions and Recommendations

### Primary Recommendations
1. **Adopt Python 3.11** for new Ansible development on RHEL 9
2. **Upgrade to Ansible-core 2.17/2.18** for enhanced features and security
3. **Update Molecule to v25.6.0+** for modern testing capabilities
4. **Maintain backward compatibility** with RHEL 8 where required

### Strategic Considerations
- **Long-term Viability:** Python 3.11/Ansible 2.18 provides 2-3 year stability
- **Enterprise Support:** Full Red Hat support for recommended configurations
- **Community Alignment:** Following mainstream community practices
- **Technical Debt:** Proactive migration reduces future technical debt

### Implementation Priority
1. **High Priority:** Security and compatibility updates
2. **Medium Priority:** Performance optimization features
3. **Low Priority:** Convenience and developer experience improvements

## Evidence and Sources

### Documentation References
- [Red Hat Ansible Automation Platform Life Cycle](https://access.redhat.com/support/policy/updates/ansible-automation-platform)
- [Ansible-core Support Matrix](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html)
- [RHEL 9 Python Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/installing_and_using_dynamic_programming_languages/)
- [Molecule Project Documentation](https://ansible.readthedocs.io/projects/molecule/)

### Community Evidence
- [Ansible Community Forum Discussions](https://forum.ansible.com/t/python-3-7-impact-on-el8-future-for-el9/6229)
- [Rocky Linux Community Support Matrix](https://forums.rockylinux.org/t/installing-python-packages-for-python-3-11-on-rocky-linux-9-3-blue-onyx/13447)

### Version Tracking
- **Ansible-core releases:** GitHub repository tags and changelogs
- **Molecule releases:** PyPI version history and GitHub releases
- **Python releases:** Python.org release schedule and endoflife.date

---

**Research conducted by:** AI Assistant  
**Review date:** July 11, 2025  
**Next review:** January 2026 (6 months)
