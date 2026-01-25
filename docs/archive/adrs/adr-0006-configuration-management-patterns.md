# ADR-0006: Configuration Management Patterns

## Status
Implemented

> **Review Note (2026-01-25)**: ADR compliance review confirmed full implementation with
> 9/10 compliance score. Configuration management patterns are consistently applied
> with standardized variable hierarchy, naming conventions, and template-driven config.

## Context
The Qubinode project requires consistent and maintainable configuration management across multiple roles, environments, and deployment scenarios. Configuration data includes system settings, network parameters, storage configurations, and application-specific variables that need to be:

- Organized in a logical hierarchy
- Environment-specific when needed
- Easily maintainable and discoverable
- Secure for sensitive data
- Consistent across all roles and playbooks

Without standardized configuration patterns, the project would suffer from scattered configuration files, inconsistent variable naming, and difficulty in managing environment-specific settings.

## Decision
Implement a standardized configuration management pattern using Ansible's variable precedence hierarchy with the following structure:

1. **Role Defaults** (`roles/*/defaults/main.yml`) - Safe default values for all role variables
2. **Role Variables** (`roles/*/vars/main.yml`) - Role-specific constants and computed values
3. **Inventory Variables** (`inventories/*/group_vars/`, `inventories/*/host_vars/`) - Environment and host-specific overrides
4. **Centralized Variable Naming** - Consistent naming conventions with role prefixes
5. **Template-driven Configuration** - Use Jinja2 templates for complex configuration files

## Alternatives Considered
1. **Flat variable structure** - All variables in single files without hierarchy
   - Pros: Simple to understand initially
   - Cons: Becomes unmanageable at scale, no environment separation

2. **External configuration management** - Tools like Consul, etcd for configuration
   - Pros: Dynamic configuration updates, service discovery integration
   - Cons: Additional infrastructure complexity, not needed for this use case

3. **Environment-specific repositories** - Separate repos for each environment
   - Pros: Complete isolation between environments
   - Cons: Code duplication, harder to maintain consistency

4. **Hardcoded values** - Configuration values embedded in tasks
   - Pros: Simple initial implementation
   - Cons: Inflexible, difficult to maintain, environment-specific deployments impossible

## Consequences

### Positive
- **Predictable variable precedence** - Clear understanding of which values take priority
- **Environment flexibility** - Easy to override values for different environments
- **Maintainable defaults** - Safe fallback values ensure roles work out-of-the-box
- **Consistent naming** - Role-prefixed variables prevent naming conflicts
- **Template reusability** - Configuration templates can be shared and reused
- **Secure handling** - Sensitive variables can be managed through Ansible Vault
- **Documentation** - Variable definitions serve as configuration documentation

### Negative
- **Learning curve** - Team needs to understand Ansible variable precedence
- **Initial overhead** - More files and structure to set up initially
- **Debugging complexity** - Variable precedence can make troubleshooting more complex

## Implementation

### Variable Hierarchy
```
roles/*/defaults/main.yml          # Lowest precedence - safe defaults
roles/*/vars/main.yml              # Role constants
inventories/*/group_vars/all.yml   # Global overrides
inventories/*/group_vars/group.yml # Group-specific overrides
inventories/*/host_vars/host.yml   # Host-specific overrides (highest precedence)
```

### Naming Conventions
- **Role-prefixed variables**: `kvmhost_bridge_name`, `edge_validate_packages`
- **Consistent patterns**: `<role>_<component>_<attribute>`
- **Boolean naming**: `enable_*`, `configure_*`, `validate_*`
- **List naming**: `*_packages`, `*_services`, `*_networks`

### Template Usage
- Network configurations: `libvirt_net_bridge.xml.j2`
- Storage pools: `libvirt_pool.xml.j2`
- System configs: `resolv.conf.j2`, `bashrc.j2`

## Evidence
- Standardized `defaults/main.yml` files in all roles with documented variables
- Template files in `templates/` directories for complex configurations
- Inventory structure with group_vars for environment-specific settings
- Consistent variable naming patterns across roles
- Documentation of variables in role README files

## Date
2024-07-11

## Tags
ansible, configuration-management, variables, templates, maintainability, environments
