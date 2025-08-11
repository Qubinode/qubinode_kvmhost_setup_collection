# Reference - Information-Oriented Documentation

Welcome to the Reference section! This is your comprehensive source for factual, technical information about the Qubinode KVM Host Setup Collection. Here you'll find detailed specifications, API documentation, and complete variable references.

## 🎯 What You'll Find Here

Reference documentation is **information-oriented** and provides:
- Complete API and interface documentation
- Exhaustive variable and parameter references
- Module and role specifications
- Configuration file formats and schemas
- Command-line interface documentation

## 📋 Reference Categories

### Collection Overview
- [Collection Metadata](collection-metadata.md) - Galaxy information, version, dependencies
- [Supported Platforms](supported-platforms.md) - Compatible operating systems and versions
- [System Requirements](system-requirements.md) - Hardware and software prerequisites
- [Installation Methods](installation-methods.md) - All ways to install the collection

### Roles Reference
- [kvmhost_setup](roles/kvmhost_setup.md) - Main orchestration role
- [kvmhost_base](roles/kvmhost_base.md) - Base system configuration
- [kvmhost_libvirt](roles/kvmhost_libvirt.md) - Libvirt and virtualization setup
- [kvmhost_networking](roles/kvmhost_networking.md) - Network bridge configuration
- [kvmhost_storage](roles/kvmhost_storage.md) - Storage pool management
- [kvmhost_cockpit](roles/kvmhost_cockpit.md) - Web interface setup
- [kvmhost_user_config](roles/kvmhost_user_config.md) - User environment configuration
- [edge_hosts_validate](roles/edge_hosts_validate.md) - System validation
- [swygue_lvm](roles/swygue_lvm.md) - LVM management

### Variables and Configuration
- [Global Variables](variables/global-variables.md) - Collection-wide configuration options
- [Role Variables](variables/role-variables.md) - Role-specific variables by role
- [Default Values](variables/default-values.md) - All default variable values
- [Variable Validation](variables/variable-validation.md) - Input validation schemas
- [Environment Variables](variables/environment-variables.md) - Runtime environment configuration

### Playbooks and Examples
- [Example Playbooks](playbooks/example-playbooks.md) - Complete playbook examples
- [Inventory Examples](playbooks/inventory-examples.md) - Sample inventory configurations
- [Variable Examples](playbooks/variable-examples.md) - Common variable configurations
- [Advanced Scenarios](playbooks/advanced-scenarios.md) - Complex deployment examples

### APIs and Interfaces
- [Ansible Module APIs](apis/ansible-modules.md) - Custom module interfaces
- [Role Interfaces](apis/role-interfaces.md) - Role input/output specifications
- [Callback Plugins](apis/callback-plugins.md) - Custom callback plugin APIs
- [Filter Plugins](apis/filter-plugins.md) - Custom filter documentation

### Configuration Files
- [galaxy.yml](config-files/galaxy-yml.md) - Collection metadata configuration
- [ansible.cfg](config-files/ansible-cfg.md) - Ansible configuration
- [molecule.yml](config-files/molecule-yml.md) - Testing configuration
- [requirements.yml](config-files/requirements-yml.md) - Dependency specifications

### Testing and Validation
- [Test Scenarios](testing/test-scenarios.md) - Available Molecule scenarios
- [Validation Schemas](testing/validation-schemas.md) - Configuration validation
- [Test Data](testing/test-data.md) - Sample test data and fixtures
- [CI/CD Configuration](testing/cicd-configuration.md) - GitHub Actions reference

## 📖 Reference Characteristics

Reference documentation in this section:
- **Is comprehensive** - Covers all features and options
- **Is factual** - Based directly on code and specifications
- **Is up-to-date** - Automatically maintained with code changes
- **Is searchable** - Organized for quick lookup
- **Is precise** - Exact syntax, parameters, and return values

## 🔍 How to Use This Reference

### Quick Lookup
- **Need a specific variable?** Check [Variables and Configuration](#variables-and-configuration)
- **Looking for role details?** See [Roles Reference](#roles-reference)
- **Want example code?** Browse [Playbooks and Examples](#playbooks-and-examples)
- **API information?** Check [APIs and Interfaces](#apis-and-interfaces)

### Systematic Reading
- **New to the collection?** Start with [Collection Overview](#collection-overview)
- **Planning deployment?** Review [System Requirements](system-requirements.md)
- **Configuring roles?** Study [Role Variables](variables/role-variables.md)
- **Testing setup?** Examine [Testing and Validation](#testing-and-validation)

## 📚 Reference Format

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

### Role Documentation Format
Each role reference includes:
- **Purpose**: What the role does
- **Dependencies**: Required roles and collections
- **Variables**: All configurable options
- **Examples**: Common usage patterns
- **Return Values**: Facts and variables set by the role
- **Tags**: Available task tags

### API Documentation Format
- **Function Signature**: Exact syntax
- **Parameters**: All input parameters with types
- **Return Values**: Output format and types
- **Exceptions**: Error conditions and handling
- **Examples**: Usage examples with expected output

## 🔄 Maintenance

This reference documentation is maintained as "documentation-as-code":
- **Automated Updates**: Generated from code annotations and docstrings
- **Version Tracking**: Synchronized with collection versions
- **Accuracy Validation**: Tested against actual code behavior
- **Change Tracking**: Updated with every code change

## 🔗 Related Documentation

- **Learning the basics?** Start with [Tutorials](../tutorials/)
- **Solving specific problems?** Check [How-To Guides](../how-to-guides/)
- **Understanding concepts?** Read [Explanations](../explanations/)
- **Contributing?** See [Developer How-To Guides](../how-to-guides/developer/)

---

*This reference provides factual information about the collection. For learning and problem-solving guidance, see other sections of the documentation.*
