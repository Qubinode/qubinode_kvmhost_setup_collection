# ADR-0003: KVM Virtualization Platform Selection

## Status
Implemented

> **Review Note (2026-01-25)**: ADR compliance review confirmed full implementation with
> 9/10 compliance score. KVM/libvirt is the established virtualization platform with
> complete automation for host setup, networking, and storage configuration.

## Context
The Qubinode project requires a virtualization platform to host OpenShift clusters and associated infrastructure components on bare metal servers. The solution needs to provide:

- High performance virtualization with minimal overhead
- Strong security isolation between virtual machines
- Compatibility with RHEL-based Linux operating systems
- Cost-effective solution without licensing restrictions
- Good integration with Linux ecosystem and tooling
- Support for both single-node and multi-node deployments

## Decision
Selected KVM (Kernel-based Virtual Machine) as the primary virtualization platform for the Qubinode project. KVM will be managed through libvirt APIs and tools, providing a standardized interface for VM lifecycle management.

## Alternatives Considered
1. **VMware vSphere/ESXi** - Enterprise virtualization platform
   - Pros: Mature, feature-rich, strong enterprise support
   - Cons: Expensive licensing, proprietary, less Linux-native integration

2. **VirtualBox** - Desktop virtualization solution  
   - Pros: Free, cross-platform, easy to use
   - Cons: Not designed for production server workloads, limited performance

3. **Hyper-V** - Microsoft virtualization platform
   - Pros: Good Windows integration, included with Windows Server
   - Cons: Less suitable for Linux-centric environments, licensing costs

4. **Xen** - Bare-metal hypervisor
   - Pros: High performance, good isolation
   - Cons: More complex setup, smaller community compared to KVM

## Consequences

### Positive
- **Cost-effective**: KVM is open-source and included in Linux kernel, no licensing fees
- **High performance**: Near-native performance leveraging hardware virtualization extensions (Intel VT-x/AMD-V)
- **Strong security**: Provides robust isolation between guest VMs and host system using SELinux and hardware features
- **Linux integration**: Excellent integration with RHEL/Rocky Linux ecosystem
- **Community support**: Large, active community with extensive documentation and tools
- **Scalability**: Supports large numbers of VMs and can scale for enterprise deployments
- **Standardized management**: libvirt provides consistent API and tooling across different hypervisors
- **Hardware compatibility**: Works with standard x86_64 hardware with virtualization extensions

### Negative
- **Learning curve**: Requires understanding of KVM/libvirt concepts and CLI tools
- **Limited GUI tools**: Fewer graphical management options compared to commercial solutions
- **Hardware requirements**: Requires CPU virtualization extensions (VT-x/AMD-V)
- **Complex networking**: Advanced networking configurations can be complex to set up and troubleshoot

## Implementation
- KVM kernel modules enabled and configured on target hosts
- libvirt daemon (libvirtd) installed and configured for VM management
- Virtual machine definitions stored as libvirt XML configurations
- Network bridges configured for VM connectivity
- Storage pools configured for VM disk images
- Integration with Ansible roles for automated setup and management

## Evidence
- `roles/kvmhost_setup/` role contains KVM/libvirt configuration tasks
- libvirt network and storage pool templates in `templates/` directory
- VM configuration management through libvirt XML definitions
- Bridge networking setup for VM connectivity

## Date
2024-07-11

## Tags
virtualization, kvm, libvirt, infrastructure, performance, security
