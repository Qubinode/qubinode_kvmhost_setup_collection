# Variable Naming Conventions Reference

Complete reference for standardized variable naming conventions implementing ADR-0006 (Configuration Management Patterns).

## 📋 Naming Convention Standards

### 1. Role-Scoped Variables

All role-specific variables must be prefixed with the role name:

```yaml
# Pattern: <role_name>_<category>_<setting>
kvmhost_base_packages: []
kvmhost_networking_bridge_name: "qubibr0"
kvmhost_libvirt_storage_path: "/var/lib/libvirt/images"
kvmhost_cockpit_ssl_cert_path: "/etc/ssl/certs/cockpit.crt"
kvmhost_storage_pool_size: "100G"
```

### 2. Feature Toggle Variables

Boolean variables that enable/disable features:

```yaml
# Pattern: enable_<feature> or <role>_<feature>_enabled
enable_cockpit: true
enable_performance_optimization: false
kvmhost_base_epel_enabled: true
kvmhost_networking_validation_enabled: true
kvmhost_libvirt_nested_virt_enabled: false
```

### 3. Configuration Object Variables

Complex configuration as structured objects:

```yaml
# Pattern: <role>_<component>_config
kvmhost_networking_bridge_config:
  name: "qubibr0"
  stp: false
  forward_delay: 0
  hello_time: 1

kvmhost_libvirt_storage_config:
  pools:
    - name: default
      path: /var/lib/libvirt/images
      type: dir
    - name: ssd-pool
      path: /var/lib/libvirt/ssd
      type: dir
```

### 4. List Variables

Collections of items (always plural):

```yaml
# Pattern: <role>_<items> (plural)
kvmhost_base_packages:
  - curl
  - wget
  - git

kvmhost_libvirt_services:
  - libvirtd
  - virtlogd

kvmhost_networking_interfaces:
  - name: "ens3"
    type: "ethernet"
  - name: "ens4"
    type: "ethernet"
```

## 🏷️ Variable Categories

### System Configuration Variables
```yaml
# Operating system and hardware
kvm_host_os_family: "RedHat"
kvm_host_architecture: "x86_64"
kvm_host_cpu_features: ["vmx", "ept"]

# Network configuration
kvm_host_ipaddr: "192.168.1.100"
kvm_host_interface: "ens3"
kvm_host_gw: "192.168.1.1"
kvm_host_netmask: "255.255.255.0"
kvm_host_mask_prefix: 24
```

### Service Configuration Variables
```yaml
# Service management
<service>_enabled: true|false
<service>_state: started|stopped|restarted
<service>_autostart: true|false

# Examples
libvirtd_enabled: true
libvirtd_state: started
cockpit_socket_enabled: true
```

### Path and Directory Variables
```yaml
# Pattern: <role>_<component>_<path_type>
kvmhost_libvirt_images_dir: "/var/lib/libvirt/images"
kvmhost_cockpit_config_dir: "/etc/cockpit"
kvmhost_storage_mount_point: "/var/lib/libvirt"
kvmhost_base_log_dir: "/var/log/kvmhost"
```

### User and Permission Variables
```yaml
# User management
admin_user: "kvmadmin"
<role>_user: "service_user"
<role>_group: "service_group"

# Permission settings
<role>_file_mode: "0644"
<role>_dir_mode: "0755"
<role>_executable_mode: "0755"
```

## 🔧 Advanced Naming Patterns

### Conditional Variables
```yaml
# Pattern: <role>_<condition>_<setting>
kvmhost_base_rhel8_packages: ["package1", "package2"]
kvmhost_base_rhel9_packages: ["package3", "package4"]
kvmhost_networking_bridge_required: true
kvmhost_storage_lvm_available: false
```

### Environment-Specific Variables
```yaml
# Pattern: <role>_<environment>_<setting>
kvmhost_base_production_packages: ["monitoring", "security"]
kvmhost_base_development_packages: ["debug", "profiling"]
kvmhost_networking_test_validation: false
kvmhost_storage_production_performance: true
```

### Performance and Optimization Variables
```yaml
# Pattern: <role>_<performance|optimization>_<setting>
kvmhost_libvirt_performance_mode: "high"
kvmhost_networking_optimization_enabled: true
kvmhost_storage_performance_tuning: true
kvm_hugepages_percent: 25
kvm_cpu_governor: "performance"
```

## 📊 Variable Type Standards

### String Variables
```yaml
# Use descriptive names, avoid abbreviations
kvm_host_domain: "example.com"          # Good
kvm_host_dom: "example.com"             # Avoid

# Use consistent casing (snake_case)
bridge_interface_name: "qubibr0"        # Good
bridgeInterfaceName: "qubibr0"          # Avoid
```

### Boolean Variables
```yaml
# Use positive phrasing when possible
enable_feature: true                     # Good
disable_feature: false                   # Avoid when possible

# Use consistent patterns
<feature>_enabled: true                  # Good
<feature>_disabled: false                # Avoid
```

### Integer Variables
```yaml
# Use descriptive units in names
timeout_seconds: 30                      # Good
timeout: 30                              # Less clear

# Include reasonable defaults
connection_retries: 3
wait_timeout_seconds: 60
```

### List Variables
```yaml
# Always use plural names
packages: ["pkg1", "pkg2"]               # Good
package: ["pkg1", "pkg2"]                # Avoid

# Use consistent structure
services:
  - name: "service1"
    enabled: true
  - name: "service2"
    enabled: false
```

### Dictionary Variables
```yaml
# Use structured, hierarchical naming
network_config:
  bridge:
    name: "qubibr0"
    stp: false
  interface:
    name: "ens3"
    type: "ethernet"
```

## 🔍 Variable Validation Standards

### Input Validation Patterns
```yaml
# Required variable validation
- name: "Validate required variables are defined"
  ansible.builtin.assert:
    that:
      - admin_user is defined
      - admin_user | length > 0
    fail_msg: "admin_user must be defined and non-empty"

# Type validation
- name: "Validate variable types"
  ansible.builtin.assert:
    that:
      - kvm_host_mask_prefix is number
      - kvm_host_mask_prefix >= 1
      - kvm_host_mask_prefix <= 32
    fail_msg: "kvm_host_mask_prefix must be a number between 1 and 32"
```

### Format Validation
```yaml
# IP address validation
- name: "Validate IP address format"
  ansible.builtin.assert:
    that:
      - kvm_host_ipaddr | ansible.utils.ipaddr
    fail_msg: "kvm_host_ipaddr must be a valid IP address"

# Hostname validation
- name: "Validate hostname format"
  ansible.builtin.assert:
    that:
      - admin_user | regex_search('^[a-zA-Z][a-zA-Z0-9_-]*$')
    fail_msg: "admin_user must start with letter and contain only alphanumeric, underscore, or hyphen"
```

## 📝 Documentation Standards

### Variable Documentation Format
```yaml
# In defaults/main.yml
variable_name: default_value
# Type: string|boolean|integer|list|dict
# Required: true|false  
# Description: Detailed description of variable purpose
# Example: variable_name: "example_value"
# Version Added: 0.9.0
```

### README.md Variable Section
```markdown
## Role Variables

### Required Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| admin_user | string | Administrative user name | `admin_user: "kvmadmin"` |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| enable_cockpit | boolean | `true` | Enable Cockpit web interface |
```

## 🔄 Migration Guidelines

### Updating Existing Variables
1. **Identify non-compliant variables** in existing roles
2. **Create aliases** for backward compatibility
3. **Update documentation** to reflect new names
4. **Deprecate old names** with warnings
5. **Remove deprecated names** in next major version

### Example Migration
```yaml
# Old variable (deprecated)
bridge_name: "{{ qubinode_bridge_name | default('qubibr0') }}"

# New variable (compliant)
kvmhost_networking_bridge_name: "{{ bridge_name | default(qubinode_bridge_name) | default('qubibr0') }}"

# Deprecation warning
- name: "Warn about deprecated variable"
  ansible.builtin.debug:
    msg: "WARNING: 'bridge_name' is deprecated. Use 'kvmhost_networking_bridge_name' instead."
  when: bridge_name is defined
```

## 🔗 Related Documentation

- **Role Interfaces**: [Role Interface Standards](../apis/role-interfaces.md)
- **Configuration**: [Configuration Management](../../explanations/configuration-management.md)
- **ADR**: [ADR-0006 Configuration Patterns](../../explanations/architecture-decisions/adr-0006-configuration-patterns.md)
- **Examples**: [Variable Examples](../playbooks/variable-examples.md)

---

*This reference defines variable naming standards for the collection. For understanding the configuration philosophy, see the explanations section.*
