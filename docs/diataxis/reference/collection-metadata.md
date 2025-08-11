# Collection Metadata Reference

Complete reference for the Qubinode KVM Host Setup Collection metadata, versioning, and distribution information.

## 📦 Collection Information

### Basic Metadata
```yaml
namespace: tosin2013
name: qubinode_kvmhost_setup_collection
version: "0.9.7"
description: >
  This Ansible Collection for Virtual Machines Setup provides a set of roles 
  for configuring and managing KVM hosts in baremetal servers using RHEL-based 
  Linux operating systems.
```

### Authors and Maintainers
```yaml
authors:
  - Tosin Akinosho (github.com/tosin2013)
  - Rodrique Heron (github.com/flyemsafe)
```

### Repository Information
```yaml
repository: https://github.com/Qubinode/qubinode_kvmhost_setup_collection
homepage: https://github.com/Qubinode/qubinode_kvmhost_setup_collection
issues: https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues
```

### Licensing
```yaml
license_file: LICENSE
license: GNU General Public License v3.0 or later
```

## 🏷️ Tags and Classification

### Galaxy Tags
```yaml
tags:
  - kvm          # KVM virtualization
  - libvirt      # Libvirt management
  - kvmhost      # KVM host configuration
  - linux        # Linux systems
```

### Search Keywords
- KVM virtualization
- Libvirt management
- RHEL automation
- Virtual machine setup
- Bare metal configuration

## 📋 Version Information

### Current Version
- **Version**: 0.9.7
- **Release Date**: Latest release information available in [CHANGELOG.rst](../../../CHANGELOG.rst)
- **Stability**: Production-ready

### Version History
| Version | Release Date | Major Changes |
|---------|--------------|---------------|
| 0.9.7   | 2025-01-XX   | Current stable release |
| 0.9.6   | 2024-XX-XX   | Previous release |
| 0.9.5   | 2024-XX-XX   | Previous release |

### Semantic Versioning
- **MAJOR**: Breaking changes, incompatible API changes
- **MINOR**: New features, backward-compatible functionality
- **PATCH**: Bug fixes, documentation updates, dependency updates

## 🔧 Build Configuration

### Build Ignore Patterns
```yaml
build_ignore:
  - .gitignore
  - changelogs/.plugin-cache.yaml
```

### Included Files
The collection includes:
- `README.md` - Collection overview and usage
- `LICENSE` - License information
- `ansible.cfg` - Ansible configuration
- `galaxy.yml` - Collection metadata
- `meta/runtime.yml` - Runtime requirements
- `roles/` - All role implementations
- `inventories/` - Example inventories
- `docs/` - Documentation

### Excluded Files
The following are excluded from distribution:
- `.git/` - Git repository data
- `.github/` - GitHub-specific files
- `tests/` - Development tests
- `molecule/` - Testing configurations
- `scripts/` - Development scripts
- `node_modules/` - Node.js dependencies

## 🎯 Runtime Requirements

### Ansible Version Support
```yaml
# From meta/runtime.yml
requires_ansible: ">=2.13.0"
```

### Supported Ansible Versions
- **Minimum**: 2.13.0
- **Tested**: 2.13, 2.14, 2.15, 2.16, 2.17
- **Recommended**: 2.17 (latest stable)

### Python Version Support
- **Minimum**: Python 3.9
- **Tested**: Python 3.9, 3.10, 3.11
- **Recommended**: Python 3.11

## 🔗 Dependencies

### Collection Dependencies
```yaml
# From requirements.yml
collections:
  - name: community.libvirt
    version: ">=1.3.0"
  - name: ansible.posix
    version: ">=1.5.0"
  - name: community.general
    version: ">=7.0.0"
```

### System Dependencies
- **libvirt**: Virtualization management
- **qemu-kvm**: KVM hypervisor
- **NetworkManager**: Network management
- **podman** or **docker**: Container runtime (for testing)

## 📊 Collection Statistics

### Content Overview
- **Roles**: 9 total roles
  - 6 core KVM setup roles
  - 2 validation roles
  - 1 LVM management role
- **Playbooks**: Multiple example playbooks
- **Modules**: No custom modules (uses community collections)
- **Plugins**: No custom plugins

### Role Breakdown
| Role | Purpose | Dependencies |
|------|---------|--------------|
| kvmhost_setup | Main orchestration | All other roles |
| kvmhost_base | Base system setup | None |
| kvmhost_libvirt | Libvirt configuration | kvmhost_base |
| kvmhost_networking | Network bridge setup | kvmhost_base |
| kvmhost_storage | Storage management | kvmhost_base, kvmhost_libvirt |
| kvmhost_cockpit | Web interface | kvmhost_base, kvmhost_libvirt |
| kvmhost_user_config | User environment | kvmhost_base |
| edge_hosts_validate | System validation | None |
| swygue_lvm | LVM management | None |

## 🌐 Distribution Information

### Ansible Galaxy
- **Namespace**: tosin2013
- **Collection Name**: qubinode_kvmhost_setup_collection
- **Galaxy URL**: https://galaxy.ansible.com/tosin2013/qubinode_kvmhost_setup_collection

### Installation Methods
```bash
# From Ansible Galaxy
ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection

# From Git repository
ansible-galaxy collection install git+https://github.com/Qubinode/qubinode_kvmhost_setup_collection.git

# From local source
ansible-galaxy collection install .

# Specific version
ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection:==0.9.7
```

### Requirements File Format
```yaml
# requirements.yml
---
collections:
  - name: tosin2013.qubinode_kvmhost_setup_collection
    version: ">=0.9.0"
    source: https://galaxy.ansible.com
```

## 🔄 Update and Upgrade Information

### Upgrade Process
```bash
# Upgrade to latest version
ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection --upgrade

# Check installed version
ansible-galaxy collection list | grep qubinode

# Verify upgrade
ansible-doc tosin2013.qubinode_kvmhost_setup_collection.kvmhost_setup
```

### Breaking Changes
Check [CHANGELOG.rst](../../../CHANGELOG.rst) for:
- Variable name changes
- Role interface modifications
- Deprecated features
- Migration instructions

### Compatibility Matrix
| Collection Version | Ansible Version | Python Version | RHEL Version |
|-------------------|-----------------|----------------|--------------|
| 0.9.x             | 2.13+          | 3.9+          | 8, 9, 10     |
| 0.8.x             | 2.12+          | 3.8+          | 8, 9         |
| 0.7.x             | 2.11+          | 3.8+          | 8, 9         |

## 📈 Release Information

### Release Channels
- **Stable**: Tagged releases on main branch
- **Development**: Latest commits on main branch
- **Feature Branches**: Experimental features

### Release Frequency
- **Patch Releases**: Weekly (dependency updates, bug fixes)
- **Minor Releases**: Monthly (new features, enhancements)
- **Major Releases**: Quarterly (breaking changes, major features)

### Automated Releases
The collection uses automated release workflows:
- **Dependabot**: Automatic dependency updates
- **Auto-release**: Triggered by dependency merges
- **Manual Release**: For feature releases

## 🔒 Security Information

### Security Policy
- Security vulnerabilities reported via GitHub Security Advisories
- Regular security scanning with Bandit and other tools
- Dependency vulnerability monitoring with Dependabot

### Supported Security Features
- SELinux compatibility
- Firewall integration
- Secure defaults
- Permission management
- Audit logging

## 📞 Support Information

### Community Support
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and community support
- **Documentation**: Comprehensive guides and references

### Commercial Support
- Available through Red Hat Ansible Automation Platform
- Professional services available through partners

### Response Times
- **Critical Issues**: 24-48 hours
- **Bug Reports**: 3-5 business days
- **Feature Requests**: 1-2 weeks
- **Documentation**: 1 week

## 🔗 Related Documentation

- **Installation**: [Installation Methods](installation-methods.md)
- **Compatibility**: [Supported Platforms](supported-platforms.md)
- **Requirements**: [System Requirements](system-requirements.md)
- **Changelog**: [CHANGELOG.rst](../../../CHANGELOG.rst)

---

*This reference provides complete collection metadata information. For specific role details, see the individual role reference pages.*
