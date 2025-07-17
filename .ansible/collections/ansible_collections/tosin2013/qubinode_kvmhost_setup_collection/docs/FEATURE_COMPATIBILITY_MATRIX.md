# Feature Compatibility Matrix

**Generated**: Mon Jul 14 12:01:51 UTC 2025
**Project**: Qubinode KVM Host Setup Collection
**Total Roles**: 1

## Overview

This matrix shows the compatibility of each role with different platforms, Ansible versions, and system requirements. Use this guide to determine which features are available for your target environment.

## Platform Compatibility

| Role | Description | RHEL 8 | RHEL 9 | RHEL 10 | Rocky 8 | Rocky 9 | AlmaLinux 8 | AlmaLinux 9 |
|------|-------------|:------:|:------:|:-------:|:-------:|:-------:|:-----------:|:-----------:|
| **swygue_lvm** | Create pv, vg, lv, filesystems then mounts and configures /etc/fstab. | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **edge_hosts_validate** | Validate the KVM deployment. | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **kvmhost_user_config** | Configures user shell environments, SSH access, and permissions for KVM hosts | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **kvmhost_setup** | This Ansible Collection for Virtual Machines Setup provides a set of roles
 for configuring and managing KVM hosts in baremetal servers using RHEL-based
 Linux operating systems. The collection includes roles for setting up the
 KVM environment, installing and configuring guest VMs, managing VM disks
 and networks, and more. Whether you are a system administrator, DevOps
 engineer, or cloud architect, this collection can help you automate your
 KVM host setup and management tasks, and improve the reliability and
 security of your virtualized environment. | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **kvmhost_cockpit** | Configure Cockpit web interface for KVM host management with SSL, authentication, and module integration | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |
| **kvmhost_networking** | KVM host network bridge configuration and validation | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |
| **kvmhost_libvirt** | Configure libvirt services, storage pools, and virtualization settings for KVM hosts | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |
| **kvmhost_storage** | Advanced storage management for KVM hosts including LVM, performance optimization, and monitoring | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |
| **kvmhost_base** | Base KVM host configuration and OS detection | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |

## Role Dependencies

| Role | Dependencies | Collections Required |
|------|--------------|---------------------|
| **kvmhost_storage** | kvmhost_base,kvmhost_libvirt | community.general,community.libvirt,ansible.posix |
| **kvmhost_base** | None | ansible.posix,community.general |
| **kvmhost_setup** | None | None |
| **swygue_lvm** | None | None |
| **kvmhost_networking** | kvmhost_base | ansible.posix,community.general |
| **kvmhost_user_config** | kvmhost_base | ansible.posix,community.general |
| **edge_hosts_validate** | None | None |
| **kvmhost_cockpit** | kvmhost_base,kvmhost_libvirt | fedora.linux_system_roles,ansible.posix |
| **kvmhost_libvirt** | kvmhost_base,kvmhost_networking | community.libvirt,ansible.posix |

## System Requirements

| Role | Min Ansible Version | Hardware Requirements |
|------|--------------------|-----------------------|
| **kvmhost_cockpit** | 2.9 | ## Requirements - **Dashboard**: System overview with CPU, memory, disk, and network usage  |
| **kvmhost_storage** | 2.9 | ## Requirements | **NVMe SSDs** | `none` | High-performance NVMe with hardware queuing |  |
| **kvmhost_user_config** | 2.12 | ## Requirements  |
| **kvmhost_setup** | 2.10 | Requirements  |
| **kvmhost_libvirt** | 2.9 | - Virtualization hardware validation ## Requirements - **Hardware**: VT-enabled CPU (configurable validation)  |
| **edge_hosts_validate** | 2.10 | Requirements  |
| **kvmhost_base** | 2.9 | - Minimum memory requirements (2GB)  |
| **swygue_lvm** | 2.10 | Requirements  |
| **kvmhost_networking** | 2.9 | ### Input Requirements  |

## Feature Support Matrix

| Feature Category | kvmhost_base | kvmhost_networking | kvmhost_libvirt | kvmhost_storage | kvmhost_cockpit | kvmhost_user_config |
|------------------|:------------:|:-----------------:|:---------------:|:---------------:|:---------------:|:--------------------:|
| **OS Detection** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Package Management** | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ |
| **Network Bridges** | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **KVM/Libvirt** | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Storage Management** | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **Web UI** | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| **User Configuration** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Performance Tuning** | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| **Security Hardening** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## Usage Recommendations

### Typical Deployment Scenarios

#### **Minimal KVM Host** (RHEL/Rocky/AlmaLinux 8+)
- ✅ kvmhost_base (OS detection and base packages)
- ✅ kvmhost_networking (basic bridge configuration)
- ✅ kvmhost_libvirt (KVM virtualization)

#### **Production KVM Host** (RHEL/Rocky/AlmaLinux 9+)
- ✅ kvmhost_base
- ✅ kvmhost_networking
- ✅ kvmhost_libvirt
- ✅ kvmhost_storage (advanced storage management)
- ✅ kvmhost_cockpit (web management interface)

#### **Enterprise KVM Host** (RHEL 9/10)
- ✅ All roles for complete feature set
- ✅ Enhanced security and compliance features
- ✅ Performance optimization

### Migration Notes

- **RHEL 7 → RHEL 8+**: Requires role updates due to networking changes
- **RHEL 8 → RHEL 9**: Fully supported, no breaking changes
- **RHEL 9 → RHEL 10**: Supported with conditional logic
- **CentOS → Rocky/AlmaLinux**: Direct migration supported

---

**Note**: This matrix is automatically generated from role metadata. For the most current information, refer to individual role documentation.

**Last Updated**: Mon Jul 14 12:01:51 UTC 2025
**Generated by**: `scripts/generate-compatibility-matrix.sh`

