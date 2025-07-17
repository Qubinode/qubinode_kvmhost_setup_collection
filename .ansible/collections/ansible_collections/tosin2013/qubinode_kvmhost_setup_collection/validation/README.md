# Variable Validation Framework

## Overview

The Variable Validation Framework implements **ADR-0006: Configuration Management Patterns** by providing schema-driven validation for all role variables. This framework extends the existing assert-based validation with comprehensive JSON Schema validation, cross-role dependency checking, and configuration drift detection.

## Architecture

### Framework Components

```
validation/
├── schema_validation.yml           # Main validation orchestrator
├── schemas/                        # JSON Schema definitions
│   ├── kvmhost_base_schema.json
│   ├── kvmhost_networking_schema.json
│   ├── kvmhost_storage_schema.json
│   ├── kvmhost_cockpit_schema.json
│   └── kvmhost_user_config_schema.json
├── schema_validation_*.yml         # Role-specific validation tasks
├── cross_role_validation.yml       # Cross-role dependency checks
├── configuration_drift_detection.yml # Drift detection from ADR compliance
├── validation_reporting.yml        # Comprehensive validation reports
└── validation_utilities.yml        # Shared validation functions
```

### Integration Points

- **Main Validation**: Integrated into `roles/kvmhost_setup/tasks/validation/main.yml`
- **Role Validation**: Each modular role includes validation tasks
- **Environment Templates**: Validates consistency with environment-specific templates
- **ADR Compliance**: Enforces architectural rules from ADRs

## Features

### 1. Schema-Driven Validation

Each role has a corresponding JSON Schema that defines:
- Required vs optional properties
- Data types and formats
- Value constraints and patterns
- Cross-property dependencies
- ADR compliance requirements

### 2. Cross-Role Dependency Validation

Validates dependencies between roles:
- **kvmhost_networking** ← **kvmhost_base** (base packages)
- **kvmhost_storage** ← **kvmhost_base** (EPEL repository)
- **kvmhost_libvirt** ← **kvmhost_networking** + **kvmhost_storage**
- **kvmhost_cockpit** ← **kvmhost_base**
- **kvmhost_user_config** ← **kvmhost_base**

### 3. Configuration Drift Detection

Detects deviations from ADR-recommended configurations:
- EPEL installation method (ADR-0001)
- Bridge device naming patterns (ADR-0007)
- Standard directory locations
- Default port configurations
- User naming conventions

### 4. Comprehensive Reporting

Generates detailed validation reports with:
- Error and warning summaries
- ADR compliance status
- Specific recommendations
- Environment consistency checks
- Validation timestamps and metadata

## Usage

### Basic Validation

```yaml
- name: Run variable validation
  ansible.builtin.include_tasks: validation/schema_validation.yml
  vars:
    validation_scope: "all_roles"
```

### Role-Specific Validation

```yaml
- name: Validate networking configuration
  ansible.builtin.include_tasks: validation/schema_validation.yml
  vars:
    validation_scope: "kvmhost_networking"
```

### With Drift Detection

```yaml
- name: Run validation with drift detection
  ansible.builtin.include_tasks: validation/schema_validation.yml
  vars:
    enable_drift_detection: true
    inventory_environment: "production"
```

### Save Validation Report

```yaml
- name: Run validation and save report
  ansible.builtin.include_tasks: validation/schema_validation.yml
  vars:
    save_validation_report: true
    validation_report_path: "/tmp/validation_report.yml"
```

## Schema Definitions

### Example: kvmhost_base_schema.json

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "KVM Host Base Configuration Schema",
  "type": "object",
  "properties": {
    "epel_installation_method": {
      "type": "string",
      "enum": ["dnf_module", "rpm", "package"],
      "default": "dnf_module"
    },
    "supported_os_families": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["RedHat", "CentOS", "Rocky", "AlmaLinux", "Fedora"]
      }
    }
  },
  "required": ["supported_os_families", "epel_installation_method"],
  "adr_compliance": {
    "adr_001": {
      "property": "epel_installation_method",
      "requirement": "Must use 'dnf_module' for ADR-0001 compliance"
    }
  }
}
```

## ADR Compliance

### ADR-0001: DNF Module for EPEL Installation
- Validates `epel_installation_method` equals `"dnf_module"`
- Reports violations as configuration errors

### ADR-0002: Ansible Role-Based Modular Architecture
- Validates role variable naming conventions
- Checks role interface consistency

### ADR-0003: KVM Virtualization Platform Selection
- Validates KVM/libvirt-specific configurations
- Ensures proper storage and network setup

### ADR-0006: Configuration Management Patterns
- Enforces variable hierarchy and naming
- Validates against schema definitions

### ADR-0007: Network Architecture Decisions
- Validates bridge-based networking configuration
- Checks bridge device naming patterns

## Error Handling

### Validation Errors
Cause playbook failure and require immediate attention:
- Missing required variables
- Invalid data types or formats
- ADR compliance violations
- Cross-role dependency failures

### Validation Warnings
Logged but don't cause failure:
- Configuration drift from recommendations
- Non-standard naming patterns
- Environment template inconsistencies

## Extending the Framework

### Adding New Role Schema

1. Create schema file: `validation/schemas/new_role_schema.json`
2. Create validation task: `validation/schema_validation_new_role.yml`
3. Update main orchestrator: `validation/schema_validation.yml`
4. Add role validation: `roles/new_role/tasks/validation/main.yml`

### Adding Validation Rules

1. Update relevant schema file with new properties
2. Add validation logic to role-specific validation task
3. Update cross-role validation if dependencies exist
4. Add drift detection rules if applicable

### Custom Validation Functions

Add reusable validation functions to `validation/validation_utilities.yml`:

```yaml
- name: Validate custom format
  ansible.builtin.set_fact:
    is_valid_custom: "{{ target_value | regex_search('^custom_pattern$') | bool }}"
  when: target_value is defined
```

## Testing

### Molecule Integration

The validation framework is integrated with Molecule testing:

```yaml
# molecule/default/verify.yml
- name: Run comprehensive validation
  ansible.builtin.include_tasks: validation/schema_validation.yml
  vars:
    validation_scope: "all_roles"
    enable_drift_detection: true
```

### Manual Testing

```bash
# Test validation with invalid configuration
ansible-playbook test.yml -e "epel_installation_method=rpm"

# Test with drift detection
ansible-playbook test.yml -e "enable_drift_detection=true"
```

## Troubleshooting

### Common Issues

1. **Schema File Not Found**
   - Ensure schema files exist in `validation/schemas/`
   - Check file permissions

2. **JSON Schema Validation Errors**
   - Validate JSON syntax with `jq` or online validator
   - Check property names and types

3. **Cross-Role Dependency Failures**
   - Verify role dependencies in `roles/role_config.yml`
   - Check variable definitions across roles

### Debug Mode

Enable detailed validation output:

```yaml
- name: Debug validation
  ansible.builtin.include_tasks: validation/schema_validation.yml
  vars:
    ansible_verbosity: 2
    debug_validation: true
```

## Performance Considerations

- Schema validation adds ~5-10 seconds to playbook execution
- Use `validation_scope` to limit validation to specific roles
- Disable drift detection in CI/CD for faster execution
- Cache schema files for repeated runs

## Security Considerations

- Schema files don't contain sensitive data
- Validation reports may contain configuration details
- Use appropriate file permissions for validation reports
- Don't log sensitive variable values in validation output

---

**Version**: 1.0.0  
**Compatibility**: Ansible 2.9+  
**Last Updated**: 2025-07-11  
**ADR Compliance**: ADR-0006
