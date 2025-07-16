# KVM Host Networking Configuration Role

## Overview

The `kvmhost_networking` role provides automated network bridge configuration for KVM hosts. This role implements ADR-0007 (Network Architecture Decisions) with modern NetworkManager-based bridge setup.

## Features

- **Automated Bridge Creation**: NetworkManager-based bridge configuration
- **Interface Detection**: Automatic primary interface detection
- **Network Validation**: Comprehensive connectivity testing
- **Configuration Backup**: Optional backup of existing network settings
- **Bridge Validation**: Post-configuration validation and reporting

## Supported Platforms

- RHEL 8, 9, 10 with NetworkManager
- CentOS Stream 8, 9 with NetworkManager
- Rocky Linux 8, 9 with NetworkManager
- AlmaLinux 8, 9 with NetworkManager

## Dependencies

- `kvmhost_base`: Provides OS detection and basic system preparation
- NetworkManager service must be available and running

## Role Variables

### Required Variables

None. All variables have sensible defaults.

### Core Configuration

```yaml
# Bridge configuration
qubinode_bridge_name: "qubibr0"    # Bridge interface name
qubinode_bridge_interface: ""      # Specific interface (auto-detect if empty)

# Network detection
auto_detect_interface: true        # Auto-detect primary interface
force_bridge_creation: false       # Force recreation if exists

# Backup settings
backup_existing_config: true       # Backup network config before changes
```

### Advanced Configuration

```yaml
# Bridge interface settings
bridge_interface_settings:
  stp: false                       # Spanning Tree Protocol
  forward_delay: 0                 # Forward delay in seconds
  hello_time: 2                    # Hello time in seconds
  max_age: 20                      # Max age in seconds
  priority: 32768                  # Bridge priority

# Network validation
network_validation_enabled: true   # Enable post-config validation
validation_timeout: 60             # Validation timeout in seconds
ping_test_hosts:                   # Hosts to test connectivity
  - "8.8.8.8"
  - "1.1.1.1"

# Firewall integration
configure_firewall_for_bridge: true
firewall_zone: "public"
```

## Example Playbook

```yaml
---
- hosts: kvm_hosts
  become: true
  roles:
    - role: kvmhost_base
    - role: kvmhost_networking
      qubinode_bridge_name: "kvmbr0"
      network_validation_enabled: true
      backup_existing_config: true
```

## Role Interface

### Input Requirements

- NetworkManager must be installed and running
- Primary network interface must be available
- Sufficient privileges for network configuration

### Exported Facts

- `primary_interface`: Detected or specified primary interface
- `primary_ip`: Primary interface IP address
- `primary_gateway`: Primary interface gateway
- `bridge_already_exists`: Boolean indicating if bridge pre-exists

### Generated Files

- `/tmp/network_backup_<timestamp>.txt`: Network configuration backup
- `/tmp/network_validation_<timestamp>.txt`: Validation report

## Tags

- `networking`: All networking tasks
- `network_preflight`: Pre-flight checks
- `interface_detection`: Interface detection tasks
- `bridge_config`: Bridge configuration tasks
- `network_validation`: Validation tasks

## Testing

```bash
# Test with Molecule (requires privileged containers)
cd roles/kvmhost_networking
molecule test

# Test with ansible-playbook
ansible-playbook -i inventory test-modular.yml --tags networking
```

## Validation

The role performs comprehensive validation:

- NetworkManager service status
- nmcli command availability
- Bridge utilities presence
- Interface existence and configuration
- Post-configuration connectivity tests

## Bridge Configuration Process

1. **Pre-flight Checks**: Validate NetworkManager and dependencies
2. **Interface Detection**: Identify primary network interface
3. **Configuration Backup**: Save existing network configuration
4. **Bridge Creation**: Create bridge using NetworkManager
5. **Interface Binding**: Add primary interface as bridge slave
6. **Network Validation**: Test connectivity and generate report

## Troubleshooting

### Common Issues

1. **NetworkManager Not Available**
   ```bash
   sudo systemctl start NetworkManager
   sudo systemctl enable NetworkManager
   ```

2. **Bridge Creation Fails**
   - Check if bridge already exists: `nmcli connection show`
   - Verify interface is not in use: `nmcli device status`
   - Check permissions: ensure running with sudo/become

3. **Network Connectivity Lost**
   - Restore from backup: check `/tmp/network_backup_*.txt`
   - Restart NetworkManager: `sudo systemctl restart NetworkManager`
   - Check bridge status: `ip link show <bridge_name>`

4. **Container/VM Limitations**
   - Bridge configuration may not work in Docker containers
   - Use `force_bridge_creation: false` for testing
   - Disable validation in constrained environments

### Debugging

Enable debugging with:
```yaml
enable_network_debugging: true
network_debug_level: "debug"
```

## Migration from Legacy

If migrating from the monolithic `kvmhost_setup` role:

1. Review existing bridge configuration
2. Set appropriate variables to match current setup
3. Use `backup_existing_config: true` for safety
4. Test in non-production environment first

## Contributing

See the main project [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

GPL-3.0 - See [LICENSE](../../LICENSE) for details.
