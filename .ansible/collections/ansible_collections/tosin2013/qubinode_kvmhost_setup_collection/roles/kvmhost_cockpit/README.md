# kvmhost_cockpit

This role configures Cockpit web management interface for KVM hosts, providing a modern web-based interface for system administration and virtualization management.

## Description

The `kvmhost_cockpit` role installs and configures Cockpit, a web-based server management interface that provides:

- Web-based system administration
- Virtual machine management through libvirt
- Real-time system monitoring
- User and group management
- Storage management
- Network configuration
- Logs and journal viewing

## Requirements

- RHEL/CentOS/Rocky/AlmaLinux 8 or newer
- systemd-based system
- Python 3.6 or newer
- ansible-core 2.12 or newer

## Role Dependencies

This role has dependencies on:
- `kvmhost_base` (implied through role_config.yml)

Optional integration with:
- `kvmhost_libvirt` (for enhanced VM management)
- `kvmhost_networking` (for network interface management)

## Variables

### Core Configuration

```yaml
# Enable/disable the entire role
kvmhost_cockpit_enabled: true

# Network configuration
kvmhost_cockpit_port: 9090
kvmhost_cockpit_listen_address: ""  # Empty = all interfaces

# SSL configuration
kvmhost_cockpit_ssl_enabled: true
kvmhost_cockpit_ssl_generate_self_signed: true
kvmhost_cockpit_ssl_cert_path: ""
kvmhost_cockpit_ssl_key_path: ""
```

### Package Configuration

```yaml
# Core Cockpit packages
kvmhost_cockpit_packages:
  - cockpit
  - cockpit-system
  - cockpit-ws

# Additional modules
kvmhost_cockpit_additional_packages:
  - cockpit-machines  # VM management
  - cockpit-storaged  # Storage management
  - cockpit-networkmanager  # Network management
  - cockpit-podman    # Container management
```

### Authentication and Access

```yaml
# Authentication methods
kvmhost_cockpit_auth_methods:
  - password
  - certificate

# User access control
kvmhost_cockpit_allowed_users: []
kvmhost_cockpit_admin_users: []
kvmhost_cockpit_default_access: "allow"

# Session configuration
kvmhost_cockpit_session_timeout: 900
kvmhost_cockpit_max_sessions: 10
kvmhost_cockpit_max_login_attempts: 3
kvmhost_cockpit_login_timeout: 300
```

### Firewall Configuration

```yaml
# Firewall management
kvmhost_cockpit_firewall_enabled: true
kvmhost_cockpit_firewall_zone: "public"

# Access restrictions
kvmhost_cockpit_restrict_access: false
kvmhost_cockpit_allowed_ips: []

# Custom firewall rules
kvmhost_cockpit_firewall_rich_rules: []
```

### Advanced Configuration

```yaml
# Service configuration
kvmhost_cockpit_max_startups: 10
kvmhost_cockpit_idle_timeout: 900
kvmhost_cockpit_allow_remote: true

# Logging
kvmhost_cockpit_log_level: "warn"

# Custom banner
kvmhost_cockpit_banner_message: ""

# PAM configuration
kvmhost_cockpit_pam_config: []

# Role-based access control
kvmhost_cockpit_user_roles: {}
kvmhost_cockpit_module_restrictions: {}

# Custom configuration sections
kvmhost_cockpit_custom_config: {}
```

## Example Playbooks

### Basic Installation

```yaml
---
- name: Configure Cockpit for KVM host
  hosts: kvm_hosts
  become: true
  roles:
    - role: kvmhost_cockpit
      vars:
        kvmhost_cockpit_enabled: true
        kvmhost_cockpit_ssl_enabled: true
```

### Production Configuration with SSL

```yaml
---
- name: Configure Cockpit with custom SSL
  hosts: kvm_hosts
  become: true
  roles:
    - role: kvmhost_cockpit
      vars:
        kvmhost_cockpit_enabled: true
        kvmhost_cockpit_port: 9443
        kvmhost_cockpit_ssl_enabled: true
        kvmhost_cockpit_ssl_generate_self_signed: false
        kvmhost_cockpit_ssl_cert_path: "/path/to/certificate.crt"
        kvmhost_cockpit_ssl_key_path: "/path/to/private.key"
        kvmhost_cockpit_admin_users:
          - admin
          - operator
        kvmhost_cockpit_firewall_enabled: true
        kvmhost_cockpit_restrict_access: true
        kvmhost_cockpit_allowed_ips:
          - "192.168.1.0/24"
          - "10.0.0.0/8"
```

### Development Environment

```yaml
---
- name: Configure Cockpit for development
  hosts: dev_kvm_hosts
  become: true
  roles:
    - role: kvmhost_cockpit
      vars:
        kvmhost_cockpit_enabled: true
        kvmhost_cockpit_ssl_enabled: false
        kvmhost_cockpit_firewall_enabled: false
        kvmhost_cockpit_additional_packages:
          - cockpit-machines
          - cockpit-storaged
          - cockpit-networkmanager
          - cockpit-podman
```

## Features

### Web Interface Components

- **Dashboard**: System overview with CPU, memory, disk, and network usage
- **Logs**: Real-time log viewing and filtering
- **Storage**: Disk and filesystem management
- **Networking**: Network interface configuration
- **Accounts**: User and group management
- **Services**: systemd service management
- **Terminal**: Web-based terminal access

### Virtualization Management

When `cockpit-machines` is installed:
- Virtual machine creation and management
- VM console access
- Storage pool management
- Network configuration
- VM migration and snapshots

### Security Features

- SSL/TLS encryption support
- Certificate-based authentication
- Role-based access control
- Session management
- Firewall integration
- Access logging

## File Structure

```
roles/kvmhost_cockpit/
├── defaults/main.yml           # Default variables
├── handlers/main.yml           # Service handlers
├── meta/main.yml              # Role metadata and dependencies
├── tasks/
│   ├── main.yml               # Main task coordination
│   ├── configuration/
│   │   ├── authentication.yml # Authentication setup
│   │   ├── firewall.yml       # Firewall configuration
│   │   ├── service.yml        # Service configuration
│   │   └── ssl.yml            # SSL certificate setup
│   ├── setup/
│   │   └── packages.yml       # Package installation
│   └── validation/
│       ├── cockpit.yml        # Service validation
│       └── dependencies.yml   # Dependency validation
├── templates/
│   ├── access.conf.j2         # Access control configuration
│   ├── cockpit-auth.conf.j2   # Authentication configuration
│   ├── cockpit.conf.j2        # Main Cockpit configuration
│   └── cockpit_validation_report.j2  # Validation report
└── README.md                  # This file
```

## Validation

The role includes comprehensive validation:

- Service status verification
- Port accessibility testing
- Web interface responsiveness
- SSL certificate validation
- API endpoint testing
- Configuration file verification

Validation reports are generated in `/tmp/cockpit_validation_report.txt`.

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   - Check for conflicting services: `ss -tlnp | grep :9090`
   - Configure alternative port: `kvmhost_cockpit_port: 9443`

2. **SSL Certificate Issues**
   - Verify certificate files exist and are readable
   - Check certificate validity: `openssl x509 -in cert.pem -text -noout`
   - Use self-signed certificates for testing: `kvmhost_cockpit_ssl_generate_self_signed: true`

3. **Firewall Access Issues**
   - Verify firewall rules: `firewall-cmd --list-all`
   - Check service status: `systemctl status firewalld`
   - Temporarily disable for testing: `kvmhost_cockpit_firewall_enabled: false`

4. **Authentication Problems**
   - Check user permissions: `groups username`
   - Verify PAM configuration: `/etc/pam.d/cockpit`
   - Review logs: `journalctl -u cockpit.socket`

### Log Files

- Cockpit service logs: `journalctl -u cockpit.socket -u cockpit.service`
- Web service logs: `journalctl -u cockpit-ws`
- Authentication logs: `/var/log/secure` or `journalctl -t cockpit-ws`

## Integration

### With Other Roles

The role integrates with:
- `kvmhost_libvirt`: Enhanced VM management capabilities
- `kvmhost_networking`: Network interface management
- `kvmhost_storage`: Storage pool management

### With External Tools

- **Ansible Tower/AWX**: Web-based Ansible management
- **Foreman**: System lifecycle management
- **Nagios/Zabbix**: Monitoring integration
- **LDAP/AD**: Enterprise authentication

## Contributing

When contributing to this role:

1. Follow the established variable naming conventions
2. Add appropriate validation tasks
3. Update the README.md with new variables
4. Test with multiple RHEL/CentOS versions
5. Ensure idempotency of all tasks

## License

This role is part of the Qubinode KVM Host Setup Collection and follows the same licensing terms.

## Author Information

This role is maintained as part of the Qubinode project for automated KVM host configuration.
