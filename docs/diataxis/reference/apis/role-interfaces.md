# Role Interface Standards Reference

Complete reference for role interface standards, implementing ADR-0002 (Ansible Role-Based Modular Architecture).

## 📋 Interface Standards Overview

Every role in the collection must follow standardized interface patterns to ensure:
- **Consistency**: Predictable interfaces across all roles
- **Interoperability**: Roles can work together seamlessly
- **Maintainability**: Clear contracts for role interactions
- **Testability**: Standardized testing approaches

## 🏷️ Role Metadata Standards

### Required meta/main.yml Structure
```yaml
galaxy_info:
  author: "Qubinode Project"
  description: "Clear, concise role description"
  company: "Red Hat"
  license: "GPL-3.0"
  min_ansible_version: "2.13"
  platforms:
    - name: EL
      versions: ["8", "9", "10"]
  galaxy_tags:
    - kvm
    - libvirt
    - virtualization
  
dependencies: []  # Explicit dependency list

collections:      # Required collections
  - ansible.posix
  - community.general
  - community.libvirt  # if using libvirt
```

### Platform Support Declaration
```yaml
platforms:
  - name: EL  # Enterprise Linux
    versions: 
      - "8"    # RHEL 8, Rocky 8, AlmaLinux 8
      - "9"    # RHEL 9, Rocky 9, AlmaLinux 9
      - "10"   # RHEL 10 (when available)
```

## 🔧 Variable Interface Standards

### Variable Naming Conventions

#### Feature Toggles (Boolean)
```yaml
# Pattern: enable_<feature>
enable_cockpit: true
enable_performance_optimization: false
configure_bridge: true
lib_virt_setup: true
```

#### Configuration Objects
```yaml
# Pattern: <role>_config
kvmhost_networking_config:
  bridge_name: "qubibr0"
  interface: "ens3"
  validation_enabled: true

kvmhost_storage_config:
  pool_name: "default"
  pool_path: "/var/lib/libvirt/images"
  performance_mode: "high"
```

#### List Configurations
```yaml
# Pattern: <role>_<type>s
kvmhost_base_packages:
  - curl
  - wget
  - git

kvmhost_libvirt_services:
  - libvirtd
  - virtlogd
```

#### Role-Specific Variables
```yaml
# Pattern: <role_name>_<setting>
kvmhost_networking_bridge_name: "qubibr0"
kvmhost_storage_pool_size: "100G"
kvmhost_cockpit_ssl_enabled: true
```

### Variable Documentation Format
```yaml
variable_name:
  type: string|boolean|integer|list|dict
  required: true|false
  default: default_value
  description: "Detailed description of the variable"
  choices: [option1, option2, option3]  # if applicable
  version_added: "0.9.0"
  examples:
    - value: example_value
      description: "When to use this value"
```

## 📤 Output Interface Standards

### Facts Provided by Roles

#### Standard Fact Pattern
```yaml
# Pattern: <role>_<fact_type>
<role>_configured: true|false
<role>_version: "version_string"
<role>_status: "status_description"
<role>_features: ["feature1", "feature2"]
```

#### Example Role Facts
```yaml
# kvmhost_base role facts
kvmhost_base_configured: true
kvmhost_base_os_detected: "rhel9"
kvmhost_base_packages_installed: ["curl", "wget", "git"]

# kvmhost_networking role facts  
kvmhost_networking_configured: true
kvmhost_networking_bridge_created: "qubibr0"
kvmhost_networking_interface_enslaved: "ens3"

# kvmhost_libvirt role facts
kvmhost_libvirt_configured: true
kvmhost_libvirt_daemon_running: true
kvmhost_libvirt_networks: ["qubinet"]
```

### Handler Interface Standards

#### Handler Naming Convention
```yaml
# Pattern: <action> <service/component>
handlers:
  - name: restart libvirtd
    ansible.builtin.systemd:
      name: libvirtd
      state: restarted

  - name: reload NetworkManager
    ansible.builtin.systemd:
      name: NetworkManager
      state: reloaded

  - name: restart cockpit
    ansible.builtin.systemd:
      name: cockpit.socket
      state: restarted
```

## 🏗️ Task Interface Standards

### Task Naming Convention
```yaml
# Pattern: <Action> <object> [for <purpose>]
tasks:
  - name: "Install libvirt packages for KVM host setup"
  - name: "Configure network bridge for VM connectivity"
  - name: "Create storage pool for VM disk images"
  - name: "Validate KVM hardware features"
```

### Task Organization
```yaml
# Main task file structure
tasks/main.yml:
  - include_tasks: validate_variables.yml
    tags: [always, validation]
    
  - include_tasks: install_packages.yml
    tags: [packages, installation]
    
  - include_tasks: configure_service.yml
    tags: [configuration, service]
    
  - include_tasks: validate_configuration.yml
    tags: [validation, verification]
```

### Tag Standards
```yaml
# Standard tags for all roles
tags:
  - always          # Tasks that always run
  - validation      # Variable and system validation
  - packages        # Package installation
  - configuration   # Service/feature configuration
  - verification    # Post-configuration validation
  - <role_name>     # Role-specific tag
```

## 🔄 Dependency Interface Standards

### Dependency Declaration
```yaml
# In meta/main.yml
dependencies:
  - role: kvmhost_base
    when: kvmhost_base_required | default(true)
    
  - role: kvmhost_networking
    when: configure_bridge | default(true)
```

### Inter-Role Communication
```yaml
# Roles communicate through facts
- name: "Set role completion fact"
  ansible.builtin.set_fact:
    kvmhost_networking_configured: true
    kvmhost_networking_bridge_name: "{{ qubinode_bridge_name }}"

# Dependent roles check facts
- name: "Configure libvirt network"
  when: kvmhost_networking_configured | default(false)
```

## 🧪 Testing Interface Standards

### Molecule Configuration Standards
```yaml
# Standard molecule.yml structure
dependency:
  name: galaxy
  options:
    requirements-file: requirements.yml

driver:
  name: podman

platforms:
  - name: instance
    image: registry.redhat.io/ubi9-init:latest
    dockerfile: ../default/Dockerfile.rhel
    pre_build_image: false
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro

provisioner:
  name: ansible
  config_options:
    defaults:
      callback_whitelist: profile_tasks, timer

verifier:
  name: testinfra
```

### Test Interface Standards
```python
# Standard test file structure
def test_role_configured(host):
    """Test that role completed successfully."""
    # Check service status
    service = host.service("service_name")
    assert service.is_running
    assert service.is_enabled

def test_configuration_files(host):
    """Test that configuration files are created correctly."""
    config = host.file("/etc/service/config.conf")
    assert config.exists
    assert config.contains("expected_setting")

def test_role_facts(host):
    """Test that role sets expected facts."""
    # This would be tested through Ansible fact gathering
    pass
```

## 📚 Documentation Interface Standards

### README.md Structure
```markdown
# Role Name

Brief description of role purpose.

## Requirements

- Ansible version requirements
- System requirements
- Dependencies

## Role Variables

Comprehensive variable documentation.

## Dependencies

List of role dependencies.

## Example Playbook

Working example of role usage.

## License

License information.

## Author Information

Author and maintainer information.
```

### Variable Documentation Format
```yaml
# In defaults/main.yml - document each variable
variable_name: default_value  # Description of variable purpose and usage
```

## 🔒 Security Interface Standards

### Security Variable Patterns
```yaml
# Security-sensitive variables
<role>_ssl_enabled: true
<role>_auth_required: true
<role>_secure_defaults: true

# Security configuration objects
<role>_security_config:
  ssl_cert_path: "/etc/ssl/certs/service.crt"
  ssl_key_path: "/etc/ssl/private/service.key"
  auth_method: "pam"
```

### Security Task Patterns
```yaml
- name: "Configure SSL certificates for secure communication"
  ansible.builtin.copy:
    src: "{{ item.src }}"
    dest: "{{ item.dest }}"
    mode: "{{ item.mode }}"
    owner: "{{ item.owner }}"
  loop:
    - {src: "cert.pem", dest: "/etc/ssl/certs/", mode: "0644", owner: "root"}
    - {src: "key.pem", dest: "/etc/ssl/private/", mode: "0600", owner: "root"}
  notify: restart service
```

## 🔗 Related Documentation

- **Architecture**: [Modular Role Design](../../explanations/modular-role-design.md)
- **Variables**: [Variable Naming Conventions](../standards/variable-naming.md)
- **Testing**: [Testing Framework](../testing/test-scenarios.md)
- **ADR**: [ADR-0002 Modular Architecture](../../explanations/architecture-decisions/adr-0002-modular-architecture.md)

---

*This reference defines the interface standards for all roles. For understanding the design philosophy, see the explanations section.*
