# How to Configure Custom Network Bridges

This guide shows you how to create custom network bridges for specific networking requirements beyond the default bridge configuration.

## 🎯 Goal

Configure custom network bridges for scenarios such as:
- Multiple isolated networks
- VLAN-tagged networks
- Dedicated management networks
- High-performance networking setups

## 📋 Prerequisites

- Completed basic KVM host setup
- Understanding of network bridge concepts
- Administrative access to the KVM host
- NetworkManager installed and running

## 🛠️ Solution

### Scenario 1: Create a Management Bridge

Create a dedicated bridge for management traffic:

```yaml
---
- name: Configure Management Bridge
  hosts: kvm-host
  become: true
  vars:
    management_bridge:
      name: "mgmt-br0"
      interface: "ens4"  # Dedicated management interface
      ip: "10.0.1.100"
      netmask: "255.255.255.0"
      gateway: "10.0.1.1"
      
  tasks:
    - name: Create management bridge connection
      community.general.nmcli:
        conn_name: "{{ management_bridge.name }}"
        type: bridge
        ip4: "{{ management_bridge.ip }}/24"
        gw4: "{{ management_bridge.gateway }}"
        state: present
        autoconnect: true

    - name: Add interface to management bridge
      community.general.nmcli:
        conn_name: "{{ management_bridge.name }}-slave"
        type: bridge-slave
        ifname: "{{ management_bridge.interface }}"
        master: "{{ management_bridge.name }}"
        state: present
        autoconnect: true

    - name: Activate management bridge
      community.general.nmcli:
        conn_name: "{{ management_bridge.name }}"
        state: up
```

### Scenario 2: VLAN-Tagged Bridge

Create a bridge with VLAN tagging:

```yaml
    vlan_bridge:
      name: "vlan100-br0"
      vlan_id: 100
      parent_interface: "ens3"
      ip: "192.168.100.1"
      netmask: "255.255.255.0"
      
  tasks:
    - name: Create VLAN interface
      community.general.nmcli:
        conn_name: "vlan{{ vlan_bridge.vlan_id }}"
        type: vlan
        vlanid: "{{ vlan_bridge.vlan_id }}"
        vlandev: "{{ vlan_bridge.parent_interface }}"
        state: present

    - name: Create VLAN bridge
      community.general.nmcli:
        conn_name: "{{ vlan_bridge.name }}"
        type: bridge
        ip4: "{{ vlan_bridge.ip }}/24"
        state: present
        autoconnect: true

    - name: Add VLAN to bridge
      community.general.nmcli:
        conn_name: "{{ vlan_bridge.name }}-slave"
        type: bridge-slave
        ifname: "vlan{{ vlan_bridge.vlan_id }}"
        master: "{{ vlan_bridge.name }}"
        state: present
```

### Scenario 3: High-Performance Bridge

Configure a bridge optimized for performance:

```yaml
    performance_bridge:
      name: "perf-br0"
      interface: "ens5"
      mtu: 9000  # Jumbo frames
      
  tasks:
    - name: Create high-performance bridge
      community.general.nmcli:
        conn_name: "{{ performance_bridge.name }}"
        type: bridge
        mtu: "{{ performance_bridge.mtu }}"
        state: present
        autoconnect: true

    - name: Configure bridge options for performance
      ansible.builtin.shell: |
        nmcli connection modify {{ performance_bridge.name }} \
          bridge.stp no \
          bridge.forward-delay 0 \
          bridge.hello-time 1 \
          bridge.max-age 6

    - name: Add interface with performance settings
      community.general.nmcli:
        conn_name: "{{ performance_bridge.name }}-slave"
        type: bridge-slave
        ifname: "{{ performance_bridge.interface }}"
        master: "{{ performance_bridge.name }}"
        mtu: "{{ performance_bridge.mtu }}"
        state: present
```

## 🔧 Implementation Steps

### Step 1: Plan Your Bridge Configuration

Determine your requirements:
- **Purpose**: Management, production, development, VLAN isolation
- **IP addressing**: Subnet and IP range
- **Performance**: MTU size, STP settings
- **Security**: Firewall rules, access controls

### Step 2: Identify Available Interfaces

Check available network interfaces:
```bash
# List all interfaces
ip link show

# Check interface status
nmcli device status

# Verify interface isn't in use
nmcli connection show
```

### Step 3: Create the Bridge Configuration

Choose the appropriate scenario from above and customize variables for your environment.

### Step 4: Execute the Configuration

```bash
ansible-playbook -i inventory.yml configure-custom-bridges.yml
```

### Step 5: Verify Bridge Creation

```bash
# Check bridge status
nmcli connection show
ip addr show

# Test bridge connectivity
ping -c 3 BRIDGE_IP
```

## ✅ Verification

### Bridge Validation Checklist

- [ ] Bridge interface is created and active
- [ ] IP address is assigned correctly
- [ ] Physical interface is enslaved to bridge
- [ ] Bridge is set to autoconnect
- [ ] Firewall rules allow necessary traffic
- [ ] MTU settings are correct (if customized)

### Testing Commands

```bash
# Verify bridge configuration
sudo nmcli connection show BRIDGE_NAME

# Check bridge details
sudo brctl show  # or ip link show type bridge

# Test network connectivity
ping -c 3 GATEWAY_IP
```

## 🔥 Firewall Configuration

Configure firewall rules for your custom bridges:

```bash
# Allow bridge traffic
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i BRIDGE_NAME -o BRIDGE_NAME -j ACCEPT

# Add bridge to trusted zone (if appropriate)
sudo firewall-cmd --permanent --zone=trusted --add-interface=BRIDGE_NAME

# Reload firewall
sudo firewall-cmd --reload
```

## 🚨 Common Issues and Solutions

### Issue: Bridge Creation Fails
**Symptoms**: nmcli command fails with "connection already exists"
**Solution**: 
```bash
# Remove existing connection
sudo nmcli connection delete CONNECTION_NAME
# Retry bridge creation
```

### Issue: No Network Connectivity
**Symptoms**: Bridge created but no network access
**Solution**:
```bash
# Check if interface is properly enslaved
nmcli device status
# Verify IP configuration
ip addr show BRIDGE_NAME
# Check routing
ip route show
```

### Issue: Performance Problems
**Symptoms**: Slow network performance
**Solution**:
```bash
# Disable STP if not needed
sudo nmcli connection modify BRIDGE_NAME bridge.stp no
# Increase MTU if supported
sudo nmcli connection modify BRIDGE_NAME mtu 9000
```

## 🔧 Advanced Configuration

### Multiple Bridge Setup

For complex environments with multiple bridges:

```yaml
multiple_bridges:
  - name: "dmz-br0"
    interface: "ens6"
    ip: "172.16.1.1"
    zone: "dmz"
  - name: "internal-br0"
    interface: "ens7"
    ip: "10.10.1.1"
    zone: "internal"
```

### Bridge Bonding

For redundancy, combine multiple interfaces:

```yaml
bonded_bridge:
  name: "bond-br0"
  bond_name: "bond0"
  interfaces: ["ens3", "ens4"]
  mode: "active-backup"
```

## 📊 Monitoring and Maintenance

### Monitor Bridge Status

```bash
# Check bridge statistics
cat /proc/net/dev | grep BRIDGE_NAME

# Monitor traffic
sudo iftop -i BRIDGE_NAME

# Check for errors
sudo ethtool -S BRIDGE_NAME
```

### Regular Maintenance

- Monitor interface statistics for errors
- Verify bridge connectivity regularly
- Update firewall rules as needed
- Document bridge purposes and configurations

## 🔗 Related Documentation

- **Tutorial**: [Basic Network Configuration](../tutorials/02-basic-network-configuration.md)
- **Reference**: [Network Variables](../reference/variables/role-variables.md#networking)
- **Explanation**: [Network Bridge Architecture](../explanations/network-bridge-architecture.md)
- **Troubleshooting**: [Troubleshoot Network Issues](troubleshoot-networking.md)

---

*This guide focused on custom bridge configuration. For basic networking setup, see the tutorials section. For network troubleshooting, check the troubleshooting guides.*
