How-To Guides - Problem-Oriented Solutions
==========================================

Welcome to the how-to guides section! These practical guides help you solve specific problems and accomplish particular goals with the Qubinode KVM Host Setup Collection.

.. note::
   **Looking for learning materials?** Check out our :doc:`../tutorials/index` section. **Contributing to the project?** See our :doc:`developer/index` section.

Quick Problem Solving
----------------------

.. grid:: 1 1 2 2
    :gutter: 3

    .. grid-item-card:: 🌐 Network Configuration
        :link: configure-custom-bridges
        :link-type: doc

        **Configure Custom Network Bridges**
        
        Set up specialized network configurations for VLANs, management networks, and high-performance scenarios.

    .. grid-item-card:: 💾 Storage Management
        :link: manage-storage-pools
        :link-type: doc

        **Manage Storage Pools**
        
        Create, resize, monitor, and maintain storage pools throughout their lifecycle.

    .. grid-item-card:: 🔧 Troubleshooting
        :link: troubleshoot-networking
        :link-type: doc

        **Troubleshoot Network Issues**
        
        Diagnose and resolve common networking problems in your KVM environment.

Problem Categories
------------------

### Network Configuration
- :doc:`configure-custom-bridges` - Advanced bridge configurations
- :doc:`troubleshoot-networking` - Network problem diagnosis and resolution

### Storage Management  
- :doc:`manage-storage-pools` - Complete storage pool lifecycle management

### System Administration
- Coming soon: VM management, backup configuration, monitoring setup

How-To Guide Characteristics
-----------------------------

All how-to guides in this section:

- **Are goal-oriented**: Help you accomplish specific tasks
- **Assume basic knowledge**: You should be familiar with the collection basics
- **Provide practical solutions**: Real-world scenarios and working examples
- **Are task-focused**: Get you from problem to solution efficiently
- **Include troubleshooting**: Common issues and their solutions

When to Use How-To Guides
-------------------------

Use these guides when you:

- **Have a specific problem** to solve
- **Know what you want to accomplish** but need guidance on how
- **Need practical examples** for real-world scenarios
- **Want efficient solutions** without extensive explanation
- **Are comfortable** with the collection basics

Prerequisites
-------------

Before using these guides:

- **Complete basic setup**: Follow :doc:`../tutorials/01-first-kvm-host-setup` first
- **Understand fundamentals**: Basic familiarity with KVM, networking, and storage concepts
- **Have working environment**: Functional KVM host with the collection installed
- **Administrative access**: Sudo/root access to make system changes

Finding Solutions
-----------------

### By Problem Type

**Network Issues**
- Bridge not working → :doc:`troubleshoot-networking`
- Need custom networking → :doc:`configure-custom-bridges`

**Storage Issues**
- Storage pool problems → :doc:`manage-storage-pools`
- Performance issues → :doc:`manage-storage-pools` (optimization section)

**System Issues**
- General troubleshooting → :doc:`troubleshoot-networking` (general techniques)

### By Use Case

**Production Deployment**
- :doc:`configure-custom-bridges` - Production network setup
- :doc:`manage-storage-pools` - Production storage management

**Development Environment**
- :doc:`troubleshoot-networking` - Development troubleshooting
- :doc:`../tutorials/02-basic-network-configuration` - Basic dev setup

**Testing Environment**
- :doc:`developer/index` - Development and testing procedures

Getting Help
------------

If these guides don't solve your problem:

1. **Check tutorials**: :doc:`../tutorials/index` for foundational knowledge
2. **Search documentation**: Use search (Ctrl+K) to find related information
3. **Review reference**: :doc:`../reference/index` for technical specifications
4. **Ask the community**: `GitHub Discussions <https://github.com/Qubinode/qubinode_kvmhost_setup_collection/discussions>`_
5. **Report issues**: `GitHub Issues <https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues>`_

Related Documentation
---------------------

- **Learning**: :doc:`../tutorials/index` - Step-by-step learning guides
- **Contributing**: :doc:`developer/index` - Developer and contribution guides  
- **Technical Details**: :doc:`../reference/index` - Complete technical reference
- **Understanding**: :doc:`../explanations/index` - Architecture and design concepts

.. toctree::
   :maxdepth: 2
   :hidden:
   :caption: Available How-To Guides

   configure-custom-bridges
   manage-storage-pools
   troubleshoot-networking
