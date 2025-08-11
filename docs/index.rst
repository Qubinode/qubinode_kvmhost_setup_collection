Qubinode KVM Host Setup Collection Documentation
=================================================

Welcome to the comprehensive documentation for the **Qubinode KVM Host Setup Collection** - an Ansible collection that provides automated setup and management of KVM hosts on RHEL-based systems.

This documentation follows the `Diátaxis framework <https://diataxis.fr/>`_ to provide you with exactly the information you need, when you need it.

.. grid:: 2
    :gutter: 3

    .. grid-item-card:: 📚 Tutorials
        :link: diataxis/tutorials/index
        :link-type: doc
        :class-header: bg-primary text-white

        **Learning-oriented guides**
        
        Step-by-step tutorials to help you learn by doing. Perfect for newcomers who want to get started with the collection.

    .. grid-item-card:: 🛠️ How-To Guides  
        :link: diataxis/how-to-guides/index
        :link-type: doc
        :class-header: bg-success text-white

        **Problem-oriented guides**
        
        Practical solutions for specific problems. Use these when you have a particular goal to accomplish.

    .. grid-item-card:: 👨‍💻 Developer Guides
        :link: diataxis/how-to-guides/developer/index
        :link-type: doc
        :class-header: bg-warning text-dark

        **Contribution-oriented guides**
        
        Everything you need to contribute to the project, from setting up your development environment to submitting pull requests.

    .. grid-item-card:: 📖 Reference
        :link: diataxis/reference/index
        :link-type: doc
        :class-header: bg-info text-white

        **Information-oriented documentation**
        
        Complete technical specifications, API documentation, and configuration references.

    .. grid-item-card:: 💡 Explanations
        :link: diataxis/explanations/index
        :link-type: doc
        :class-header: bg-secondary text-white

        **Understanding-oriented documentation**
        
        Architecture, design decisions, and concepts that help you understand how and why the collection works.

    .. grid-item-card:: 🚀 Quick Start
        :link: diataxis/tutorials/00-quick-start
        :link-type: doc
        :class-header: bg-danger text-white

        **Get started in 10 minutes**
        
        Rapid setup guide for experienced users who want to get running immediately.

Quick Navigation
----------------

.. tab-set::

    .. tab-item:: New Users

        **Start your journey here:**

        1. :doc:`Quick Start Guide <diataxis/tutorials/00-quick-start>` - Get running in 10 minutes
        2. :doc:`Your First KVM Host Setup <diataxis/tutorials/01-first-kvm-host-setup>` - Comprehensive beginner guide
        3. :doc:`Basic Network Configuration <diataxis/tutorials/02-basic-network-configuration>` - Learn networking
        4. :doc:`Storage Pool Creation <diataxis/tutorials/03-storage-pool-creation>` - Manage storage

    .. tab-item:: Experienced Users

        **Solve specific problems:**

        - :doc:`Configure Custom Bridges <diataxis/how-to-guides/configure-custom-bridges>` - Advanced networking
        - :doc:`Manage Storage Pools <diataxis/how-to-guides/manage-storage-pools>` - Storage management
        - :doc:`Troubleshoot Networks <diataxis/how-to-guides/troubleshoot-networking>` - Fix network issues
        - :doc:`Reference Documentation <diataxis/reference/index>` - Technical specifications

    .. tab-item:: Contributors

        **Contribute to the project:**

        1. :doc:`Development Environment <diataxis/how-to-guides/developer/setup-development-environment>` - Set up dev environment
        2. :doc:`Run Tests <diataxis/how-to-guides/developer/run-molecule-tests>` - Testing procedures
        3. :doc:`Contributing Guidelines <diataxis/how-to-guides/developer/contributing-guidelines>` - Contribution process
        4. :doc:`Architecture Overview <diataxis/explanations/architecture-overview>` - Understand the design

Collection Overview
-------------------

The Qubinode KVM Host Setup Collection provides:

- **Automated KVM Host Setup**: Complete automation for RHEL-based KVM hosts
- **Modular Architecture**: Nine specialized roles for different aspects of setup
- **Platform Support**: RHEL 8/9/10, Rocky Linux, AlmaLinux
- **Comprehensive Testing**: Molecule-based testing framework
- **Production Ready**: Used in enterprise environments

Key Features
~~~~~~~~~~~~

.. list-table::
   :widths: 25 75
   :header-rows: 1

   * - Feature
     - Description
   * - **Base System Setup**
     - RHEL detection, package management, EPEL configuration
   * - **Network Configuration**
     - Bridge creation, interface management, connectivity validation
   * - **Virtualization Setup**
     - Libvirt configuration, KVM optimization, hardware detection
   * - **Storage Management**
     - Storage pools, LVM configuration, performance tuning
   * - **Web Interface**
     - Cockpit installation, SSL configuration, user management
   * - **User Environment**
     - Shell configuration, SSH setup, development tools

Installation
~~~~~~~~~~~~

.. code-block:: bash

   # Install from Ansible Galaxy
   ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection

   # Quick setup
   ansible-playbook -i localhost, -c local -b \
     -e admin_user=$USER \
     ~/.ansible/collections/ansible_collections/tosin2013/qubinode_kvmhost_setup_collection/playbooks/kvmhost_setup.yml

Support and Community
~~~~~~~~~~~~~~~~~~~~~

- **GitHub Repository**: `Qubinode KVM Host Setup Collection <https://github.com/Qubinode/qubinode_kvmhost_setup_collection>`_
- **Issue Tracker**: `Report Issues <https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues>`_
- **Discussions**: `Community Support <https://github.com/Qubinode/qubinode_kvmhost_setup_collection/discussions>`_
- **Ansible Galaxy**: `Collection Page <https://galaxy.ansible.com/tosin2013/qubinode_kvmhost_setup_collection>`_

Documentation Structure
-----------------------

This documentation is organized according to the `Diátaxis framework <https://diataxis.fr/>`_, which provides four types of documentation based on user needs:

.. toctree::
   :maxdepth: 2
   :caption: 📚 Tutorials (Learning-Oriented)
   :hidden:

   diataxis/tutorials/index
   diataxis/tutorials/00-quick-start
   diataxis/tutorials/01-first-kvm-host-setup
   diataxis/tutorials/02-basic-network-configuration
   diataxis/tutorials/03-storage-pool-creation

.. toctree::
   :maxdepth: 2
   :caption: 🛠️ How-To Guides (Problem-Oriented)
   :hidden:

   diataxis/how-to-guides/index
   diataxis/how-to-guides/configure-custom-bridges
   diataxis/how-to-guides/manage-storage-pools
   diataxis/how-to-guides/troubleshoot-networking

.. toctree::
   :maxdepth: 2
   :caption: 👨‍💻 Developer Guides (Contribution-Oriented)
   :hidden:

   diataxis/how-to-guides/developer/index
   diataxis/how-to-guides/developer/setup-development-environment
   diataxis/how-to-guides/developer/run-molecule-tests
   diataxis/how-to-guides/developer/contributing-guidelines
   diataxis/how-to-guides/developer/setup-dependabot-automation
   diataxis/how-to-guides/developer/migrate-molecule-tests
   diataxis/how-to-guides/developer/local-testing-requirements

.. toctree::
   :maxdepth: 2
   :caption: 📖 Reference (Information-Oriented)
   :hidden:

   diataxis/reference/index
   diataxis/reference/collection-metadata
   diataxis/reference/supported-platforms
   diataxis/reference/roles/kvmhost_setup
   diataxis/reference/variables/global-variables
   diataxis/reference/apis/role-interfaces
   diataxis/reference/standards/variable-naming

.. toctree::
   :maxdepth: 2
   :caption: 💡 Explanations (Understanding-Oriented)
   :hidden:

   diataxis/explanations/index
   diataxis/explanations/architecture-overview
   diataxis/explanations/modular-role-design
   diataxis/explanations/automation-philosophy
   diataxis/explanations/architecture-decisions/index

.. toctree::
   :maxdepth: 1
   :caption: 📋 Project Information
   :hidden:

   README
   DIATAXIS_MIGRATION_PLAN
   MIGRATION_COMPLETION_SUMMARY

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
