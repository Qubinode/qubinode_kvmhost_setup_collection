# KVM Host Base Configuration Role

## Overview

The `kvmhost_base` role provides foundational system configuration for KVM hosts running RHEL 9/10 and compatible distributions. This role implements ADR-0008 (RHEL 9/10 Support Strategy) and ADR-0001 (DNF Module for EPEL Installation).

## Features

- **OS Detection**: Automatic detection and validation of supported operating systems
- **Package Management**: Base package installation with DNF module support
- **Service Management**: Configure essential system services
- **System Preparation**: KVM-specific kernel modules and system parameters
- **EPEL Integration**: ADR-0001 compliant EPEL repository configuration

## Supported Platforms

- RHEL 8, 9, 10
- CentOS Stream 8, 9
- Rocky Linux 8, 9
- AlmaLinux 8, 9

## Dependencies

None. This is a foundational role.

## Role Variables

### Required Variables

None. All variables have sensible defaults.

### Optional Variables

```yaml
# System configuration
cicd_test: false                    # Enable test mode
testing_mode: false                 # Enable testing features

# Package management
enable_epel: true                   # Enable EPEL repository
epel_installation_method: "dnf_module"  # ADR-0001 compliant method

# Service configuration
base_services_enabled:             # Services to enable
  - NetworkManager
  - firewalld

base_services_started:             # Services to start
  - NetworkManager
  - firewalld
```

### Advanced Configuration

```yaml
# Custom package lists
base_packages_common:
  - curl
  - wget
  - git
  # ... additional packages

# Python packages
python_packages:
  - python3-pip
  - python3-virtualenv
  - python3-setuptools
```

## Example Playbook

```yaml
---
- hosts: kvm_hosts
  become: true
  roles:
    - role: kvmhost_base
      cicd_test: false
      enable_epel: true
```

## Role Interface

### Exported Facts

- `kvmhost_os_family`: Detected OS family (RedHat, CentOS, etc.)
- `kvmhost_os_major_version`: Major OS version (8, 9, 10)
- `kvmhost_is_rhel8/9/10`: Boolean flags for version detection
- `kvmhost_package_manager`: Package manager (dnf/yum)
- `kvmhost_python_executable`: Python executable path

### Completion Markers

- `/var/lib/kvmhost_base_prepared`: Created when role completes successfully

## Tags

- `base`: All base configuration tasks
- `os_detection`: OS detection and validation
- `packages`: Package management tasks
- `services`: Service management tasks
- `system_prep`: System preparation tasks

## Testing

```bash
# Test with Molecule
cd roles/kvmhost_base
molecule test

# Test with ansible-playbook
ansible-playbook -i inventory test-modular.yml --tags base
```

## Validation

The role includes comprehensive validation:

- OS family and version compatibility
- Architecture support (x86_64)
- Minimum memory requirements (2GB)
- Package installation verification
- Service status validation

## Troubleshooting

### Common Issues

1. **EPEL Installation Fails**
   - Ensure network connectivity
   - Check if running in container environment
   - Verify DNF is available

2. **Service Start Failures**
   - Check systemd is available (not in containers)
   - Verify service packages are installed
   - Review service logs: `journalctl -u <service>`

3. **Package Installation Errors**
   - Update package cache: `dnf clean all && dnf makecache`
   - Check repository configuration
   - Verify network connectivity

## Contributing

See the main project [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

GPL-3.0 - See [LICENSE](../../LICENSE) for details.
