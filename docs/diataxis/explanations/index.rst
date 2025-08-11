Explanations - Understanding-Oriented Documentation
==================================================

Welcome to the explanations section! This documentation helps you understand the concepts, architecture, and design decisions behind the Qubinode KVM Host Setup Collection.

.. note::
   **Need practical guidance?** Check out our :doc:`../tutorials/index` for learning or :doc:`../how-to-guides/index` for problem-solving.

Understanding the Collection
----------------------------

.. grid:: 1 1 2 2
    :gutter: 3

    .. grid-item-card:: 🏗️ Architecture Overview
        :link: architecture-overview
        :link-type: doc

        **System Architecture**
        
        High-level design principles, component relationships, and architectural patterns used throughout the collection.

    .. grid-item-card:: 🧩 Modular Design
        :link: modular-role-design
        :link-type: doc

        **Modular Role Design**
        
        Why we chose a modular approach and how it benefits users, developers, and the project ecosystem.

    .. grid-item-card:: 🤖 Automation Philosophy
        :link: automation-philosophy
        :link-type: doc

        **Automation Framework**
        
        The comprehensive automation philosophy that guides development, testing, and deployment processes.

    .. grid-item-card:: 📋 Design Decisions
        :link: architecture-decisions/index
        :link-type: doc

        **Architecture Decision Records**
        
        Detailed records of all major architectural decisions, their context, and consequences.

Key Concepts
------------

### Architectural Principles

**Modularity**
The collection is built on modular principles where each role has a specific, well-defined responsibility. This enables:

- **Separation of Concerns**: Each role focuses on one aspect
- **Reusability**: Roles can be used independently or together
- **Maintainability**: Changes to one component don't affect others
- **Testability**: Each role can be tested in isolation

**Idempotency**
All operations are designed to be idempotent, meaning:

- **Safe Re-execution**: Can be run multiple times safely
- **State Convergence**: Brings system to desired state regardless of current state
- **Change Detection**: Only makes changes when necessary

**Configuration-Driven**
The collection uses extensive configuration to adapt to different environments:

- **Environment Flexibility**: Same code works across dev, staging, production
- **Platform Abstraction**: Supports multiple RHEL-based distributions
- **Feature Toggles**: Enable/disable features based on requirements

### Design Patterns

**Layered Architecture**
The collection implements a layered architecture:

.. code-block:: text

   ┌─────────────────────────────────────────┐
   │           Orchestration Layer           │
   │            (kvmhost_setup)              │
   ├─────────────────────────────────────────┤
   │          Application Layer              │
   │    (cockpit, user_config, storage)     │
   ├─────────────────────────────────────────┤
   │         Infrastructure Layer           │
   │      (libvirt, networking, base)       │
   ├─────────────────────────────────────────┤
   │           Foundation Layer              │
   │        (OS, hardware, services)        │
   └─────────────────────────────────────────┘

**Event-Driven Communication**
Roles communicate through Ansible facts and handlers:

- **Facts**: Roles set facts that other roles can use
- **Handlers**: Asynchronous event handling for service management
- **Dependencies**: Clear dependency chains ensure proper execution order

Design Philosophy
-----------------

### User-Centric Design
The collection is designed with users in mind:

- **Simplicity**: Complex tasks made simple through automation
- **Flexibility**: Configurable for different use cases
- **Reliability**: Consistent, predictable behavior
- **Documentation**: Comprehensive, user-focused documentation

### Developer-Friendly Architecture
The architecture supports effective development:

- **Modularity**: Clear separation of concerns
- **Testability**: Comprehensive testing framework
- **Extensibility**: Easy to add new features
- **Standards**: Consistent coding and documentation standards

### Operational Excellence
The design supports operational requirements:

- **Automation**: Reduced manual intervention
- **Monitoring**: Built-in health checks and validation
- **Scalability**: Supports growth and expansion
- **Security**: Security best practices built-in

Evolution and History
---------------------

### Project Evolution
The collection has evolved through several phases:

1. **Foundation Phase**: Basic role structure and core functionality
2. **Enhancement Phase**: Advanced features and platform support
3. **Automation Phase**: CI/CD integration and automated processes
4. **Documentation Phase**: Comprehensive documentation framework

### Key Milestones
- **Modular Architecture**: ADR-0002 established the modular foundation
- **Testing Framework**: ADR-0005 integrated Molecule testing
- **Platform Support**: ADR-0008 extended RHEL 9/10 support
- **Automation Strategy**: ADR-0009 implemented Dependabot automation

### Lessons Learned
- **Start Simple**: Begin with basic functionality, add complexity gradually
- **Test Early**: Comprehensive testing prevents issues
- **Document Decisions**: ADRs capture reasoning behind choices
- **User Feedback**: Regular user feedback drives improvements

Understanding Through Examples
------------------------------

### Architectural Patterns in Action

**Dependency Resolution Example**:

.. code-block:: yaml

   # kvmhost_setup orchestrates dependencies
   dependencies:
     - kvmhost_base          # Foundation
     - kvmhost_networking    # Requires base
     - kvmhost_libvirt      # Requires base + networking
     - kvmhost_storage      # Requires base + libvirt

**Configuration Inheritance Example**:

.. code-block:: yaml

   # Base role provides foundation
   base_packages: [curl, wget, git]
   
   # Libvirt role extends
   libvirt_packages: "{{ base_packages + ['libvirt-daemon', 'qemu-kvm'] }}"
   
   # Storage role further extends
   storage_packages: "{{ libvirt_packages + ['lvm2', 'parted'] }}"

Research and Analysis
---------------------

The explanations in this section are based on:

- **Industry Best Practices**: Ansible, DevOps, and infrastructure automation standards
- **User Feedback**: Real-world usage patterns and requirements
- **Performance Analysis**: Benchmarking and optimization research
- **Security Research**: Security best practices and compliance requirements

Related Documentation
---------------------

- **Implementation**: :doc:`../tutorials/index` - Learn by implementing
- **Problem-Solving**: :doc:`../how-to-guides/index` - Solve specific issues
- **Technical Details**: :doc:`../reference/index` - Look up specifications
- **Contributing**: :doc:`../how-to-guides/developer/index` - Contribute to the project

.. toctree::
   :maxdepth: 2
   :hidden:
   :caption: Explanations

   architecture-overview
   modular-role-design
   automation-philosophy
   architecture-decisions/index
