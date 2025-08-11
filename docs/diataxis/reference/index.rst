Reference Documentation - Technical Specifications
================================================

Welcome to the reference documentation! This section provides comprehensive technical specifications, API documentation, and configuration details for the Qubinode KVM Host Setup Collection.

.. note::
   **Looking for learning materials?** Check out our :doc:`../tutorials/index` section. **Need to solve a specific problem?** See our :doc:`../how-to-guides/index` section.

Quick Reference
---------------

.. grid:: 1 1 2 2
    :gutter: 3

    .. grid-item-card:: 📦 Collection Metadata
        :link: collection-metadata
        :link-type: doc

        **Collection Information**
        
        Version, dependencies, Galaxy information, and distribution details.

    .. grid-item-card:: 🖥️ Platform Support
        :link: supported-platforms
        :link-type: doc

        **Supported Platforms**
        
        Complete compatibility matrix, system requirements, and feature support.

    .. grid-item-card:: 🎛️ Main Role Reference
        :link: roles/kvmhost_setup
        :link-type: doc

        **kvmhost_setup Role**
        
        Complete reference for the main orchestration role including all variables and options.

    .. grid-item-card:: 🔧 Global Variables
        :link: variables/global-variables
        :link-type: doc

        **Global Variables**
        
        Collection-wide variables that affect multiple roles and overall behavior.

Technical Specifications
------------------------

### APIs and Interfaces
.. toctree::
   :maxdepth: 1

   apis/role-interfaces

### Standards and Conventions
.. toctree::
   :maxdepth: 1

   standards/variable-naming

### Role Documentation
.. toctree::
   :maxdepth: 1

   roles/kvmhost_setup

### Variable References
.. toctree::
   :maxdepth: 1

   variables/global-variables

### Platform Information
.. toctree::
   :maxdepth: 1

   supported-platforms
   collection-metadata

Reference Categories
--------------------

### Collection Information
- :doc:`collection-metadata` - Galaxy metadata, versioning, dependencies
- :doc:`supported-platforms` - Platform compatibility and requirements

### Role References
- :doc:`roles/kvmhost_setup` - Main orchestration role
- Additional role references (coming soon)

### Variable Documentation
- :doc:`variables/global-variables` - Collection-wide variables
- Role-specific variables (coming soon)

### API Documentation
- :doc:`apis/role-interfaces` - Role interface standards and contracts

### Standards and Conventions
- :doc:`standards/variable-naming` - Variable naming conventions
- Code style standards (coming soon)

Using Reference Documentation
-----------------------------

### Finding Information

**Looking for a specific variable?**
→ :doc:`variables/global-variables` or role-specific documentation

**Need role details?**
→ :doc:`roles/kvmhost_setup` or specific role documentation

**Checking compatibility?**
→ :doc:`supported-platforms` for platform support matrix

**Understanding interfaces?**
→ :doc:`apis/role-interfaces` for role contracts and standards

### Reference Characteristics

All reference documentation:

- **Is comprehensive**: Complete coverage of features and options
- **Is factual**: Based directly on code and specifications  
- **Is searchable**: Organized for quick lookup and discovery
- **Is precise**: Exact syntax, parameters, and specifications
- **Is current**: Automatically updated with code changes

Technical Details
-----------------

### System Requirements
- **Ansible**: 2.13 or newer
- **Python**: 3.9 or newer
- **Platforms**: RHEL 8/9/10, Rocky Linux, AlmaLinux
- **Hardware**: CPU with virtualization support, 8GB+ RAM

### Dependencies
- **Collections**: community.libvirt, ansible.posix, community.general
- **System Packages**: libvirt, qemu-kvm, NetworkManager
- **Python Modules**: libvirt-python, lxml, netaddr

### Installation Methods
.. code-block:: bash

   # From Ansible Galaxy
   ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection

   # From Git repository
   ansible-galaxy collection install git+https://github.com/Qubinode/qubinode_kvmhost_setup_collection.git

   # Specific version
   ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection:==0.9.7

Configuration Examples
----------------------

### Basic Configuration
.. code-block:: yaml

   - hosts: kvm_hosts
     become: true
     vars:
       admin_user: "kvmadmin"
       kvm_host_ipaddr: "192.168.1.100"
       kvm_host_interface: "ens3"
     roles:
       - tosin2013.qubinode_kvmhost_setup_collection.kvmhost_setup

### Advanced Configuration
.. code-block:: yaml

   - hosts: kvm_hosts
     become: true
     vars:
       admin_user: "kvmadmin"
       kvm_host_ipaddr: "10.0.1.100"
       kvm_host_interface: "ens3"
       enable_cockpit: true
       enable_kvm_performance_optimization: true
       qubinode_bridge_name: "kvmbr0"
     roles:
       - tosin2013.qubinode_kvmhost_setup_collection.kvmhost_setup

Getting Help
------------

### For Technical Questions
- **Search this reference**: Use search (Ctrl+K) to find specific information
- **Check examples**: Look for configuration examples in role documentation
- **Review variables**: Check variable documentation for available options

### For Implementation Help
- **How-to guides**: :doc:`../how-to-guides/index` for practical solutions
- **Tutorials**: :doc:`../tutorials/index` for step-by-step guidance
- **Community support**: `GitHub Discussions <https://github.com/Qubinode/qubinode_kvmhost_setup_collection/discussions>`_

Related Documentation
---------------------

- **Learning**: :doc:`../tutorials/index` - Step-by-step learning guides
- **Problem-Solving**: :doc:`../how-to-guides/index` - Practical solutions
- **Contributing**: :doc:`../how-to-guides/developer/index` - Development guides
- **Understanding**: :doc:`../explanations/index` - Architecture and concepts

.. toctree::
   :maxdepth: 2
   :hidden:
   :caption: Reference Documentation

   collection-metadata
   supported-platforms
   roles/kvmhost_setup
   variables/global-variables
   apis/role-interfaces
   standards/variable-naming
