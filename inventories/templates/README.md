# Environment-Specific Variable Templates

## Overview

This directory contains standardized configuration templates for different deployment environments, implementing ADR-0006 (Configuration Management Patterns). These templates maintain compatibility with the original Qubinode KVM Host Setup Collection specifications while providing environment-specific optimizations.

## Available Templates

### 1. Development Environment (`all-development.yml`)
**Purpose**: Local development and testing
**Characteristics**:
- Relaxed validation and security settings
- Debugging features enabled
- Faster setup with reduced timeouts
- Additional development packages (minimal additions to original spec)
- Bridge name: `devbr0`

### 2. Staging Environment (`all-staging.yml`)  
**Purpose**: Pre-production testing and validation
**Characteristics**:
- Production-like configuration with moderate resources
- Full validation enabled
- Monitoring and alerting active
- Bridge name: `stagbr0`
- Domain: `staging.example.com`

### 3. Production Environment (`all-production.yml`)
**Purpose**: Live production deployments
**Characteristics**:
- Maximum security and validation
- Full resource allocation
- Comprehensive monitoring and backup
- Original package specifications maintained
- Bridge name: `qubibr0` (original spec)

## Original Package Specifications Maintained

All templates preserve the original package requirements from `roles/kvmhost_setup/defaults/main.yml`:

### Core KVM/Libvirt Packages
```yaml
required_rpm_packages:
  - virt-install
  - libvirt-daemon-config-network
  - libvirt-daemon-kvm
  - libguestfs-tools
  - libvirt-client
  - qemu-kvm
  - libvirt-daemon
  - virt-top
  - tuned
```

### System Administration Tools
```yaml
  - openssh-server
  - wget
  - bc
  - git
  - net-tools
  - bind-utils
  - dnf-utils
  - firewalld
  - bash-completion
  - kexec-tools
  - sos
  - psacct
  - vim
  - httpd-tools
  - tmux
```

### Container and Monitoring Tools
```yaml
  - podman
  - container-selinux
  - k9s
  - cockpit-machines
  - nmap
  - lm_sensors
```

### Python Ecosystem
```yaml
  - python3-dns
  - python3-pip
  - python3-lxml
  - python3-netaddr

# Python packages (from vars/main.yml)
kvmhost_pip_packages:
  - httpie      # Command line HTTP client
  - tldr        # Simplified man pages
  - kube-shell  # Kubernetes shell
  - openshift   # OpenShift CLI
```

## Usage Instructions

### 1. Copy Template to Inventory

```bash
# For development environment
cp inventories/templates/group_vars/all-development.yml \
   inventories/dev/group_vars/all.yml

# For staging environment  
cp inventories/templates/group_vars/all-staging.yml \
   inventories/staging/group_vars/all.yml

# For production environment
cp inventories/templates/group_vars/all-production.yml \
   inventories/prod/group_vars/all.yml
```

### 2. Customize for Your Environment

Edit the copied file and customize:

```yaml
# Environment-specific settings
admin_user: "your-admin-user"
domain: "your-domain.com"
kvm_host_domain: "your-domain.com"

# Network settings
qubinode_bridge_name: "your-bridge-name"
kvm_host_interface: "eth0"  # Your primary interface

# DNS settings
dns_forwarder: "your-dns-server"
```

### 3. Inventory Structure

Create environment-specific inventories:

```
inventories/
├── templates/              # Template files (don't modify)
│   └── group_vars/
│       ├── all-development.yml
│       ├── all-staging.yml
│       └── all-production.yml
├── dev/                    # Development inventory
│   ├── hosts
│   └── group_vars/
│       └── all.yml         # Copied and customized from template
├── staging/               # Staging inventory
│   ├── hosts
│   └── group_vars/
│       └── all.yml
└── prod/                  # Production inventory
    ├── hosts
    └── group_vars/
        └── all.yml
```

## Variable Naming Conventions

All templates follow the standardized naming conventions from ADR-0006:

### Role-Scoped Variables
```yaml
kvmhost_base_epel_enabled: true
kvmhost_networking_bridge_name: "qubibr0"
kvmhost_libvirt_autostart: true
```

### Feature Toggles
```yaml
enable_cockpit: true           # Original variable (maintained)
kvmhost_cockpit_enabled: true  # New standardized variable
```

### Configuration Objects
```yaml
kvmhost_networking_bridge_config:
  method: "auto"
  dhcp_timeout: 30
```

## Legacy Compatibility

All templates maintain backward compatibility with original variables:

```yaml
# Original variables are preserved
lib_virt_setup: true
enable_cockpit: true
configure_shell: true

# New variables provide enhanced functionality
kvmhost_libvirt_enabled: "{{ lib_virt_setup }}"
kvmhost_cockpit_enabled: "{{ enable_cockpit }}"
kvmhost_user_config_enabled: "{{ configure_shell }}"
```

## Environment Differences

| Setting | Development | Staging | Production |
|---------|-------------|---------|------------|
| **Bridge Name** | `devbr0` | `stagbr0` | `qubibr0` |
| **Memory Min** | 1GB | 2GB | 4GB |
| **VM Memory** | 2GB | 4GB | 8GB |
| **VM Disk** | 20GB | 50GB | 100GB |
| **Validation** | Relaxed | Full | Strict |
| **Backup** | Disabled | Enabled | Enabled |
| **SSL/TLS** | Disabled | Enabled | Enabled |
| **SELinux** | Permissive | Enforcing | Enforcing |
| **Alerts** | Disabled | Enabled | Enabled |
| **Debug** | Enabled | Disabled | Disabled |

## Host-Specific Overrides

Create host-specific variables in `host_vars/hostname.yml`:

```yaml
# host_vars/kvm-host-01.yml
admin_user: "admin"
kvm_host_interface: "enp1s0"
qubinode_bridge_name: "br-kvm01"

# Host-specific storage
kvm_host_libvirt_dir: "/storage/kvm-host-01/images"

# Host-specific network
kvm_host_ip: "192.168.1.10"
kvm_host_netmask: "255.255.255.0"
kvm_host_gw: "192.168.1.1"
```

## Validation and Testing

### Environment Validation

Each template includes environment-appropriate validation:

```yaml
# Development: Relaxed validation
kvmhost_base_validation_memory_minimum: 1024
skip_production_validations: true

# Production: Strict validation  
kvmhost_base_validation_memory_minimum: 4096
skip_production_validations: false
```

### Testing Different Environments

```bash
# Test development configuration
ansible-playbook -i inventories/dev site.yml --check

# Test staging configuration
ansible-playbook -i inventories/staging site.yml --check

# Test production configuration
ansible-playbook -i inventories/prod site.yml --check
```

## Best Practices

### 1. Environment Separation
- Never use production credentials in development
- Use different bridge names per environment
- Separate storage paths and domains

### 2. Configuration Management
- Version control all environment configurations
- Use Ansible Vault for sensitive data
- Document environment-specific changes

### 3. Testing Strategy
- Test changes in development first
- Validate in staging before production
- Use `--check` mode for dry runs

### 4. Security Considerations
- Enable SSL/TLS in staging and production
- Use enforcing SELinux in non-development environments
- Configure appropriate firewall rules

## Troubleshooting

### Common Issues

1. **Variable Conflicts**
   - Check for duplicate variable definitions
   - Verify variable precedence order
   - Use `ansible-inventory --list` to check resolved variables

2. **Environment Mismatch**
   - Verify correct template was used
   - Check environment_name variable
   - Validate inventory structure

3. **Legacy Compatibility**
   - Ensure both old and new variable names are set
   - Check deprecation warnings in playbook output
   - Update playbooks gradually to use new variables

## Migration from Legacy Configuration

### Step 1: Backup Current Configuration
```bash
cp inventories/hosts inventories/hosts.backup
cp -r inventories/group_vars inventories/group_vars.backup
```

### Step 2: Choose Appropriate Template
Select based on your environment type and copy the template.

### Step 3: Migrate Variables
Transfer your existing customizations to the new template format.

### Step 4: Test and Validate
Run in check mode and validate all functionality works as expected.

This environment template system provides a standardized, maintainable approach to configuration management while preserving the original Qubinode specifications and ensuring compatibility across all deployment scenarios.
