# Quick Start Guide

This quick start guide is for experienced users who want to get a KVM host up and running immediately with minimal configuration. If you're new to the collection, start with [Your First KVM Host Setup](01-first-kvm-host-setup.md) instead.

## 🎯 What You'll Accomplish

In 10 minutes or less, you'll have:
- A fully configured KVM host
- Network bridge for VM connectivity
- Storage pools for VM disks
- Cockpit web interface for management

## ⚡ Prerequisites Check

Before starting, ensure you have:
- RHEL 8/9, Rocky Linux 8/9, or AlmaLinux 8/9
- CPU with virtualization support (Intel VT-x or AMD-V)
- Minimum 8GB RAM (16GB recommended)
- Administrative access (sudo/root)
- Ansible 2.13+ installed

### Quick System Verification

Run this one-liner to check your system:

```bash
# Quick compatibility check
curl -s https://raw.githubusercontent.com/Qubinode/qubinode_kvmhost_setup_collection/main/scripts/system-check.sh | bash
```

Or manual check:
```bash
# Check OS
cat /etc/os-release | grep -E "(rhel|rocky|almalinux)"

# Check virtualization support
grep -E "(vmx|svm)" /proc/cpuinfo

# Check memory
free -h | grep Mem

# Check Ansible
ansible --version
```

## 🚀 One-Command Setup

For the absolute fastest setup on a fresh system:

```bash
# Install collection and run complete setup
ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection && \
ansible-playbook -i localhost, -c local -b \
  -e admin_user=$USER \
  -e kvm_host_ipaddr=$(hostname -I | awk '{print $1}') \
  -e kvm_host_interface=$(ip route | grep default | awk '{print $5}' | head -1) \
  -e kvm_host_gw=$(ip route | grep default | awk '{print $3}' | head -1) \
  ~/.ansible/collections/ansible_collections/tosin2013/qubinode_kvmhost_setup_collection/playbooks/kvmhost_setup.yml
```

## 📝 Standard Quick Setup

For more control over the configuration:

### Step 1: Install Collection
```bash
ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection
```

### Step 2: Create Minimal Playbook
```bash
cat > quick-setup.yml << 'EOF'
---
- name: Quick KVM Host Setup
  hosts: localhost
  connection: local
  become: true
  vars:
    admin_user: "{{ ansible_user }}"
    kvm_host_ipaddr: "{{ ansible_default_ipv4.address }}"
    kvm_host_interface: "{{ ansible_default_ipv4.interface }}"
    kvm_host_gw: "{{ ansible_default_ipv4.gateway }}"
    kvm_host_netmask: "{{ ansible_default_ipv4.netmask }}"
    kvm_host_mask_prefix: 24
    
  roles:
    - tosin2013.qubinode_kvmhost_setup_collection.kvmhost_setup
EOF
```

### Step 3: Run Setup
```bash
ansible-playbook quick-setup.yml
```

## ✅ Verify Installation

### Quick Health Check
```bash
# Check services
sudo systemctl status libvirtd
sudo systemctl status NetworkManager

# Check bridge
ip addr show qubibr0

# Check storage
sudo virsh pool-list

# Check Cockpit (if enabled)
curl -k https://localhost:9090
```

### Access Cockpit Web Interface
Open your browser to: `https://YOUR_HOST_IP:9090`

## 🔧 Common Quick Customizations

### Custom Network Configuration
```bash
# Run with custom network settings
ansible-playbook quick-setup.yml \
  -e kvm_host_ipaddr=192.168.1.100 \
  -e kvm_host_interface=ens3 \
  -e kvm_host_gw=192.168.1.1 \
  -e qubinode_bridge_name=kvmbr0
```

### Minimal Installation (No Cockpit)
```bash
# Skip web interface installation
ansible-playbook quick-setup.yml \
  -e enable_cockpit=false \
  -e configure_shell=false
```

### Development Environment
```bash
# Setup for development/testing
ansible-playbook quick-setup.yml \
  -e cicd_test=true \
  -e enable_kvm_performance_optimization=false
```

## 🆘 Quick Troubleshooting

### Installation Fails
```bash
# Check Ansible version
ansible --version  # Must be 2.13+

# Check collection installation
ansible-galaxy collection list | grep qubinode

# Reinstall if needed
ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection --force
```

### Network Issues
```bash
# Check NetworkManager
sudo systemctl status NetworkManager

# Reset network if needed
sudo nmcli connection reload
```

### Permission Issues
```bash
# Ensure running with sudo/become
ansible-playbook quick-setup.yml --ask-become-pass

# Check user permissions
groups $USER | grep -E "(wheel|sudo)"
```

## 🔄 What's Next?

After quick setup, you can:

1. **Create your first VM** using Cockpit web interface
2. **Learn more** with [detailed tutorials](01-first-kvm-host-setup.md)
3. **Customize further** with [how-to guides](../how-to-guides/)
4. **Understand the architecture** with [explanations](../explanations/)

## 📚 Full Documentation

This quick start gets you running fast, but for comprehensive understanding:

- **New to KVM?** Start with [Your First KVM Host Setup](01-first-kvm-host-setup.md)
- **Need specific solutions?** Check [How-To Guides](../how-to-guides/)
- **Want technical details?** See [Reference Documentation](../reference/)
- **Curious about design?** Read [Explanations](../explanations/)

## 🔗 Related Documentation

- **Detailed Setup**: [Your First KVM Host Setup](01-first-kvm-host-setup.md)
- **Network Configuration**: [Basic Network Configuration](02-basic-network-configuration.md)
- **Troubleshooting**: [Troubleshoot Network Issues](../how-to-guides/troubleshoot-networking.md)
- **Reference**: [Collection Metadata](../reference/collection-metadata.md)

---

*This quick start is designed for speed. For learning and understanding, use the comprehensive tutorials and guides.*
