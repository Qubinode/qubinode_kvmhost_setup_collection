# ADR-0002: Ansible Role-Based Modular Architecture

## Status
Accepted

## Context
The project manages complex KVM host setup, edge host validation, and LVM configuration tasks. These operations involve multiple interconnected components including virtualization, networking, storage, and system configuration that need to be organized in a maintainable and reusable way. 

Without proper organization, these tasks would become a monolithic, hard-to-maintain codebase that would be difficult to test, debug, and extend.

## Decision
Adopt a modular Ansible role-based architecture to organize all automation tasks into discrete, reusable roles. Each role encapsulates related functionality with standardized directory structure including tasks, handlers, variables, defaults, templates, and documentation.

The project implements nine specialized roles:
1. **kvmhost_setup**: Main orchestration role coordinating all KVM host setup
2. **kvmhost_base**: Foundation system configuration and package management
3. **kvmhost_networking**: Network bridge configuration and validation
4. **kvmhost_libvirt**: Libvirt daemon and virtualization setup
5. **kvmhost_storage**: Storage pool management and optimization
6. **kvmhost_cockpit**: Web interface installation and configuration
7. **kvmhost_user_config**: User environment and shell configuration
8. **edge_hosts_validate**: System validation and compliance checking
9. **swygue_lvm**: Advanced LVM management and configuration

## Alternatives Considered
1. **Monolithic playbook structure** - All tasks in single large playbooks without role separation
2. **Single large playbook** with all tasks inline - Would be difficult to maintain and test
3. **Separate standalone scripts** for each configuration task - Would lose Ansible benefits and create inconsistent execution patterns
4. **External tooling integration** without Ansible abstraction - Would require managing multiple tool ecosystems

## Consequences

### Positive
- **Improved code organization** through encapsulated, reusable components
- **Enhanced maintainability** with clear separation of concerns
- **Better reusability** - roles can be used across multiple playbooks and projects
- **Simplified testing** - each role can be tested independently using Molecule
- **Parallel development** - multiple developers can work on different roles simultaneously
- **Selective execution** - users can run only the roles they need
- **Clear dependencies** - explicit role dependencies make relationships obvious

### Negative
- **Increased complexity** in role coordination and dependency management
- **Additional overhead** in maintaining role interfaces and contracts
- **Learning curve** for developers unfamiliar with modular Ansible patterns
- **Potential over-engineering** for simple use cases

## Implementation

### Role Structure Standard
Each role follows the standard Ansible role directory structure:
```
roles/<role_name>/
├── defaults/main.yml      # Default variables
├── handlers/main.yml      # Event handlers
├── meta/main.yml         # Role metadata and dependencies
├── tasks/main.yml        # Main task entry point
├── tasks/               # Additional task files
├── templates/           # Jinja2 templates
├── vars/main.yml        # Role-specific variables
├── files/              # Static files
└── README.md           # Role documentation
```

### Dependency Management
Roles declare explicit dependencies in `meta/main.yml`:
```yaml
dependencies:
  - role: kvmhost_base
    when: kvmhost_base_required | default(true)
```

### Interface Contracts
Each role defines clear input/output interfaces:
- **Input**: Required and optional variables
- **Output**: Facts set and services configured
- **Side Effects**: System changes made

### Testing Strategy
Each role includes comprehensive Molecule testing:
- **Unit tests**: Individual role functionality
- **Integration tests**: Role interaction validation
- **System tests**: End-to-end functionality verification

## Evidence

### Implementation Artifacts
- **Role Directory Structure**: Standardized across all roles
- **Dependency Declarations**: Explicit in meta/main.yml files
- **Testing Framework**: Molecule scenarios for each role
- **Documentation**: README.md for each role with interface documentation

### Success Metrics
- **Code Reusability**: Roles used across multiple playbooks
- **Testing Coverage**: Each role has comprehensive test coverage
- **Maintenance Efficiency**: Isolated changes don't affect other roles
- **Developer Productivity**: Parallel development on different roles

### Related ADRs
- **ADR-0004**: Idempotent Task Design Pattern - Ensures role reliability
- **ADR-0005**: Molecule Testing Framework Integration - Enables role testing
- **ADR-0006**: Configuration Management Patterns - Defines role variable standards

## References
- [Ansible Best Practices - Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#directory-layout)
- [Ansible Role Development Guide](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html)
- [Modular Architecture Patterns](https://martinfowler.com/articles/microservices.html)

---

*This ADR established the foundational architecture for the collection. For understanding how this architecture is implemented, see [Modular Role Design](../modular-role-design.md).*
