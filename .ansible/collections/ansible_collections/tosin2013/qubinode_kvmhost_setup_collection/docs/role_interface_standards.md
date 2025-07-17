# Role Interface Documentation Standards

## Overview

This document defines the standardized interface requirements for all roles in the Qubinode KVM Host Setup Collection, implementing ADR-0002 (Ansible Role-Based Modular Architecture).

## Interface Standards

### 1. Role Metadata (meta/main.yml)

Every role must define:

```yaml
galaxy_info:
  author: "Qubinode Project"
  description: "Clear, concise role description"
  company: "Red Hat"
  license: "GPL-3.0"
  min_ansible_version: "2.9"
  platforms:
    - name: EL
      versions: ["8", "9", "10"]
  
dependencies: []  # Explicit dependency list

collections:      # Required collections
  - ansible.posix
  - community.general
```

### 2. Variable Interface (defaults/main.yml)

#### Required Pattern:
```yaml
# Feature toggles (boolean)
enable_<feature>: true/false

# Configuration objects
<role>_config:
  setting1: value
  setting2: value

# List configurations  
<role>_packages:
  - package1
  - package2
```

#### Variable Naming Convention:
- Role-specific variables: `<role_name>_<setting>`
- Feature toggles: `enable_<feature>`
- List variables: `<role_name>_<type>s` (plural)
- Configuration objects: `<role_name>_config`

### 3. Task Interface (tasks/main.yml)

#### Required Structure:
```yaml
- name: "Phase Description - Task Category"
  ansible.builtin.include_tasks: subtask.yml
  tags:
    - category
    - specific_tag
```

#### Task Naming Convention:
- Main task names: `"Role Name - Action Description"`
- Include names: `"Phase N: Category Description"`
- Subtask names: `"Action - Specific Operation"`

### 4. Tag Standards

#### Required Tags:
- `always`: Tasks that run regardless of tag selection
- `<role_name>`: All tasks for the role
- `validation`: Validation and verification tasks
- `config`: Configuration tasks
- `install`: Installation tasks

#### Optional Tags:
- `debug`: Debug and diagnostic tasks
- `backup`: Backup and restore tasks
- `test`: Testing-specific tasks

### 5. Fact Export Interface

#### Naming Convention:
```yaml
<role_name>_<fact_type>: value
```

#### Required Exports:
- `<role_name>_completed`: Boolean completion status
- `<role_name>_version`: Role version if applicable
- `<role_name>_config_path`: Configuration file paths

#### Example:
```yaml
kvmhost_base_completed: true
kvmhost_base_os_family: "RedHat"
kvmhost_base_major_version: "9"
```

### 6. Handler Interface

#### Naming Convention:
```yaml
- name: "restart <service_name>"
- name: "reload <service_name>"
- name: "validate <component>"
```

### 7. File and Directory Standards

#### Completion Markers:
- Location: `/var/lib/<role_name>_<status>`
- Examples: 
  - `/var/lib/kvmhost_base_prepared`
  - `/var/lib/kvmhost_networking_configured`

#### Generated Files:
- Reports: `/tmp/<role_name>_<type>_<timestamp>.txt`
- Backups: `/tmp/<role_name>_backup_<timestamp>.txt`
- Logs: `/var/log/<role_name>/<component>.log`

## Dependency Management

### 1. Declaration Format

```yaml
# In meta/main.yml
dependencies:
  - role: dependency_role_name
    when: condition
```

### 2. Runtime Dependencies

```yaml
# In tasks/main.yml
- name: "Verify dependency completion"
  ansible.builtin.assert:
    that:
      - dependency_role_completed | default(false)
    fail_msg: "Dependency role not completed"
```

### 3. Feature Dependencies

```yaml
# Conditional role inclusion
- name: "Include dependent role"
  ansible.builtin.include_role:
    name: dependency_role
  when: enable_feature | default(true)
```

## Testing Interface

### 1. Molecule Configuration

Each role must provide:
- `molecule/default/molecule.yml`: Basic testing
- `molecule/default/converge.yml`: Test playbook  
- `molecule/default/verify.yml`: Validation tests

### 2. Test Variables

```yaml
# Testing mode flags
testing_mode: true
cicd_test: true
molecule_test: true

# Test-specific configuration
test_<role_name>_<setting>: value
```

## Validation Standards

### 1. Input Validation

```yaml
- name: "Validate required variables"
  ansible.builtin.assert:
    that:
      - required_var is defined
      - required_var | length > 0
    fail_msg: "Required variable not defined"
```

### 2. State Validation

```yaml
- name: "Validate service state"
  ansible.builtin.systemd:
    name: service_name
  register: service_status

- name: "Assert service is running"
  ansible.builtin.assert:
    that:
      - service_status.status.ActiveState == "active"
```

### 3. Completion Validation

```yaml
- name: "Create completion marker"
  ansible.builtin.file:
    path: "/var/lib/{{ role_name }}_completed"
    state: touch
    mode: '0644'
```

## Documentation Requirements

### 1. README.md Structure

Required sections:
- Overview
- Features  
- Supported Platforms
- Dependencies
- Role Variables
- Example Playbook
- Role Interface
- Tags
- Testing
- Troubleshooting

### 2. Variable Documentation

Each variable must include:
- Purpose and description
- Default value
- Type (string, boolean, list, dict)
- Required/Optional status
- Examples

### 3. Example Documentation

```yaml
# Network bridge configuration
qubinode_bridge_name: "qubibr0"    # string, required
  # Description: Name of the bridge interface to create
  # Default: "qubibr0"
  # Example: "kvmbr0", "br0"
```

## Backwards Compatibility

### 1. Variable Deprecation

```yaml
# Deprecated variable handling
- name: "Handle deprecated variable"
  ansible.builtin.set_fact:
    new_variable: "{{ old_variable }}"
  when: 
    - old_variable is defined
    - new_variable is not defined

- name: "Warn about deprecated variable"
  ansible.builtin.debug:
    msg: "WARNING: old_variable is deprecated, use new_variable"
  when: old_variable is defined
```

### 2. Migration Support

Provide migration tasks for major interface changes:

```yaml
- name: "Migrate configuration format"
  ansible.builtin.include_tasks: migrate_config.yml
  when: legacy_config_detected | default(false)
```

## Quality Standards

### 1. Idempotency

All tasks must be idempotent and include proper `changed_when` conditions.

### 2. Error Handling

```yaml
- name: "Operation with error handling"
  ansible.builtin.command: risky_command
  register: result
  failed_when: result.rc not in [0, 1]  # Define acceptable return codes
  retries: 3
  delay: 5
```

### 3. Logging

```yaml
- name: "Log important operations"
  ansible.builtin.debug:
    msg: "Performing {{ operation }} with {{ parameters }}"
  when: enable_logging | default(true)
```

This interface documentation ensures consistency across all roles and facilitates easy integration and maintenance.
