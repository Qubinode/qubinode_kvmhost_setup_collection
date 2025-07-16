# kvmhost_user_config

This role configures user shell environments, SSH access, and permissions for KVM hosts, providing a comprehensive user configuration framework.

## Description

The `kvmhost_user_config` role manages user accounts, shell environments, SSH configuration, and permissions for KVM host administrators and users. It provides:

- User account creation and management
- Shell environment customization (bash, zsh, fish)
- SSH key generation and management
- Sudo and group permissions configuration
- Dotfiles and configuration management
- Development tools installation
- Environment variable configuration

## Requirements

- RHEL/CentOS/Rocky/AlmaLinux 8 or newer
- systemd-based system
- Python 3.6 or newer
- ansible-core 2.12 or newer

## Role Dependencies

This role has dependencies on:
- `kvmhost_base` (implied through role_config.yml)

## Variables

### Core Configuration

```yaml
# Enable/disable the entire role
kvmhost_user_config_enabled: true

# Target user configuration
kvmhost_user_config_target_user: "{{ ansible_user_id }}"
kvmhost_user_config_create_users: true
```

### User Management

```yaml
# User account configuration
kvmhost_user_config_users:
  - name: "{{ kvmhost_user_config_target_user }}"
    shell: "/bin/bash"
    groups:
      - wheel
      - libvirt
    create_home: true
    state: present

# Additional users
kvmhost_user_config_additional_users: []

# System groups
kvmhost_user_config_system_groups:
  - wheel
  - libvirt
  - docker
```

### Shell Configuration

```yaml
# Shell customization
kvmhost_user_config_shell_enabled: true
kvmhost_user_config_shell_type: "bash"
kvmhost_user_config_starship_enabled: true
kvmhost_user_config_vim_enhanced: true

# Command aliases
kvmhost_user_config_aliases:
  ll: "ls -alF"
  la: "ls -A"
  vms: "virsh list --all"
  vmstart: "virsh start"
```

### SSH Configuration

```yaml
# SSH key management
kvmhost_user_config_ssh_enabled: true
kvmhost_user_config_ssh_generate_keys: true
kvmhost_user_config_ssh_key_type: "ed25519"

# SSH authorized keys
kvmhost_user_config_ssh_authorized_keys: []
```

### Environment Variables

```yaml
# Custom environment variables
kvmhost_user_config_env_vars:
  EDITOR: "vim"
  PAGER: "less"
  HISTSIZE: "10000"

# PATH modifications
kvmhost_user_config_custom_paths:
  - "$HOME/bin"
  - "$HOME/.local/bin"
```

## Example Playbooks

### Basic Configuration

```yaml
---
- name: Configure user environment for KVM host
  hosts: kvm_hosts
  become: true
  roles:
    - role: kvmhost_user_config
      vars:
        kvmhost_user_config_enabled: true
        kvmhost_user_config_target_user: "admin"
```

### Advanced Configuration

```yaml
---
- name: Configure multiple users with custom settings
  hosts: kvm_hosts
  become: true
  roles:
    - role: kvmhost_user_config
      vars:
        kvmhost_user_config_enabled: true
        kvmhost_user_config_target_user: "admin"
        kvmhost_user_config_additional_users:
          - name: "developer"
            shell: "/bin/bash"
            groups: ["libvirt"]
        kvmhost_user_config_starship_enabled: true
        kvmhost_user_config_ssh_generate_keys: true
        kvmhost_user_config_dev_tools:
          - git
          - htop
          - tmux
```

## Features

### User Account Management
- Automated user creation with proper permissions
- Group membership management
- Home directory structure setup
- Shell selection and configuration

### Shell Environment
- Bash, zsh, and fish support
- Starship prompt integration
- Custom aliases and functions
- Command history optimization
- Tab completion enhancement

### SSH Configuration
- SSH key generation (RSA, ED25519, ECDSA)
- Authorized keys management
- SSH client configuration
- SSH agent setup

### Development Tools
- Essential CLI tools installation
- Modern CLI alternatives (bat, exa, fd, ripgrep)
- Version control configuration
- Editor customization

### Security Features
- Sudo configuration with NOPASSWD options
- File permission management
- SSH security hardening
- User access restrictions

## File Structure

```
roles/kvmhost_user_config/
├── defaults/main.yml          # Default variables
├── handlers/main.yml          # Event handlers
├── meta/main.yml             # Role metadata
├── tasks/
│   ├── main.yml              # Main task orchestration
│   ├── validation/
│   │   ├── dependencies.yml  # Dependency validation
│   │   └── user_config.yml   # Configuration validation
│   ├── users/
│   │   ├── account_management.yml  # User account tasks
│   │   └── permissions.yml         # Permission management
│   ├── home/
│   │   └── directory_setup.yml     # Home directory setup
│   ├── shell/
│   │   └── configuration.yml       # Shell customization
│   ├── tools/
│   │   └── installation.yml        # Tool installation
│   ├── ssh/
│   │   └── configuration.yml       # SSH setup
│   ├── dotfiles/
│   │   └── setup.yml               # Dotfiles management
│   └── environment/
│       └── variables.yml           # Environment variables
├── vars/main.yml             # Internal variables
└── README.md                 # This file
```

## Integration

### With Other Roles
- `kvmhost_base`: Provides foundational system setup
- `kvmhost_libvirt`: Integrates with VM management permissions
- `kvmhost_cockpit`: Coordinates web interface user access

### With KVM/Libvirt
- Automatic libvirt group membership
- VM management aliases and functions
- Console access configuration
- Storage permission management

## Contributing

When contributing to this role:

1. Follow established variable naming conventions
2. Add appropriate validation tasks for new features
3. Update README.md with new variables and examples
4. Test with multiple user scenarios
5. Ensure idempotency of all user modifications

## License

This role is part of the Qubinode KVM Host Setup Collection and follows the same licensing terms.

## Author Information

This role is maintained as part of the Qubinode project for automated KVM host configuration.

---

**Note**: This role is currently in development. Task implementations are placeholder files that need to be completed with full functionality.
