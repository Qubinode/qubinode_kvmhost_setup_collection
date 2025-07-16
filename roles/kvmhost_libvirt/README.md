# kvmhost_libvirt

Configure libvirt services, storage pools, and virtualization settings for KVM hosts.

## Description

This role is part of the Qubinode KVM Host Setup Collection's modular architecture (ADR-0002). It provides comprehensive libvirt configuration including:

- Libvirt service management and tuned profile optimization
- Storage pool creation and management
- Virtual network configuration (bridge, NAT, isolated modes)
- User access control and permissions
- Virtualization hardware validation

## Requirements

- **Dependencies**: `kvmhost_base`, `kvmhost_networking` (configurable)
- **Collections**: `community.libvirt`, `ansible.posix`
- **Minimum Ansible**: 2.9
- **Hardware**: VT-enabled CPU (configurable validation)

## Role Variables

### Service Configuration
```yaml
kvmhost_libvirt_enabled: true
kvmhost_libvirt_autostart: true
kvmhost_libvirt_services:
  - libvirtd
  - tuned
kvmhost_libvirt_tuned_profile: "virtual-host"
```

### Storage Pools
```yaml
kvmhost_libvirt_storage_enabled: true
kvmhost_libvirt_storage_pools:
  - name: default
    state: active
    autostart: true
    path: "/var/lib/libvirt/images"
    type: "dir"
```

### Virtual Networks
```yaml
kvmhost_libvirt_networks_enabled: true
kvmhost_libvirt_networks:
  - name: "vmnetbr0"
    create: true
    mode: bridge  # bridge, nat, isolated
    bridge_name: "vmbr0"
    autostart: true
```

### User Access
```yaml
kvmhost_libvirt_user_access_enabled: true
kvmhost_libvirt_admin_group: "libvirt"
kvmhost_libvirt_admin_users: []
kvmhost_libvirt_unix_sock_group: "libvirt"
kvmhost_libvirt_unix_sock_rw_perms: "0770"
```

### Validation
```yaml
kvmhost_libvirt_validation_enabled: true
kvmhost_libvirt_skip_vt_check: false
```

## Dependencies

This role depends on:
- `kvmhost_base` - for base system configuration
- `kvmhost_networking` - for bridge network setup

Dependencies can be disabled by setting:
```yaml
kvmhost_libvirt_require_base: false
kvmhost_libvirt_require_networking: false
```

## Example Playbook

### Basic Usage
```yaml
- hosts: kvm_hosts
  roles:
    - kvmhost_libvirt
```

### Advanced Configuration
```yaml
- hosts: kvm_hosts
  vars:
    kvmhost_libvirt_admin_users:
      - developer
      - admin
    kvmhost_libvirt_storage_pools:
      - name: default
        path: "/var/lib/libvirt/images"
        state: active
        autostart: true
      - name: ssd-storage
        path: "/mnt/ssd/libvirt"
        state: active
        autostart: true
    kvmhost_libvirt_networks:
      - name: production
        mode: bridge
        bridge_name: "br0"
      - name: development
        mode: nat
        autostart: false
  roles:
    - kvmhost_libvirt
```

### CI/CD Testing Mode
```yaml
- hosts: test_hosts
  vars:
    cicd_test: true
    kvmhost_libvirt_skip_vt_check: true
  roles:
    - kvmhost_libvirt
```

## Network Modes

### Bridge Mode
- Uses existing physical bridge
- VMs get direct network access
- Requires bridge configuration

### NAT Mode  
- Creates isolated network with NAT
- VMs access network through host
- Automatic DHCP configuration

### Isolated Mode
- Creates isolated network without external access
- VMs can communicate with each other only
- Automatic DHCP within network

## Storage Pool Types

### Directory Pools
```yaml
- name: default
  type: dir
  path: "/var/lib/libvirt/images"
```

### Network Storage (planned)
```yaml
- name: nfs-storage
  type: netfs
  source_host: "storage.example.com"
  source_path: "/exports/libvirt"
```

## User Access Management

The role configures libvirt for non-root access by:
1. Adding users to the `libvirt` group
2. Configuring unix socket permissions
3. Setting appropriate group ownership

Users must log out and back in for group changes to take effect.

## Validation and Testing

### Hardware Validation
- VT (Virtualization Technology) capability check
- KVM kernel module verification
- Storage path validation

### Service Validation
- Libvirt daemon connectivity
- Storage pool status verification
- Network configuration validation

### Skip Validation
```yaml
kvmhost_libvirt_skip_vt_check: true  # Skip VT check
cicd_test: true                      # Skip all hardware checks
```

## Legacy Compatibility

The role maintains compatibility with original kvmhost_setup variables:
```yaml
# Legacy variables are mapped automatically
lib_virt_setup: true
enable_libvirt_admin_user: true
kvm_host_group: "libvirt"
create_libvirt_storage: true
```

## Troubleshooting

### Common Issues

1. **VT Disabled**: Enable virtualization in BIOS/UEFI
2. **Permission Denied**: User needs to be in libvirt group
3. **Storage Path Missing**: Role auto-creates missing directories
4. **Bridge Not Found**: Ensure kvmhost_networking role ran first

### Debug Mode
```yaml
kvmhost_libvirt_debug_enabled: true
```

### Testing Libvirt Access
```bash
# Test as regular user
virsh version
virsh list --all
```

## Integration

This role integrates with:
- **kvmhost_base**: System prerequisites
- **kvmhost_networking**: Bridge configuration  
- **kvmhost_storage**: Advanced storage management
- **kvmhost_cockpit**: Web UI management

## Performance Tuning

The role applies the `virtual-host` tuned profile for optimal virtualization performance. Additional tuning can be configured through:
```yaml
kvmhost_libvirt_memory_overcommit: false
kvmhost_libvirt_cpu_overcommit: false
```

## License

Apache-2.0

## Author Information

Qubinode Community - Part of the Qubinode KVM Host Setup Collection
