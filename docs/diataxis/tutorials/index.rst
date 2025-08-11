Tutorials - Learning-Oriented Guides
====================================

Welcome to the tutorials section! These step-by-step guides will help you learn the Qubinode KVM Host Setup Collection by doing. Each tutorial is designed to be completed in sequence, building your knowledge progressively.

.. note::
   **New to the collection?** Start with the :doc:`00-quick-start` guide for a rapid introduction, or :doc:`01-first-kvm-host-setup` for a comprehensive learning experience.

Getting Started
---------------

.. grid:: 1 1 2 2
    :gutter: 3

    .. grid-item-card:: 🚀 Quick Start
        :link: 00-quick-start
        :link-type: doc

        **10-minute setup for experienced users**
        
        Get a KVM host running immediately with minimal configuration. Perfect if you're already familiar with KVM and Ansible.

    .. grid-item-card:: 📚 Your First KVM Host Setup
        :link: 01-first-kvm-host-setup
        :link-type: doc

        **Comprehensive beginner guide**
        
        Complete walkthrough from installation to running VMs. Perfect for newcomers to KVM or the collection.

Core Tutorials
--------------

.. grid:: 1 1 2 2
    :gutter: 3

    .. grid-item-card:: 🌐 Basic Network Configuration
        :link: 02-basic-network-configuration
        :link-type: doc

        **Set up networking for VMs**
        
        Learn to configure network bridges, NAT networks, and isolated networks for different VM scenarios.

    .. grid-item-card:: 💾 Storage Pool Creation
        :link: 03-storage-pool-creation
        :link-type: doc

        **Manage storage for VMs**
        
        Create and manage storage pools, understand different storage types, and optimize for performance.

Learning Path
-------------

Follow this recommended learning path:

1. **Start Here**: :doc:`00-quick-start` (experienced) or :doc:`01-first-kvm-host-setup` (beginners)
2. **Networking**: :doc:`02-basic-network-configuration`
3. **Storage**: :doc:`03-storage-pool-creation`
4. **Next Steps**: Explore :doc:`../how-to-guides/index` for specific problems

Tutorial Characteristics
------------------------

All tutorials in this section:

- **Are learning-oriented**: Designed to help you learn by doing
- **Are safe to follow**: Won't break existing setups when followed correctly
- **Build progressively**: Each tutorial builds on previous knowledge
- **Have clear outcomes**: You'll know exactly what you've accomplished
- **Include verification**: Steps to confirm everything is working

What You'll Learn
-----------------

By completing these tutorials, you'll understand:

- **KVM Host Setup**: Complete automation of KVM host configuration
- **Network Management**: Bridge creation, network isolation, connectivity testing
- **Storage Management**: Storage pools, LVM configuration, performance optimization
- **Web Interface**: Cockpit setup and management
- **Best Practices**: Security, performance, and operational considerations

Prerequisites
-------------

Before starting the tutorials:

- **System**: RHEL 8/9/10, Rocky Linux, or AlmaLinux
- **Hardware**: CPU with virtualization support, 8GB+ RAM
- **Access**: Administrative (sudo/root) access
- **Network**: Internet connection for package downloads
- **Ansible**: Version 2.13 or newer

Getting Help
------------

If you encounter issues during tutorials:

1. **Check troubleshooting sections** in each tutorial
2. **Review common issues** in :doc:`../how-to-guides/troubleshoot-networking`
3. **Search documentation** using the search box (Ctrl+K)
4. **Ask for help** in `GitHub Discussions <https://github.com/Qubinode/qubinode_kvmhost_setup_collection/discussions>`_

Next Steps
----------

After completing tutorials:

- **Solve specific problems**: :doc:`../how-to-guides/index`
- **Contribute to the project**: :doc:`../how-to-guides/developer/index`
- **Look up technical details**: :doc:`../reference/index`
- **Understand the architecture**: :doc:`../explanations/index`

.. toctree::
   :maxdepth: 2
   :hidden:
   :caption: Available Tutorials

   00-quick-start
   01-first-kvm-host-setup
   02-basic-network-configuration
   03-storage-pool-creation
