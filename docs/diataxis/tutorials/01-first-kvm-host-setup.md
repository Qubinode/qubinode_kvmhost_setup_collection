# Your First KVM Host Setup

Welcome! This tutorial will guide you through setting up your first KVM host using the Qubinode KVM Host Setup Collection. By the end of this tutorial, you'll have a fully functional KVM environment ready to host virtual machines.

## 🎯 What You'll Learn

In this tutorial, you will:
- Install the Qubinode KVM Host Setup Collection
- Configure a basic KVM host environment
- Set up networking for virtual machines
- Create your first storage pool
- Verify your setup is working correctly

## 📋 What You'll Need

### System Requirements
- **Operating System**: RHEL 8/9, Rocky Linux 8/9, AlmaLinux 8/9, or CentOS Stream 9
- **Hardware**: 
  - CPU with virtualization support (Intel VT-x or AMD-V)
  - Minimum 8GB RAM (16GB recommended)
  - At least 50GB free disk space
- **Network**: Internet connection for package downloads
- **Access**: Root or sudo access to the target system

### Software Prerequisites
- **Ansible**: Version 2.13 or newer installed on your control machine
- **Python**: Version 3.9 or newer
- **SSH**: Access to your target KVM host

## 🚀 Step 1: Install the Collection

First, install the collection from Ansible Galaxy:

```bash
ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection
```

Verify the installation:
```bash
ansible-galaxy collection list | grep qubinode
```

You should see output similar to:
```
tosin2013.qubinode_kvmhost_setup_collection  0.9.7
```

## 📝 Step 2: Create Your Inventory

Create a simple inventory file for your KVM host:

```bash
mkdir -p ~/kvm-setup
cd ~/kvm-setup
```

Create `inventory.yml`:
```yaml
all:
  hosts:
    kvm-host:
      ansible_host: 192.168.1.100  # Replace with your host IP
      ansible_user: root            # Or your sudo user
      ansible_ssh_private_key_file: ~/.ssh/id_rsa  # Your SSH key
```

## ⚙️ Step 3: Create Your First Playbook

Create `setup-kvm-host.yml`:
```yaml
---
- name: Set up KVM Host
  hosts: kvm-host
  become: true
  vars:
    # Basic network configuration
    kvm_host_ipaddr: "192.168.1.100"      # Your host IP
    kvm_host_interface: "ens3"             # Your primary interface
    kvm_host_gw: "192.168.1.1"           # Your gateway
    kvm_host_netmask: "255.255.255.0"    # Your netmask
    kvm_host_mask_prefix: 24              # CIDR prefix
    
    # User configuration
    admin_user: "admin"                    # Your admin user
    
    # Network settings
    vm_libvirt_net: "qubinet"             # VM network name
    qubinode_bridge_name: "qubibr0"       # Bridge name
    
    # Basic settings
    configure_bridge: true                 # Enable bridge creation
    configure_shell: true                 # Configure shell environment
    
  roles:
    - tosin2013.qubinode_kvmhost_setup_collection.kvmhost_setup
```

## 🔧 Step 4: Configure Your Variables

Before running the playbook, customize the variables for your environment:

1. **Update network settings** in the playbook:
   - Replace `192.168.1.100` with your actual host IP
   - Replace `ens3` with your actual network interface name
   - Update gateway and netmask for your network

2. **Find your network interface**:
   ```bash
   # On your KVM host, run:
   ip addr show
   ```
   Look for the interface with your IP address.

## 🚀 Step 5: Run the Setup

Execute the playbook:

```bash
ansible-playbook -i inventory.yml setup-kvm-host.yml
```

The setup process will:
1. **Install base packages** - Essential KVM and virtualization packages
2. **Configure libvirt** - Set up the virtualization daemon
3. **Create network bridge** - Set up networking for VMs
4. **Configure storage** - Prepare storage pools for VM disks
5. **Set up Cockpit** - Install web management interface
6. **Configure user environment** - Set up shell and permissions

This process typically takes 5-10 minutes depending on your system and internet connection.

## ✅ Step 6: Verify Your Setup

### Check Libvirt Status
```bash
# On your KVM host:
sudo systemctl status libvirtd
sudo virsh list --all
```

### Verify Network Bridge
```bash
# Check bridge creation:
sudo nmcli connection show
sudo ip addr show qubibr0
```

### Test Storage Pool
```bash
# Check default storage pool:
sudo virsh pool-list --all
sudo virsh pool-info default
```

### Access Cockpit Web Interface
Open your web browser and navigate to:
```
https://YOUR_HOST_IP:9090
```

Log in with your system credentials to access the web management interface.

## 🎉 What You've Accomplished

Congratulations! You now have:
- ✅ A fully configured KVM host
- ✅ Libvirt virtualization services running
- ✅ Network bridge for VM connectivity
- ✅ Storage pool for VM disks
- ✅ Cockpit web interface for management
- ✅ Properly configured user environment

## 🔄 Next Steps

Now that you have a basic KVM host setup, you can:

1. **Create your first VM** - Use Cockpit or command line tools
2. **Explore advanced networking** - Try the [Basic Network Configuration](02-basic-network-configuration.md) tutorial
3. **Set up additional storage** - Follow the [Storage Pool Creation](03-storage-pool-creation.md) tutorial
4. **Learn troubleshooting** - Check our [How-To Guides](../how-to-guides/) for problem-solving

## 🆘 Troubleshooting

### Common Issues

**Problem**: "No package matching 'qemu-kvm' found"
**Solution**: Ensure EPEL repository is enabled and accessible

**Problem**: "Bridge creation failed"
**Solution**: Check that NetworkManager is running and your interface isn't already configured

**Problem**: "Permission denied accessing libvirt"
**Solution**: Ensure your user is in the libvirt group: `sudo usermod -a -G libvirt $USER`

### Getting Help

If you encounter issues:
1. Check the [troubleshooting guides](../how-to-guides/troubleshoot-networking.md)
2. Review the [reference documentation](../reference/) for configuration details
3. Open an issue on our [GitHub repository](https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues)

## 🔗 Related Documentation

- **Next Tutorial**: [Basic Network Configuration](02-basic-network-configuration.md)
- **Problem Solving**: [How-To Guides](../how-to-guides/)
- **Technical Details**: [Reference Documentation](../reference/)
- **Understanding Design**: [Explanations](../explanations/)

---

*This tutorial focused on the essential setup process. For more advanced configurations and specific problem-solving, explore our other documentation sections.*
