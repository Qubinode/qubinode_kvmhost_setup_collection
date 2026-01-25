# ADR-0007: Network Architecture Decisions

## Status
Implemented

> **Review Note (2026-01-25)**: ADR compliance review confirmed full implementation with
> 9/10 compliance score. Bridge-based networking architecture is fully operational
> with custom bridge configuration, NAT networks, and DNS management templates.

## Context
The Qubinode project requires a robust networking architecture to support KVM virtualization, OpenShift cluster deployment, and host connectivity. The networking solution must provide:

- Isolated network segments for different workloads
- Bridge networking for VM connectivity to external networks
- NAT networking for internal cluster communication
- DNS resolution for service discovery
- Scalable network management across multiple hosts
- Security isolation between different network segments

The default libvirt networking (virbr0) is insufficient for production OpenShift deployments that require custom network configurations and external connectivity.

## Decision
Implement a bridge-based networking architecture with the following components:

1. **Custom Bridge Network** (`qubibr0`) - Primary bridge for VM external connectivity
2. **NAT Networks** - Isolated networks for internal cluster communication  
3. **Host Bridge Integration** - Bridge connected to host physical interface
4. **DNS Configuration** - Custom DNS settings for proper name resolution
5. **Network Templates** - Standardized libvirt network definitions

## Alternatives Considered
1. **Default libvirt NAT networking** - Using only virbr0 default network
   - Pros: Simple setup, works out-of-the-box
   - Cons: Limited external connectivity, not suitable for production OpenShift

2. **Host networking** - VMs directly use host network interfaces
   - Pros: Maximum performance, simple network path
   - Cons: No network isolation, potential IP conflicts, security concerns

3. **OVS (Open vSwitch)** - Software-defined networking with advanced features
   - Pros: Advanced networking features, flow control, monitoring
   - Cons: Additional complexity, not required for current use case

4. **MacVLAN networking** - VMs get direct access to physical network
   - Pros: Good performance, direct network access
   - Cons: Limited host-to-VM communication, DHCP complications

## Consequences

### Positive
- **External connectivity** - VMs can communicate with external networks and internet
- **Network isolation** - Separate networks for different workload types
- **OpenShift compatibility** - Proper networking for OpenShift cluster requirements
- **Scalable design** - Can support multiple hosts and network segments
- **Performance** - Bridge networking provides good performance characteristics
- **Flexibility** - Can accommodate various networking requirements
- **Standard tooling** - Uses standard libvirt/Linux networking tools

### Negative
- **Configuration complexity** - More network configuration to manage
- **Host dependencies** - Requires proper host network interface configuration
- **Troubleshooting** - More network layers to debug when issues occur
- **Bridge management** - Additional network interfaces to monitor and maintain

## Implementation

### Network Components
- **Primary Bridge**: `qubibr0` connected to host physical interface
- **NAT Networks**: Custom networks for cluster-internal communication
- **DNS Configuration**: Custom nameservers (1.1.1.1, 8.8.8.8) with local domain
- **Network Templates**: XML templates for consistent network definitions

### Configuration Variables
```yaml
qubinode_bridge_name: qubibr0
kvm_host_interface: "{{ ansible_default_ipv4.interface }}"
kvm_host_gw: "{{ ansible_default_ipv4.gateway }}"
kvm_host_domain: "lab.example"
dns_servers: ["1.1.1.1", "8.8.8.8"]
```

### Network Templates
- `libvirt_net_bridge.xml.j2` - Bridge network definition
- `nat_network.xml.j2` - NAT network configuration
- `resolv.conf.j2` - DNS resolver configuration

### Network Architecture
```
Physical Network
       |
[Host Interface] ── [qubibr0 Bridge]
                           |
                    [VM Interfaces]
                           |
                    [OpenShift Nodes]
```

## Evidence
- Bridge configuration tasks in `roles/kvmhost_setup/tasks/bridge_interface.yml`
- Network templates in `roles/kvmhost_setup/templates/`
- Network variable definitions in role defaults and vars
- DNS configuration management in resolver templates

## Date
2024-07-11

## Tags
networking, libvirt, bridge, virtualization, openshift, connectivity, dns
