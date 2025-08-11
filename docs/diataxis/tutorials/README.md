# Tutorials - Learning-Oriented Documentation

Welcome to the tutorials section! These step-by-step guides are designed to help you learn by doing. Each tutorial focuses on getting you started with the Qubinode KVM Host Setup Collection and building your confidence through hands-on experience.

## 🎯 What You'll Find Here

Tutorials are **learning-oriented** and designed for newcomers who want to:
- Get started with the collection quickly
- Learn fundamental concepts through practical examples
- Build confidence with guided, step-by-step instructions
- Understand how different components work together

## 📋 Available Tutorials

### Getting Started
- [Your First KVM Host Setup](01-first-kvm-host-setup.md) - Complete walkthrough from installation to running VMs
- [Basic Network Configuration](02-basic-network-configuration.md) - Set up networking for your KVM environment
- [Storage Pool Creation](03-storage-pool-creation.md) - Create and manage storage for virtual machines

### Intermediate Tutorials
- [Multi-Host KVM Environment](04-multi-host-environment.md) - Scale beyond a single host
- [Advanced Networking with Bridges](05-advanced-networking.md) - Complex network topologies
- [Automated VM Deployment](06-automated-vm-deployment.md) - Deploy VMs using the collection

## 🎓 Tutorial Characteristics

Each tutorial in this section:
- **Starts from the beginning** - No prior knowledge assumed
- **Is hands-on** - You'll actually configure a real KVM environment
- **Has a clear learning outcome** - You'll know what you've accomplished
- **Uses the deployed collection** - Works with installed collection, not source code
- **Is safe to follow** - Won't break existing systems when followed correctly

## 🚀 Before You Start

### Prerequisites
- A RHEL-based system (RHEL 8/9, Rocky Linux, AlmaLinux, CentOS Stream)
- Ansible installed on your control machine
- Basic familiarity with command line operations
- Administrative access to your target system(s)

### Installation
Make sure you have the collection installed:
```bash
ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection
```

## 🔄 Tutorial Flow

We recommend following tutorials in order, as later tutorials build on concepts from earlier ones:

1. **Start Here**: [Your First KVM Host Setup](01-first-kvm-host-setup.md)
2. **Then**: [Basic Network Configuration](02-basic-network-configuration.md)
3. **Next**: [Storage Pool Creation](03-storage-pool-creation.md)
4. **Advanced**: Continue with intermediate tutorials based on your needs

## 💡 Learning Tips

- **Take your time** - These tutorials are designed for learning, not speed
- **Experiment** - Try variations once you complete a tutorial
- **Ask questions** - Use our [issue tracker](https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues) for help
- **Practice** - Repeat tutorials in different environments to reinforce learning

## 🔗 What's Next?

After completing tutorials, you might want to:
- Explore [How-To Guides](../how-to-guides/) for specific problem-solving
- Check the [Reference](../reference/) for detailed configuration options
- Read [Explanations](../explanations/) to understand the architecture better

---

*These tutorials focus on using the collection as an end-user. If you want to contribute to the collection's development, see [Developer How-To Guides](../how-to-guides/developer/).*
