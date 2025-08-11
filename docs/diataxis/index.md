# Qubinode KVM Host Setup Collection - Diátaxis Documentation

Welcome to the comprehensive documentation for the Qubinode KVM Host Setup Collection, organized according to the [Diátaxis framework](https://diataxis.fr/) for optimal user experience and information discovery.

## 🧭 Documentation Navigation

### 📚 [Tutorials](tutorials/) - Learning-Oriented
**Start here if you're new to the collection**

Perfect for newcomers who want to learn by doing:
- [Your First KVM Host Setup](tutorials/01-first-kvm-host-setup.md) - Complete walkthrough from installation to running VMs
- [Basic Network Configuration](tutorials/02-basic-network-configuration.md) - Set up networking for your KVM environment  
- [Storage Pool Creation](tutorials/03-storage-pool-creation.md) - Create and manage storage for virtual machines

**Best for**: Getting started, learning fundamentals, building confidence

### 🛠️ [How-To Guides](how-to-guides/) - Problem-Oriented
**Use when you have a specific goal to accomplish**

Practical solutions for common tasks:
- [Configure Custom Network Bridges](how-to-guides/configure-custom-bridges.md) - Set up specialized network configurations
- [Manage Storage Pools](how-to-guides/manage-storage-pools.md) - Create, modify, and delete storage pools
- [Troubleshoot Network Issues](how-to-guides/troubleshoot-networking.md) - Diagnose and fix network problems

**Best for**: Solving specific problems, accomplishing particular goals

### 👨‍💻 [Developer How-To Guides](how-to-guides/developer/) - Contribution-Oriented
**Essential for contributors and developers**

Development and contribution guidance:
- [Set Up Development Environment](how-to-guides/developer/setup-development-environment.md) - Complete dev environment setup
- [Run Molecule Tests](how-to-guides/developer/run-molecule-tests.md) - Execute local testing with Molecule
- [Contributing Guidelines](how-to-guides/developer/contributing-guidelines.md) - How to contribute effectively

**Best for**: Contributing to the project, development work, testing

### 📖 [Reference](reference/) - Information-Oriented
**Look up specific technical information**

Comprehensive technical specifications:
- [Collection Metadata](reference/collection-metadata.md) - Galaxy information, version, dependencies
- [kvmhost_setup Role](reference/roles/kvmhost_setup.md) - Main orchestration role reference
- [Global Variables](reference/variables/global-variables.md) - Collection-wide configuration options

**Best for**: Looking up specific details, API documentation, configuration options

### 💡 [Explanations](explanations/) - Understanding-Oriented
**Understand the bigger picture and design decisions**

Conceptual understanding and design rationale:
- [Architecture Overview](explanations/architecture-overview.md) - High-level system design and principles
- [Modular Role Design](explanations/modular-role-design.md) - Why we chose a modular approach

**Best for**: Understanding concepts, design decisions, architectural context

## 🎯 Quick Start Guide

### New Users
1. **Start with**: [Your First KVM Host Setup](tutorials/01-first-kvm-host-setup.md)
2. **Then explore**: [How-To Guides](how-to-guides/) for specific tasks
3. **Reference when needed**: [Reference](reference/) for detailed information

### Experienced Users
1. **Find solutions**: [How-To Guides](how-to-guides/) for specific problems
2. **Look up details**: [Reference](reference/) for technical specifications
3. **Understand design**: [Explanations](explanations/) for architectural context

### Contributors
1. **Set up environment**: [Developer How-To Guides](how-to-guides/developer/)
2. **Understand architecture**: [Explanations](explanations/)
3. **Follow guidelines**: [Contributing Guidelines](how-to-guides/developer/contributing-guidelines.md)

## 📋 Documentation Principles

### Audience Separation

**End-User Documentation** (Tutorials, How-To Guides, Reference, Explanations):
- Focuses on using the deployed collection
- Assumes collection is installed from Ansible Galaxy
- No development environment setup required
- Production-ready examples and configurations

**Developer Documentation** (Developer How-To Guides):
- Focuses on contributing to the collection
- Requires development environment setup
- Source code access and modification
- Testing and build processes

### Content Characteristics

#### Tutorials (Learning-Oriented)
- **Hands-on**: You actually configure systems
- **Safe**: Won't break existing setups when followed correctly
- **Progressive**: Each tutorial builds on previous knowledge
- **Outcome-focused**: Clear learning objectives

#### How-To Guides (Problem-Oriented)
- **Goal-oriented**: Solve specific problems efficiently
- **Practical**: Real-world scenarios and solutions
- **Assumes knowledge**: Basic familiarity with the collection
- **Task-focused**: Get from problem to solution quickly

#### Reference (Information-Oriented)
- **Comprehensive**: Complete coverage of features
- **Factual**: Based directly on code and specifications
- **Searchable**: Organized for quick lookup
- **Precise**: Exact syntax and parameters

#### Explanations (Understanding-Oriented)
- **Conceptual**: Explains the "why" behind decisions
- **Contextual**: Provides broader perspective
- **Discussion-oriented**: Explores topics in depth
- **Connects ideas**: Shows relationships between concepts

## 🔄 Documentation Maintenance

### Documentation-as-Code Approach

This documentation follows the "documentation-as-code" principle:

1. **Version Controlled**: Documentation lives alongside code
2. **Automated Updates**: Generated from code annotations where possible
3. **Review Process**: Documentation changes go through same review as code
4. **Continuous Integration**: Documentation is tested and validated

### Update Process

When code changes, documentation is updated following this process:

1. **Identify Impact**: Determine which documentation sections are affected
2. **Update Content**: Modify relevant documentation files
3. **Validate Changes**: Ensure accuracy and completeness
4. **Review Process**: Documentation changes reviewed with code changes

### Quality Assurance

- **Accuracy**: Documentation tested against actual code behavior
- **Completeness**: All features and options documented
- **Clarity**: Written for the intended audience
- **Currency**: Kept up-to-date with code changes

## 🎓 Using This Documentation Effectively

### Finding Information

**"I want to learn the basics"**
→ Start with [Tutorials](tutorials/)

**"I need to solve a specific problem"**
→ Check [How-To Guides](how-to-guides/)

**"I want to contribute to the project"**
→ See [Developer How-To Guides](how-to-guides/developer/)

**"I need technical specifications"**
→ Look in [Reference](reference/)

**"I want to understand the design"**
→ Read [Explanations](explanations/)

### Learning Paths

#### Beginner Path
1. [Your First KVM Host Setup](tutorials/01-first-kvm-host-setup.md)
2. [Basic Network Configuration](tutorials/02-basic-network-configuration.md)
3. [Storage Pool Creation](tutorials/03-storage-pool-creation.md)
4. Explore [How-To Guides](how-to-guides/) based on your needs

#### Advanced User Path
1. Review [Architecture Overview](explanations/architecture-overview.md)
2. Explore specific [How-To Guides](how-to-guides/) for your use cases
3. Reference [Technical Documentation](reference/) as needed
4. Understand [Design Decisions](explanations/) for complex deployments

#### Contributor Path
1. [Set Up Development Environment](how-to-guides/developer/setup-development-environment.md)
2. [Run Molecule Tests](how-to-guides/developer/run-molecule-tests.md)
3. [Contributing Guidelines](how-to-guides/developer/contributing-guidelines.md)
4. Study [Architecture](explanations/) and [ADRs](../adrs/)

## 🤝 Community and Support

### Getting Help
- **GitHub Issues**: [Report bugs or request features](https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues)
- **GitHub Discussions**: [Community questions and support](https://github.com/Qubinode/qubinode_kvmhost_setup_collection/discussions)
- **Documentation**: Search this documentation for answers

### Contributing to Documentation
- **Report Issues**: Found errors or missing information? [Create an issue](https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues)
- **Suggest Improvements**: Ideas for better documentation? [Start a discussion](https://github.com/Qubinode/qubinode_kvmhost_setup_collection/discussions)
- **Contribute Content**: Follow [Contributing Guidelines](how-to-guides/developer/contributing-guidelines.md)

## 🔗 External Resources

### Ansible Resources
- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Collection Development Guide](https://docs.ansible.com/ansible/devel/dev_guide/developing_collections.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

### KVM and Virtualization
- [KVM Documentation](https://www.linux-kvm.org/page/Documents)
- [Libvirt Documentation](https://libvirt.org/docs.html)
- [QEMU Documentation](https://qemu.readthedocs.io/)

### Testing and Development
- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Testinfra Documentation](https://testinfra.readthedocs.io/)
- [Ansible Lint Documentation](https://ansible-lint.readthedocs.io/)

---

*This documentation is organized to help you find exactly what you need, when you need it. Start with tutorials if you're learning, use how-to guides for specific problems, reference for technical details, and explanations for deeper understanding.*
