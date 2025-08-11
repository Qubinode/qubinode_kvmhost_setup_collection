# Documentation Directory

This directory contains all documentation for the Qubinode KVM Host Setup Collection. The documentation is organized using the [Diátaxis framework](https://diataxis.fr/) for optimal user experience.

## 📚 Primary Documentation (Diátaxis Framework)

### 🎯 [Start Here: Diátaxis Documentation](diataxis/)

Our main documentation follows the Diátaxis framework and is organized by user intent:

- **📚 [Tutorials](diataxis/tutorials/)** - Learn by doing with step-by-step guides
- **🛠️ [How-To Guides](diataxis/how-to-guides/)** - Solve specific problems
- **👨‍💻 [Developer Guides](diataxis/how-to-guides/developer/)** - Contribute to the project
- **📖 [Reference](diataxis/reference/)** - Look up technical details
- **💡 [Explanations](diataxis/explanations/)** - Understand architecture and design

### 🚀 Quick Navigation

**New to the collection?**
→ [Quick Start Guide](diataxis/tutorials/00-quick-start.md)

**Want to learn step-by-step?**
→ [Your First KVM Host Setup](diataxis/tutorials/01-first-kvm-host-setup.md)

**Have a specific problem to solve?**
→ [How-To Guides](diataxis/how-to-guides/)

**Want to contribute?**
→ [Developer Guides](diataxis/how-to-guides/developer/)

**Need technical specifications?**
→ [Reference Documentation](diataxis/reference/)

**Curious about design decisions?**
→ [Explanations](diataxis/explanations/)

## 📁 Legacy Documentation (Being Migrated)

The following documentation is being migrated to the Diátaxis framework:

### ⚠️ Migration Status
- **✅ Migrated**: Content moved to Diátaxis structure
- **🔄 In Progress**: Currently being migrated
- **📋 Planned**: Scheduled for migration

### User Documentation
- ✅ `USER_INSTALLATION_GUIDE.md` → [Tutorials](diataxis/tutorials/) and [How-To Guides](diataxis/how-to-guides/)
- ✅ `compatibility_report.md` → [Platform Support](diataxis/reference/supported-platforms.md)
- ✅ `FEATURE_COMPATIBILITY_MATRIX.md` → [Feature Matrix](diataxis/reference/feature-matrix.md)

### Developer Documentation  
- ✅ `DEPENDABOT_SETUP_GUIDE.md` → [Setup Dependabot](diataxis/how-to-guides/developer/setup-dependabot-automation.md)
- ✅ `MOLECULE_MIGRATION_GUIDE.md` → [Migrate Molecule Tests](diataxis/how-to-guides/developer/migrate-molecule-tests.md)
- ✅ `MANDATORY_LOCAL_TESTING.md` → [Local Testing Requirements](diataxis/how-to-guides/developer/local-testing-requirements.md)
- 🔄 `ANSIBLE_LINT_AUTOMATION.md` → Developer How-To Guides
- 🔄 `local-molecule-setup.md` → Developer How-To Guides

### Reference Documentation
- ✅ `role_interface_standards.md` → [Role Interface Standards](diataxis/reference/apis/role-interfaces.md)
- ✅ `variable_naming_conventions.md` → [Variable Naming](diataxis/reference/standards/variable-naming.md)
- 🔄 `ANSIBLE_COLLECTION_SECURITY.md` → Reference Documentation
- 🔄 `REDHAT_REGISTRY_SETUP.md` → Reference Documentation

### Architectural Documentation
- ✅ `adrs/` → [Architecture Decisions](diataxis/explanations/architecture-decisions/)
- ✅ `DEVOPS_AUTOMATION_FRAMEWORK.md` → [Automation Philosophy](diataxis/explanations/automation-philosophy.md)
- 🔄 `AUTOMATION_ENABLEMENT_STRATEGY.md` → Explanations
- 🔄 `RELEASE_STRATEGY.md` → Explanations

## 🗂️ Directory Structure

```
docs/
├── diataxis/                    # 📚 Main documentation (Diátaxis framework)
│   ├── tutorials/              # 📚 Learning-oriented guides
│   ├── how-to-guides/          # 🛠️ Problem-solving guides
│   │   └── developer/          # 👨‍💻 Developer-specific guides
│   ├── reference/              # 📖 Technical specifications
│   └── explanations/           # 💡 Architecture and concepts
├── adrs/                       # 🔄 Architecture Decision Records (migrating)
├── research/                   # 🔄 Research documentation (migrating)
├── audit-reports/              # 🔄 Audit results (migrating)
├── session-reports/            # 🔄 Implementation reports (migrating)
└── archive/                    # 📦 Historical documentation
```

## 🔄 Migration Progress

### Completed Migrations ✅
- Core Diátaxis structure created
- Essential tutorials and how-to guides
- Key developer documentation
- Primary reference materials
- Core architectural explanations

### In Progress 🔄
- Remaining developer automation guides
- Complete reference documentation
- All ADRs and architectural decisions
- Research and analysis documentation

### Planned 📋
- Legacy documentation cleanup
- Link updates throughout codebase
- Archive organization
- Final validation and testing

## 🔗 External Links

### Ansible Resources
- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/tosin2013/qubinode_kvmhost_setup_collection)
- [Ansible Collection Development](https://docs.ansible.com/ansible/devel/dev_guide/developing_collections.html)

### Project Resources
- [GitHub Repository](https://github.com/Qubinode/qubinode_kvmhost_setup_collection)
- [Issue Tracker](https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues)
- [Discussions](https://github.com/Qubinode/qubinode_kvmhost_setup_collection/discussions)

### Framework Resources
- [Diátaxis Framework](https://diataxis.fr/)
- [Documentation Best Practices](https://documentation.divio.com/)

## 📞 Support and Community

### Getting Help
- **Documentation**: Search our [Diátaxis documentation](diataxis/)
- **Issues**: [Report bugs or request features](https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues)
- **Discussions**: [Community support and questions](https://github.com/Qubinode/qubinode_kvmhost_setup_collection/discussions)

### Contributing
- **Code**: Follow our [Contributing Guidelines](diataxis/how-to-guides/developer/contributing-guidelines.md)
- **Documentation**: Help improve our documentation
- **Testing**: Enhance test coverage and scenarios
- **Feedback**: Share your experience and suggestions

---

*This documentation is continuously improved. For the most current information, always refer to the [Diátaxis documentation](diataxis/).*
