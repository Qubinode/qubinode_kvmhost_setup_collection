# Standardized Variable Naming Conventions

## Overview

This document defines the standardized variable naming conventions for the Qubinode KVM Host Setup Collection, implementing ADR-0006 (Configuration Management Patterns).

## Naming Convention Standards

### 1. Role-Scoped Variables

All role-specific variables must be prefixed with the role name:

```yaml
# Pattern: <role_name>_<category>_<setting>
kvmhost_base_packages: []
kvmhost_networking_bridge_name: "qubibr0"
kvmhost_libvirt_storage_path: "/var/lib/libvirt/images"
```

### 2. Feature Toggle Variables

Boolean variables that enable/disable features:

```yaml
# Pattern: enable_<role>_<feature> or <role>_<feature>_enabled
enable_kvmhost_networking: true
kvmhost_base_epel_enabled: true
kvmhost_cockpit_ssl_enabled: false
```

### 3. Configuration Object Variables

Complex configuration as structured objects:

```yaml
# Pattern: <role>_<component>_config
kvmhost_networking_bridge_config:
  name: "qubibr0"
  stp: false
  forward_delay: 0

kvmhost_libvirt_storage_config:
  pools:
    - name: default
      path: /var/lib/libvirt/images
```

### 4. List Variables

Collections of items (always plural):

```yaml
# Pattern: <role>_<type>s
kvmhost_base_packages:
  - curl
  - wget
  - git

kvmhost_networking_interfaces:
  - eth0
  - eth1

kvmhost_libvirt_networks:
  - default
  - isolated
```

### 5. Path Variables

File and directory paths:

```yaml
# Pattern: <role>_<component>_<type>_path
kvmhost_base_config_dir_path: "/etc/kvmhost"
kvmhost_libvirt_storage_pool_path: "/var/lib/libvirt/images"
kvmhost_cockpit_ssl_cert_path: "/etc/cockpit/ws-certs.d"
```

### 6. Service Variables

Service-related configuration:

```yaml
# Pattern: <role>_<service>_<setting>
kvmhost_base_networkmanager_enabled: true
kvmhost_base_firewalld_enabled: true
kvmhost_libvirt_libvirtd_autostart: true
```

### 7. Validation Variables

Validation and testing configuration:

```yaml
# Pattern: <role>_validation_<setting>
kvmhost_networking_validation_enabled: true
kvmhost_networking_validation_timeout: 60
kvmhost_base_validation_skip_memory_check: false
```

## Legacy Variable Migration

### Current Issues in Legacy Role

The existing `kvmhost_setup` role has inconsistent naming:

```yaml
# Inconsistent prefixes
lib_virt_setup: true           # Should be: kvmhost_libvirt_enabled
enable_cockpit: true           # Should be: kvmhost_cockpit_enabled
configure_shell: true          # Should be: kvmhost_user_config_enabled

# Mixed naming patterns
kvm_host_libvirt_dir: "/path"  # Mix of kvm_host and specific setting
kvmhost_bridge_device: "br0"  # Good: role-prefixed
qubinode_bridge_name: "qubibr0" # Inconsistent: project vs role prefix

# Unclear scope
admin_user: "user"             # Should be: kvmhost_user_config_admin_user
domain: "example.com"          # Should be: kvmhost_base_domain
```

### Migration Strategy

#### Phase 1: New Roles (Implemented)

New modular roles use consistent naming:

```yaml
# kvmhost_base role
kvmhost_base_epel_enabled: true
kvmhost_base_packages_common: []
kvmhost_base_services_enabled: []

# kvmhost_networking role  
kvmhost_networking_bridge_name: "qubibr0"
kvmhost_networking_auto_detect_interface: true
kvmhost_networking_validation_enabled: true
```

#### Phase 2: Legacy Compatibility

Provide backward compatibility with deprecation warnings:

```yaml
# Legacy variable support with warnings
- name: "Handle legacy lib_virt_setup variable"
  ansible.builtin.set_fact:
    kvmhost_libvirt_enabled: "{{ lib_virt_setup }}"
  when: 
    - lib_virt_setup is defined
    - kvmhost_libvirt_enabled is not defined

- name: "Deprecation warning for lib_virt_setup"
  ansible.builtin.debug:
    msg: "WARNING: lib_virt_setup is deprecated. Use kvmhost_libvirt_enabled instead."
  when: lib_virt_setup is defined
```

#### Phase 3: Complete Migration

Update all references and remove legacy support.

## Variable Categories by Role

### kvmhost_base

```yaml
# Feature toggles
kvmhost_base_epel_enabled: true
kvmhost_base_testing_mode: false

# Package management
kvmhost_base_packages_common: []
kvmhost_base_packages_rhel_family: []
kvmhost_base_python_packages: []

# Service management
kvmhost_base_services_enabled: []
kvmhost_base_services_started: []

# OS configuration
kvmhost_base_supported_os_families: []
kvmhost_base_supported_major_versions: []

# Validation settings
kvmhost_base_validation_memory_minimum: 2048
kvmhost_base_validation_skip_arch_check: false
```

### kvmhost_networking

```yaml
# Bridge configuration
kvmhost_networking_bridge_name: "qubibr0"
kvmhost_networking_bridge_type: "Bridge"
kvmhost_networking_auto_detect_interface: true

# Network settings
kvmhost_networking_bridge_config:
  method: "auto"
  dhcp_timeout: 30
  ipv4_method: "auto"

# Validation configuration
kvmhost_networking_validation_enabled: true
kvmhost_networking_validation_timeout: 60
kvmhost_networking_ping_test_hosts: []

# Feature toggles
kvmhost_networking_backup_existing_config: true
kvmhost_networking_firewall_integration: true
```

### kvmhost_libvirt (Planned)

```yaml
# Service configuration
kvmhost_libvirt_enabled: true
kvmhost_libvirt_services: []
kvmhost_libvirt_autostart: true

# Storage configuration
kvmhost_libvirt_storage_pools: []
kvmhost_libvirt_storage_default_path: "/var/lib/libvirt/images"

# Network configuration
kvmhost_libvirt_networks: []
kvmhost_libvirt_default_network_enabled: true

# User management
kvmhost_libvirt_admin_users: []
kvmhost_libvirt_group_name: "libvirt"
```

## Environment-Specific Variables

### Development Environment

```yaml
# Pattern: <role>_<env>_<setting>
kvmhost_base_dev_debug_enabled: true
kvmhost_networking_dev_skip_validation: true
kvmhost_libvirt_dev_unsafe_permissions: true
```

### Production Environment

```yaml
kvmhost_base_prod_security_hardening: true
kvmhost_networking_prod_backup_required: true
kvmhost_libvirt_prod_resource_limits: true
```

### Testing Environment

```yaml
kvmhost_base_test_mode: true
kvmhost_networking_test_bridge_name: "testbr0"
kvmhost_libvirt_test_storage_path: "/tmp/libvirt-test"
```

## Variable Validation

### Type Validation

```yaml
- name: "Validate variable types"
  ansible.builtin.assert:
    that:
      - kvmhost_base_epel_enabled is boolean
      - kvmhost_networking_bridge_name is string
      - kvmhost_base_packages_common is sequence
    fail_msg: "Variable type validation failed"
```

### Value Validation

```yaml
- name: "Validate enum values"
  ansible.builtin.assert:
    that:
      - kvmhost_networking_bridge_config.method in ['auto', 'static', 'dhcp']
    fail_msg: "Invalid bridge method"

- name: "Validate numeric ranges"
  ansible.builtin.assert:
    that:
      - kvmhost_networking_validation_timeout >= 30
      - kvmhost_networking_validation_timeout <= 300
    fail_msg: "Timeout must be between 30-300 seconds"
```

### Required Variable Validation

```yaml
- name: "Validate required variables"
  ansible.builtin.assert:
    that:
      - kvmhost_networking_bridge_name is defined
      - kvmhost_networking_bridge_name | length > 0
    fail_msg: "Bridge name is required"
```

## Documentation Standards

### Variable Documentation Format

Each variable must be documented with:

```yaml
# Variable: kvmhost_networking_bridge_name
# Type: string
# Required: true
# Default: "qubibr0"
# Description: Name of the bridge interface to create
# Values: Valid network interface name (e.g., "br0", "kvmbr0")
# Example: "testbr0"
kvmhost_networking_bridge_name: "qubibr0"

# Variable: kvmhost_base_epel_enabled  
# Type: boolean
# Required: false
# Default: true
# Description: Enable EPEL repository installation
# Values: true (enable), false (disable)
# Note: Required for additional packages on RHEL
kvmhost_base_epel_enabled: true
```

### Inventory Examples

#### Host Variables (host_vars/hostname.yml)

```yaml
# Host-specific overrides
kvmhost_networking_bridge_name: "br-{{ inventory_hostname_short }}"
kvmhost_libvirt_storage_default_path: "/storage/{{ inventory_hostname }}/libvirt"
```

#### Group Variables (group_vars/kvm_hosts.yml)

```yaml
# Common configuration for KVM host group
kvmhost_base_epel_enabled: true
kvmhost_networking_validation_enabled: true
kvmhost_libvirt_autostart: true

# Environment-specific bridge configuration
kvmhost_networking_bridge_config:
  method: "static"
  ipv4_method: "manual"
```

## Implementation Guidelines

### 1. Variable Naming Checklist

- [ ] Starts with role name prefix
- [ ] Uses underscore separation
- [ ] Descriptive and unambiguous
- [ ] Follows category pattern
- [ ] No abbreviations (unless standard)
- [ ] Consistent with similar variables

### 2. Deprecation Process

1. **Identify legacy variable**
2. **Create new standardized variable**
3. **Add compatibility mapping**
4. **Issue deprecation warning**
5. **Update documentation**
6. **Remove after 2 major releases**

### 3. Testing Requirements

All variable changes must include:

- [ ] Type validation tests
- [ ] Value range tests  
- [ ] Required variable tests
- [ ] Legacy compatibility tests
- [ ] Documentation updates

## Benefits

### Consistency

- Predictable variable names across all roles
- Easier to understand and remember
- Reduced cognitive load for developers

### Maintainability

- Clear ownership and scope
- Easier refactoring and updates
- Reduced variable conflicts

### Documentation

- Self-documenting variable names
- Consistent documentation patterns
- Better IDE/editor support

### Automation

- Automated validation possible
- Template generation easier
- Better tooling integration

This standardization improves code quality, reduces errors, and enhances the developer experience across the entire collection.
