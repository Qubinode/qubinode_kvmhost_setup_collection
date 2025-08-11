# How to Troubleshoot Network Issues

This guide helps you diagnose and resolve common networking problems in your KVM environment.

## 🎯 Goal

Quickly identify and resolve networking issues including:
- Bridge connectivity problems
- VM network access issues
- DNS resolution failures
- Performance problems
- Firewall blocking issues

## 📋 Prerequisites

- Basic KVM host setup completed
- Understanding of network concepts
- Administrative access to the KVM host
- Basic familiarity with network troubleshooting tools

## 🔍 Diagnostic Process

### Step 1: Identify the Problem Scope

Determine what's affected:
```bash
# Check overall network status
sudo systemctl status NetworkManager
sudo systemctl status libvirtd

# List all network interfaces
ip addr show

# Check bridge status
sudo nmcli connection show
sudo brctl show  # or ip link show type bridge
```

### Step 2: Check Network Connectivity Layers

#### Layer 1: Physical Interface
```bash
# Check interface status
sudo nmcli device status

# Check for interface errors
sudo ethtool -S INTERFACE_NAME | grep -i error

# Verify cable/link status
sudo ethtool INTERFACE_NAME | grep "Link detected"
```

#### Layer 2: Bridge Configuration
```bash
# Verify bridge exists and is active
sudo nmcli connection show | grep bridge

# Check bridge details
sudo ip addr show BRIDGE_NAME

# Verify interface is enslaved to bridge
sudo nmcli device show INTERFACE_NAME
```

#### Layer 3: IP Configuration
```bash
# Check IP assignment
ip addr show BRIDGE_NAME

# Verify routing
ip route show

# Test gateway connectivity
ping -c 3 GATEWAY_IP
```

## 🚨 Common Issues and Solutions

### Issue 1: Bridge Not Created

**Symptoms**: 
- `nmcli connection show` doesn't show bridge
- VMs can't get network access

**Diagnosis**:
```bash
# Check if NetworkManager is running
sudo systemctl status NetworkManager

# Check for conflicting connections
sudo nmcli connection show

# Check interface availability
sudo nmcli device status
```

**Solution**:
```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Remove conflicting connections
sudo nmcli connection delete CONNECTION_NAME

# Recreate bridge using the collection
ansible-playbook -i inventory.yml setup-kvm-host.yml --tags networking
```

### Issue 2: VMs Can't Access Network

**Symptoms**:
- VMs start but have no network connectivity
- VMs get IP addresses but can't reach gateway

**Diagnosis**:
```bash
# Check VM network configuration
sudo virsh domiflist VM_NAME

# Verify bridge has IP
ip addr show BRIDGE_NAME

# Check if bridge is forwarding
cat /proc/sys/net/ipv4/ip_forward

# Check iptables rules
sudo iptables -L -n | grep -i forward
```

**Solution**:
```bash
# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Check firewall rules
sudo firewall-cmd --list-all

# Allow bridge traffic
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i BRIDGE_NAME -o BRIDGE_NAME -j ACCEPT
sudo firewall-cmd --reload
```

### Issue 3: DNS Resolution Problems

**Symptoms**:
- VMs can ping IP addresses but not domain names
- Slow network performance

**Diagnosis**:
```bash
# Check DNS configuration on host
cat /etc/resolv.conf

# Test DNS from host
nslookup google.com

# Check libvirt network DNS
sudo virsh net-dumpxml NETWORK_NAME | grep -A 5 dns
```

**Solution**:
```bash
# Update network DNS configuration
sudo virsh net-edit NETWORK_NAME
# Add or modify DNS settings:
# <dns>
#   <forwarder addr="8.8.8.8"/>
#   <forwarder addr="1.1.1.1"/>
# </dns>

# Restart network
sudo virsh net-destroy NETWORK_NAME
sudo virsh net-start NETWORK_NAME
```

### Issue 4: Poor Network Performance

**Symptoms**:
- Slow VM network performance
- High latency between VMs

**Diagnosis**:
```bash
# Check bridge settings
sudo nmcli connection show BRIDGE_NAME | grep bridge

# Check MTU settings
ip link show BRIDGE_NAME | grep mtu

# Test network performance
iperf3 -s  # On one VM
iperf3 -c VM_IP  # On another VM
```

**Solution**:
```bash
# Disable STP if not needed
sudo nmcli connection modify BRIDGE_NAME bridge.stp no

# Optimize bridge settings
sudo nmcli connection modify BRIDGE_NAME bridge.forward-delay 0
sudo nmcli connection modify BRIDGE_NAME bridge.hello-time 1

# Increase MTU if supported
sudo nmcli connection modify BRIDGE_NAME mtu 9000

# Restart connection
sudo nmcli connection down BRIDGE_NAME
sudo nmcli connection up BRIDGE_NAME
```

## 🔧 Advanced Troubleshooting

### Network Packet Analysis

#### Capture Traffic on Bridge
```bash
# Capture packets on bridge
sudo tcpdump -i BRIDGE_NAME -n

# Capture specific traffic
sudo tcpdump -i BRIDGE_NAME host VM_IP

# Save capture for analysis
sudo tcpdump -i BRIDGE_NAME -w /tmp/bridge-capture.pcap
```

#### Analyze VM Network Traffic
```bash
# Check VM interface statistics
sudo virsh domifstat VM_NAME INTERFACE_NAME

# Monitor real-time traffic
sudo iftop -i BRIDGE_NAME

# Check for packet drops
sudo netstat -i | grep BRIDGE_NAME
```

### Libvirt Network Debugging

#### Enable Libvirt Logging
```bash
# Edit libvirt configuration
sudo vim /etc/libvirt/libvirtd.conf

# Add logging configuration:
# log_level = 1
# log_filters="1:qemu 1:libvirt 4:object 4:json 4:event 1:util"
# log_outputs="1:file:/var/log/libvirt/libvirtd.log"

# Restart libvirtd
sudo systemctl restart libvirtd
```

#### Check Libvirt Logs
```bash
# View libvirt logs
sudo journalctl -u libvirtd -f

# Check specific network logs
sudo grep -i network /var/log/libvirt/libvirtd.log

# Check for errors
sudo grep -i error /var/log/libvirt/libvirtd.log
```

## 🛠️ Automated Diagnostics

### Create Network Health Check Script

```bash
cat > /usr/local/bin/network-health-check.sh << 'EOF'
#!/bin/bash

echo "=== Network Health Check ==="
echo "Date: $(date)"
echo

echo "1. NetworkManager Status:"
systemctl is-active NetworkManager
echo

echo "2. Libvirt Status:"
systemctl is-active libvirtd
echo

echo "3. Bridge Interfaces:"
ip link show type bridge
echo

echo "4. Network Connections:"
nmcli connection show --active
echo

echo "5. Libvirt Networks:"
virsh net-list --all
echo

echo "6. IP Forwarding:"
cat /proc/sys/net/ipv4/ip_forward
echo

echo "7. Firewall Status:"
firewall-cmd --state
echo

echo "=== End Health Check ==="
EOF

sudo chmod +x /usr/local/bin/network-health-check.sh
```

### Run Automated Diagnostics

```bash
# Run health check
sudo /usr/local/bin/network-health-check.sh

# Save results for analysis
sudo /usr/local/bin/network-health-check.sh > /tmp/network-health-$(date +%Y%m%d-%H%M%S).log
```

## 📊 Performance Analysis

### Network Bandwidth Testing

```bash
# Install iperf3 on host and VMs
sudo dnf install -y iperf3

# Test bandwidth between host and VM
# On VM: iperf3 -s
# On host: iperf3 -c VM_IP

# Test bandwidth between VMs
# On VM1: iperf3 -s
# On VM2: iperf3 -c VM1_IP
```

### Latency Testing

```bash
# Test latency to VMs
ping -c 10 VM_IP

# Test latency between VMs
# From VM1: ping -c 10 VM2_IP

# Advanced latency testing
hping3 -c 10 -S -p 80 VM_IP
```

## 🔄 Recovery Procedures

### Reset Network Configuration

If networking is completely broken:

```bash
# Stop all VMs
sudo virsh list --name | xargs -I {} virsh shutdown {}

# Stop libvirt networks
sudo virsh net-list --name | xargs -I {} virsh net-destroy {}

# Reset NetworkManager
sudo systemctl stop NetworkManager
sudo rm -f /etc/NetworkManager/system-connections/*
sudo systemctl start NetworkManager

# Reconfigure using Ansible
ansible-playbook -i inventory.yml setup-kvm-host.yml --tags networking
```

### Emergency Network Access

If you lose SSH access due to network changes:

1. **Console Access**: Use physical console or IPMI/iDRAC
2. **Reset Network**: 
   ```bash
   # From console
   sudo nmcli connection up "System eth0"  # or your original connection
   ```
3. **Restore Configuration**: Re-run Ansible playbook

## 📚 Prevention Strategies

### Configuration Backup

```bash
# Backup network configurations
sudo cp -r /etc/NetworkManager/system-connections/ /root/network-backup-$(date +%Y%m%d)/

# Backup libvirt networks
mkdir -p /root/libvirt-backup-$(date +%Y%m%d)
for net in $(sudo virsh net-list --name); do
    sudo virsh net-dumpxml $net > /root/libvirt-backup-$(date +%Y%m%d)/$net.xml
done
```

### Monitoring Setup

```bash
# Add to crontab for regular monitoring
echo "*/5 * * * * /usr/local/bin/network-health-check.sh >> /var/log/network-health.log" | sudo crontab -
```

## 🔗 Related Documentation

- **Tutorial**: [Basic Network Configuration](../tutorials/02-basic-network-configuration.md)
- **How-To**: [Configure Custom Network Bridges](configure-custom-bridges.md)
- **Reference**: [Network Variables](../reference/variables/role-variables.md#networking)
- **Explanation**: [Network Bridge Architecture](../explanations/network-bridge-architecture.md)

---

*This guide provided comprehensive network troubleshooting techniques. For preventive configuration and advanced setups, see our other how-to guides and reference documentation.*
