# Qubinode KVM Host Setup Collection - User Installation Guide

**Version**: 1.0.0  
**Last Updated**: July 14, 2025  
**Compatibility**: RHEL 8/9, Rocky Linux 8/9, AlmaLinux 8/9  

## Overview

The Qubinode KVM Host Setup Collection is a comprehensive Ansible collection for automating the setup and configuration of KVM hosts on RHEL-based systems. This guide will walk you through the complete installation and configuration process.

### What This Collection Provides

- **Automated KVM Host Setup**: Complete virtualization environment configuration
- **Modular Role Architecture**: Six specialized roles for different aspects of setup
- **Multi-Platform Support**: RHEL 8/9, Rocky Linux, AlmaLinux compatibility
- **Enterprise-Ready**: Production-tested with comprehensive validation
- **Security Hardened**: Following security best practices and compliance standards

---

## Quick Start

For experienced users who want to get started immediately:

```bash
# Install the collection
ansible-galaxy collection install qubinode.kvmhost_setup_collection

# Run the complete setup
ansible-playbook -i localhost, qubinode.kvmhost_setup_collection.kvmhost_setup
```

For detailed setup instructions, continue reading.

---

## Prerequisites

### System Requirements

#### Hardware Requirements
- **CPU**: Intel VT-x or AMD-V capable processor
- **Memory**: Minimum 8GB RAM (16GB+ recommended for production)
- **Storage**: Minimum 100GB available disk space
- **Network**: Stable network connection for package downloads

#### Software Requirements
- **Operating System**: 
  - RHEL 8.4+ or RHEL 9.0+
  - Rocky Linux 8.4+ or 9.0+
  - AlmaLinux 8.4+ or 9.0+
- **Ansible**: Version 2.12+ (ansible-core)
- **Python**: Python 3.8+ 
- **Sudo Access**: Administrative privileges required

#### Network Requirements
- **Internet Access**: Required for package downloads and updates
- **DNS Resolution**: Proper DNS configuration
- **Repository Access**: Access to RHEL/Rocky/AlmaLinux repositories
- **EPEL Access**: Access to EPEL repository (will be configured automatically)

### Verification Script

Run this script to verify your system meets the requirements:

```bash
#!/bin/bash
# System Requirements Check

echo "=== Qubinode KVM Host Setup - System Requirements Check ==="
echo

# Check OS compatibility
echo "Checking Operating System..."
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    echo "OS: $PRETTY_NAME"
    case "$ID" in
        rhel|rocky|almalinux)
            echo "✅ OS Supported"
            ;;
        *)
            echo "❌ OS Not Supported - Use RHEL, Rocky, or AlmaLinux"
            exit 1
            ;;
    esac
else
    echo "❌ Cannot determine OS"
    exit 1
fi

# Check CPU virtualization
echo
echo "Checking CPU Virtualization..."
if grep -E "(vmx|svm)" /proc/cpuinfo > /dev/null; then
    echo "✅ Virtualization Support Detected"
else
    echo "❌ No virtualization support detected"
    echo "Enable VT-x/AMD-V in BIOS settings"
    exit 1
fi

# Check memory
echo
echo "Checking Memory..."
mem_gb=$(free -g | awk '/^Mem:/{print $2}')
if [[ $mem_gb -ge 8 ]]; then
    echo "✅ Memory: ${mem_gb}GB (meets minimum requirement)"
else
    echo "❌ Memory: ${mem_gb}GB (minimum 8GB required)"
    exit 1
fi

# Check storage
echo
echo "Checking Storage..."
storage_gb=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
if [[ $storage_gb -ge 100 ]]; then
    echo "✅ Available Storage: ${storage_gb}GB"
else
    echo "❌ Available Storage: ${storage_gb}GB (minimum 100GB required)"
    exit 1
fi

# Check Python
echo
echo "Checking Python..."
if python3 --version > /dev/null 2>&1; then
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo "✅ Python: $python_version"
else
    echo "❌ Python 3 not found"
    exit 1
fi

# Check Ansible
echo
echo "Checking Ansible..."
if ansible --version > /dev/null 2>&1; then
    ansible_version=$(ansible --version | head -1 | cut -d' ' -f2)
    echo "✅ Ansible: $ansible_version"
else
    echo "⚠️  Ansible not found - will be installed during setup"
fi

# Check sudo access
echo
echo "Checking Administrative Access..."
if sudo -n true > /dev/null 2>&1; then
    echo "✅ Sudo access confirmed"
else
    echo "❌ Sudo access required"
    exit 1
fi

echo
echo "🎉 System requirements check completed successfully!"
echo "You can proceed with the installation."
```

Save this as `check-requirements.sh` and run it:

```bash
chmod +x check-requirements.sh
./check-requirements.sh
```

---

## Installation Methods

### Method 1: Automated Installation (Recommended)

The easiest way to install and configure everything:

#### Step 1: Download Installation Script

```bash
# Download the automated installer
curl -sSL https://raw.githubusercontent.com/qubinode/kvmhost_setup_collection/main/scripts/install-qubinode.sh -o install-qubinode.sh
chmod +x install-qubinode.sh
```

#### Step 2: Run Installation

```bash
# Run with default settings
sudo ./install-qubinode.sh

# Or run with custom options
sudo ./install-qubinode.sh --ansible-version 2.17 --python-version 3.11
```

**Installation Options:**
- `--ansible-version X.Y`: Specify Ansible version (default: latest)
- `--python-version X.Y`: Specify Python version (default: system default)
- `--skip-validation`: Skip system requirements validation
- `--config-file PATH`: Use custom configuration file

### Method 2: Manual Installation

For users who prefer manual control over the installation process:

#### Step 1: Install Dependencies

```bash
# Update system
sudo dnf update -y

# Install Python and pip
sudo dnf install -y python3 python3-pip

# Install Ansible
pip3 install --user ansible-core

# Add pip binaries to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Step 2: Install Collection

```bash
# Install the collection
ansible-galaxy collection install qubinode.kvmhost_setup_collection

# Verify installation
ansible-galaxy collection list | grep qubinode
```

#### Step 3: Prepare Configuration

```bash
# Create working directory
mkdir -p ~/qubinode-setup
cd ~/qubinode-setup

# Generate default configuration
ansible-playbook qubinode.kvmhost_setup_collection.generate_config
```

### Method 3: Development Installation

For developers and advanced users:

#### Step 1: Clone Repository

```bash
# Clone the collection repository
git clone https://github.com/qubinode/kvmhost_setup_collection.git
cd kvmhost_setup_collection

# Install development dependencies
pip3 install -r requirements-dev.txt
```

#### Step 2: Install in Development Mode

```bash
# Install collection for development
ansible-galaxy collection install . --force

# Set up local testing environment
./scripts/setup-local-testing.sh
```

---

## Configuration

### Basic Configuration

#### Step 1: Generate Configuration Files

```bash
# Create configuration directory
mkdir -p ~/qubinode-config
cd ~/qubinode-config

# Generate default inventory
cat > inventory.yml << EOF
all:
  hosts:
    localhost:
      ansible_connection: local
      ansible_python_interpreter: /usr/bin/python3
  vars:
    # Basic KVM configuration
    kvmhost_enable_cockpit: true
    kvmhost_enable_ssl: true
    kvmhost_bridge_name: "br0"
    kvmhost_bridge_interface: "eth0"
    
    # Storage configuration
    kvmhost_storage_pools:
      - name: "default"
        type: "dir"
        path: "/var/lib/libvirt/images"
        
    # Network configuration
    kvmhost_networks:
      - name: "default"
        bridge: "br0"
        autostart: true
EOF
```

#### Step 2: Customize Configuration

Edit the `inventory.yml` file to match your environment:

```yaml
# Example customizations
all:
  vars:
    # Network Settings
    kvmhost_bridge_name: "br0"              # Bridge name
    kvmhost_bridge_interface: "enp1s0"      # Physical interface
    kvmhost_bridge_ip: "192.168.1.100"      # Bridge IP (optional)
    kvmhost_bridge_netmask: "255.255.255.0" # Bridge netmask
    
    # Storage Settings
    kvmhost_storage_pools:
      - name: "ssd_pool"
        type: "dir"
        path: "/srv/kvm/ssd"
      - name: "hdd_pool"
        type: "dir"
        path: "/srv/kvm/hdd"
        
    # User Configuration
    kvmhost_users:
      - username: "kvmadmin"
        groups: ["libvirt", "wheel"]
        shell: "/bin/bash"
        
    # Cockpit Configuration
    kvmhost_cockpit_port: 9090
    kvmhost_cockpit_ssl: true
    kvmhost_cockpit_cert_path: "/etc/cockpit/ws-certs.d"
    
    # Security Settings
    kvmhost_firewall_enabled: true
    kvmhost_selinux_mode: "enforcing"
```

### Advanced Configuration

#### Environment-Specific Settings

Create different configuration files for different environments:

```bash
# Production environment
cat > production.yml << EOF
kvmhost_environment: production
kvmhost_selinux_mode: enforcing
kvmhost_firewall_enabled: true
kvmhost_enable_monitoring: true
kvmhost_backup_enabled: true
EOF

# Development environment
cat > development.yml << EOF
kvmhost_environment: development
kvmhost_selinux_mode: permissive
kvmhost_firewall_enabled: false
kvmhost_enable_monitoring: false
kvmhost_backup_enabled: false
EOF
```

#### Role-Specific Configuration

Configure individual roles:

```yaml
# Base system configuration
kvmhost_base_packages:
  - vim
  - htop
  - tmux
  - git

# Networking configuration
kvmhost_networking_vlans:
  - id: 100
    name: "vlan100"
    bridge: "br0"
    
# Storage configuration
kvmhost_storage_lvm:
  volume_groups:
    - name: "vg_kvm"
      devices: ["/dev/sdb"]
      logical_volumes:
        - name: "lv_images"
          size: "500G"
          mount: "/var/lib/libvirt/images"
```

---

## Running the Setup

### Complete Setup (All Roles)

Run the complete KVM host setup:

```bash
# Run complete setup with default configuration
ansible-playbook -i inventory.yml qubinode.kvmhost_setup_collection.kvmhost_setup

# Run with custom variables file
ansible-playbook -i inventory.yml -e @production.yml qubinode.kvmhost_setup_collection.kvmhost_setup

# Run with verbose output
ansible-playbook -i inventory.yml -v qubinode.kvmhost_setup_collection.kvmhost_setup
```

### Individual Roles

Run individual roles for specific configurations:

```bash
# Base system setup only
ansible-playbook -i inventory.yml qubinode.kvmhost_setup_collection.kvmhost_base

# Networking setup only
ansible-playbook -i inventory.yml qubinode.kvmhost_setup_collection.kvmhost_networking

# Storage setup only
ansible-playbook -i inventory.yml qubinode.kvmhost_setup_collection.kvmhost_storage

# Libvirt setup only
ansible-playbook -i inventory.yml qubinode.kvmhost_setup_collection.kvmhost_libvirt

# Cockpit setup only
ansible-playbook -i inventory.yml qubinode.kvmhost_setup_collection.kvmhost_cockpit

# User configuration only
ansible-playbook -i inventory.yml qubinode.kvmhost_setup_collection.kvmhost_user_config
```

### Role Dependencies

The roles have dependencies. If you run individual roles, ensure dependencies are met:

```
kvmhost_base (no dependencies)
├── kvmhost_networking (requires: kvmhost_base)
├── kvmhost_user_config (requires: kvmhost_base)
└── kvmhost_libvirt (requires: kvmhost_base, kvmhost_networking)
    ├── kvmhost_storage (requires: kvmhost_base, kvmhost_libvirt)
    └── kvmhost_cockpit (requires: kvmhost_base, kvmhost_libvirt)
```

---

## Validation and Testing

### Automated Validation

Run the built-in validation playbook:

```bash
# Run validation tests
ansible-playbook -i inventory.yml qubinode.kvmhost_setup_collection.validate

# Run specific validation categories
ansible-playbook -i inventory.yml qubinode.kvmhost_setup_collection.validate \
  -e validation_categories="network,storage,libvirt"
```

### Manual Validation

#### System Status Check

```bash
# Check KVM support
kvm-ok

# Check libvirt status
sudo systemctl status libvirtd

# List virtual networks
sudo virsh net-list --all

# List storage pools
sudo virsh pool-list --all

# Check bridge configuration
ip link show type bridge
```

#### Cockpit Web Interface

1. Open browser to `https://your-server:9090`
2. Login with your user credentials
3. Navigate to Virtual Machines section
4. Verify all components are working

#### Create Test VM

```bash
# Download a test image
curl -o /tmp/cirros.qcow2 \
  https://download.cirros-cloud.net/0.5.2/cirros-0.5.2-x86_64-disk.img

# Create a test VM
sudo virt-install \
  --name test-vm \
  --memory 512 \
  --vcpus 1 \
  --disk /tmp/cirros.qcow2 \
  --import \
  --network bridge=br0 \
  --graphics none \
  --serial pty \
  --console pty

# Verify VM is running
sudo virsh list --all
```

---

## Troubleshooting

### Common Issues

#### Issue: Virtualization Not Enabled

**Symptoms**: 
- `kvm-ok` reports virtualization not available
- VMs fail to start with hardware acceleration errors

**Solution**:
1. Reboot system and enter BIOS/UEFI
2. Enable VT-x (Intel) or AMD-V (AMD) 
3. Enable VT-d/IOMMU if available
4. Save and reboot
5. Verify with `lscpu | grep Virtualization`

#### Issue: Bridge Interface Not Created

**Symptoms**:
- Network configuration fails
- `ip link show` doesn't show bridge interface
- VMs have no network connectivity

**Solution**:
```bash
# Check if NetworkManager is interfering
sudo systemctl status NetworkManager

# Manually create bridge (temporary)
sudo ip link add name br0 type bridge
sudo ip link set br0 up
sudo ip link set eth0 master br0

# Check configuration
cat /etc/sysconfig/network-scripts/ifcfg-br0
```

#### Issue: Storage Pool Creation Fails

**Symptoms**:
- Storage pool creation errors
- Permission denied errors on storage paths
- SELinux context errors

**Solution**:
```bash
# Check SELinux contexts
ls -lZ /var/lib/libvirt/images/

# Fix SELinux contexts
sudo restorecon -Rv /var/lib/libvirt/images/

# Check permissions
sudo chown -R qemu:qemu /var/lib/libvirt/images/
sudo chmod 755 /var/lib/libvirt/images/
```

#### Issue: Ansible Collection Not Found

**Symptoms**:
- "Collection not found" errors
- Playbook fails to run

**Solution**:
```bash
# Verify collection installation
ansible-galaxy collection list | grep qubinode

# Reinstall collection
ansible-galaxy collection install qubinode.kvmhost_setup_collection --force

# Check Ansible configuration
ansible-config dump | grep COLLECTIONS_PATHS
```

### Diagnostic Commands

```bash
# System information
hostnamectl
uname -a
lscpu | grep Virtualization

# Ansible information
ansible --version
ansible-config dump | grep COLLECTIONS_PATHS
ansible-galaxy collection list

# KVM/Libvirt status
sudo systemctl status libvirtd
sudo virsh version
sudo virsh nodeinfo

# Network configuration
ip addr show
ip route show
bridge link show

# Storage information
df -h
lsblk
sudo vgs
sudo lvs
```

### Log Files

Important log files for troubleshooting:

```bash
# System logs
sudo journalctl -u libvirtd
sudo journalctl -u NetworkManager

# Ansible logs (if using verbose mode)
# Check Ansible output for specific error messages

# Libvirt logs
sudo tail -f /var/log/libvirt/libvirtd.log

# Cockpit logs
sudo journalctl -u cockpit
```

---

## Configuration Examples

### Single-Host Setup

Basic single-host setup for development or testing:

```yaml
all:
  hosts:
    localhost:
      ansible_connection: local
  vars:
    kvmhost_bridge_name: "br0"
    kvmhost_bridge_interface: "eth0"
    kvmhost_enable_cockpit: true
    kvmhost_cockpit_ssl: false  # Disable SSL for development
    kvmhost_selinux_mode: "permissive"
    kvmhost_firewall_enabled: false
```

### Production Setup

Enterprise production setup with security hardening:

```yaml
all:
  hosts:
    kvm-host-01:
      ansible_host: 192.168.1.100
    kvm-host-02:
      ansible_host: 192.168.1.101
  vars:
    kvmhost_environment: "production"
    kvmhost_bridge_name: "br0"
    kvmhost_bridge_interface: "enp1s0"
    kvmhost_enable_cockpit: true
    kvmhost_cockpit_ssl: true
    kvmhost_cockpit_port: 9090
    kvmhost_selinux_mode: "enforcing"
    kvmhost_firewall_enabled: true
    kvmhost_enable_monitoring: true
    kvmhost_backup_enabled: true
    
    # Storage configuration
    kvmhost_storage_pools:
      - name: "production_pool"
        type: "dir"
        path: "/srv/kvm/production"
      - name: "backup_pool"
        type: "dir"
        path: "/srv/kvm/backup"
        
    # User management
    kvmhost_users:
      - username: "kvmadmin"
        groups: ["libvirt", "wheel"]
        shell: "/bin/bash"
      - username: "vmoperator"
        groups: ["libvirt"]
        shell: "/bin/bash"
```

### Multi-Network Setup

Setup with multiple networks and VLANs:

```yaml
all:
  vars:
    kvmhost_networking_bridges:
      - name: "br0"
        interface: "enp1s0"
        ip: "192.168.1.100"
        netmask: "255.255.255.0"
      - name: "br100"
        interface: "enp1s0.100"
        ip: "10.0.100.1"
        netmask: "255.255.255.0"
        
    kvmhost_networks:
      - name: "default"
        bridge: "br0"
        autostart: true
      - name: "isolated"
        bridge: "br100"
        autostart: true
        isolated: true
```

---

## Next Steps

After successful installation:

1. **Create Your First VM**: Use Cockpit web interface or `virt-install`
2. **Set Up Monitoring**: Configure system monitoring and alerting
3. **Backup Strategy**: Implement VM and configuration backup procedures
4. **Security Hardening**: Review and implement additional security measures
5. **Automation**: Create playbooks for VM provisioning and management

### Recommended Reading

- [RHEL Virtualization Deployment and Administration Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/configuring_and_managing_virtualization/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [KVM Virtualization Documentation](https://www.linux-kvm.org/page/Documents)

### Support and Community

- **Documentation**: [Qubinode KVM Collection Docs](https://github.com/qubinode/kvmhost_setup_collection/docs)
- **Issues**: [GitHub Issues](https://github.com/qubinode/kvmhost_setup_collection/issues)
- **Discussions**: [GitHub Discussions](https://github.com/qubinode/kvmhost_setup_collection/discussions)
- **Contributing**: [Contributing Guide](https://github.com/qubinode/kvmhost_setup_collection/CONTRIBUTING.md)

---

**Version**: 1.0.0  
**Last Updated**: July 14, 2025  
**Maintainers**: Qubinode Community  
**License**: Apache 2.0
