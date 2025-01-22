# kvmhost_setup Role

The kvmhost_setup role is the core component of the Qubinode KVM Host Setup Collection. It handles the complete configuration of KVM virtualization hosts.

## Role Tasks

### Main Tasks
- **bridge_interface.yml**: Configures network bridge interfaces
- **cockpit_setup.yml**: Installs and configures Cockpit web interface
- **libvirt_setup.yml**: Configures Libvirt virtualization
- **storage_pool.yml**: Creates and manages storage pools
- **user_libvirt.yml**: Configures user access to Libvirt
- **validate.yml**: Validates system requirements

### Configuration Tasks
- **cockpit.yml**: Cockpit specific configuration
- **remote.yml**: Remote access configuration
- **shell.yml**: User shell environment setup

## Role Variables

### Required Variables
```yaml
kvm_host_interface: "eth0"
kvm_bridge_name: "br0"
```

### Optional Variables
```yaml
cockpit_enabled: true
libvirt_user: "kvmuser"
storage_pools:
  - name: "default"
    type: "dir"
    target: "/var/lib/libvirt/images"
```

## Example Playbook

```yaml
- hosts: kvm_hosts
  roles:
    - role: kvmhost_setup
      vars:
        kvm_host_interface: "eth0"
        kvm_bridge_name: "br0"
        cockpit_enabled: true
        storage_pools:
          - name: "default"
            type: "dir"
            target: "/var/lib/libvirt/images"
```

## Dependencies

- python3-libvirt
- cockpit
- bridge-utils

## Tags

Available tags for selective execution:
- `network`: Network configuration tasks
- `cockpit`: Cockpit setup tasks
- `libvirt`: Libvirt configuration tasks
- `storage`: Storage pool tasks
- `validation`: System validation tasks

## Testing

To test the role:
```bash
molecule test
