# Basic Network Configuration

This tutorial builds on your first KVM host setup and teaches you how to configure networking for different virtual machine scenarios. You'll learn to create custom network configurations that suit various use cases.

## 🎯 What You'll Learn

In this tutorial, you will:
- Understand different network modes (NAT, Bridge, Isolated)
- Create custom virtual networks
- Configure network bridges for different scenarios
- Test network connectivity between VMs
- Set up firewall rules for VM networks

## 📋 Prerequisites

Before starting this tutorial:
- Complete [Your First KVM Host Setup](01-first-kvm-host-setup.md)
- Have a working KVM host with basic configuration
- Understand basic networking concepts (IP addresses, subnets, gateways)

## 🌐 Understanding Network Modes

### Bridge Mode (Default)
- VMs get IP addresses from your physical network
- VMs appear as separate devices on your network
- Best for: Production environments, external access needed

### NAT Mode
- VMs share the host's IP address
- VMs can access external networks but aren't directly accessible
- Best for: Development, testing, security isolation

### Isolated Mode
- VMs can only communicate with each other
- No external network access
- Best for: Secure testing, isolated environments

## 🚀 Step 1: Examine Current Network Setup

First, let's see what networks were created during your initial setup:

```bash
# Check existing networks
sudo virsh net-list --all

# View the default bridge network
sudo virsh net-dumpxml qubinet
```

You should see the `qubinet` network that was created during your initial setup.

## 📝 Step 2: Create a Custom NAT Network

Let's create a NAT network for development VMs:

Create `configure-nat-network.yml`:
```yaml
---
- name: Configure NAT Network
  hosts: kvm-host
  become: true
  vars:
    # Custom NAT network configuration
    custom_networks:
      - name: "dev-nat"
        mode: "nat"
        bridge: "virbr1"
        ip_address: "192.168.100.1"
        netmask: "255.255.255.0"
        dhcp_start: "192.168.100.10"
        dhcp_end: "192.168.100.100"
        
  tasks:
    - name: Create NAT network XML
      ansible.builtin.template:
        src: nat-network.xml.j2
        dest: /tmp/dev-nat.xml
      vars:
        network_name: "{{ item.name }}"
        bridge_name: "{{ item.bridge }}"
        ip_addr: "{{ item.ip_address }}"
        netmask: "{{ item.netmask }}"
        dhcp_start: "{{ item.dhcp_start }}"
        dhcp_end: "{{ item.dhcp_end }}"
      loop: "{{ custom_networks }}"
      when: item.mode == "nat"

    - name: Define the network
      community.libvirt.virt_net:
        command: define
        name: "{{ item.name }}"
        xml: "{{ lookup('file', '/tmp/' + item.name + '.xml') }}"
      loop: "{{ custom_networks }}"
      when: item.mode == "nat"

    - name: Start and autostart the network
      community.libvirt.virt_net:
        name: "{{ item.name }}"
        state: active
        autostart: true
      loop: "{{ custom_networks }}"
      when: item.mode == "nat"
```

Create the network template `templates/nat-network.xml.j2`:
```xml
<network>
  <name>{{ network_name }}</name>
  <bridge name="{{ bridge_name }}" stp="on" delay="0"/>
  <forward mode="nat"/>
  <ip address="{{ ip_addr }}" netmask="{{ netmask }}">
    <dhcp>
      <range start="{{ dhcp_start }}" end="{{ dhcp_end }}"/>
    </dhcp>
  </ip>
</network>
```

## ⚙️ Step 3: Create an Isolated Network

Now let's create an isolated network for secure testing:

Add to your `configure-nat-network.yml` vars section:
```yaml
    custom_networks:
      - name: "dev-nat"
        mode: "nat"
        bridge: "virbr1"
        ip_address: "192.168.100.1"
        netmask: "255.255.255.0"
        dhcp_start: "192.168.100.10"
        dhcp_end: "192.168.100.100"
      - name: "secure-isolated"
        mode: "isolated"
        bridge: "virbr2"
        ip_address: "10.0.0.1"
        netmask: "255.255.255.0"
        dhcp_start: "10.0.0.10"
        dhcp_end: "10.0.0.100"
```

Create the isolated network template `templates/isolated-network.xml.j2`:
```xml
<network>
  <name>{{ network_name }}</name>
  <bridge name="{{ bridge_name }}" stp="on" delay="0"/>
  <ip address="{{ ip_addr }}" netmask="{{ netmask }}">
    <dhcp>
      <range start="{{ dhcp_start }}" end="{{ dhcp_end }}"/>
    </dhcp>
  </ip>
</network>
```

Update your playbook to handle isolated networks:
```yaml
    - name: Create isolated network XML
      ansible.builtin.template:
        src: isolated-network.xml.j2
        dest: /tmp/{{ item.name }}.xml
      loop: "{{ custom_networks }}"
      when: item.mode == "isolated"
```

## 🔧 Step 4: Run the Network Configuration

Execute your network configuration playbook:

```bash
ansible-playbook -i inventory.yml configure-nat-network.yml
```

## ✅ Step 5: Verify Network Configuration

Check that your networks were created successfully:

```bash
# List all networks
sudo virsh net-list --all

# Check network details
sudo virsh net-dumpxml dev-nat
sudo virsh net-dumpxml secure-isolated

# Verify bridge interfaces
ip addr show | grep virbr
```

You should see:
- `qubinet` (your original bridge network)
- `dev-nat` (your new NAT network)
- `secure-isolated` (your isolated network)

## 🔥 Step 6: Configure Firewall Rules

Set up firewall rules to allow VM traffic:

```bash
# Allow libvirt traffic
sudo firewall-cmd --permanent --add-service=libvirt
sudo firewall-cmd --permanent --add-service=libvirt-tls

# Allow bridge traffic
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i qubibr0 -o qubibr0 -j ACCEPT
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i virbr1 -o virbr1 -j ACCEPT

# Reload firewall
sudo firewall-cmd --reload
```

## 🧪 Step 7: Test Your Network Setup

Create a simple test to verify networking:

```bash
# Check network connectivity
sudo virsh net-info qubinet
sudo virsh net-info dev-nat
sudo virsh net-info secure-isolated

# Verify DHCP ranges
sudo virsh net-dhcp-leases qubinet
sudo virsh net-dhcp-leases dev-nat
```

## 🎉 What You've Accomplished

Great work! You now have:
- ✅ Multiple network configurations for different use cases
- ✅ A bridge network for production-like VMs
- ✅ A NAT network for development and testing
- ✅ An isolated network for secure testing
- ✅ Proper firewall configuration
- ✅ Understanding of different network modes

## 🔄 Next Steps

With your networking configured, you can:

1. **Create storage pools** - Follow [Storage Pool Creation](03-storage-pool-creation.md)
2. **Deploy your first VM** - Use any of your configured networks
3. **Explore advanced networking** - Check our [How-To Guides](../how-to-guides/) for complex scenarios

## 💡 Understanding Your Networks

### When to Use Each Network

- **qubinet (Bridge)**: Use for VMs that need to be accessible from your physical network
- **dev-nat (NAT)**: Use for development VMs that need internet access but don't need to be accessible externally
- **secure-isolated (Isolated)**: Use for testing scenarios where you need complete network isolation

### Network Selection in VM Creation

When creating VMs, you can specify which network to use:
```bash
# Using bridge network (default)
virt-install --network network=qubinet ...

# Using NAT network
virt-install --network network=dev-nat ...

# Using isolated network
virt-install --network network=secure-isolated ...
```

## 🆘 Troubleshooting

### Common Issues

**Problem**: "Network already exists"
**Solution**: Use `sudo virsh net-undefine NETWORK_NAME` to remove existing networks first

**Problem**: "Bridge interface not found"
**Solution**: Verify NetworkManager is running: `sudo systemctl status NetworkManager`

**Problem**: "Permission denied"
**Solution**: Ensure you're running with sudo/become privileges

### Getting Help

- [Network Troubleshooting Guide](../how-to-guides/troubleshoot-networking.md)
- [Reference: Network Variables](../reference/variables/role-variables.md#networking)
- [GitHub Issues](https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues)

## 🔗 Related Documentation

- **Previous**: [Your First KVM Host Setup](01-first-kvm-host-setup.md)
- **Next**: [Storage Pool Creation](03-storage-pool-creation.md)
- **Advanced**: [Configure Custom Network Bridges](../how-to-guides/configure-custom-bridges.md)

---

*This tutorial covered basic network configuration concepts. For production deployments and advanced scenarios, consult our How-To Guides and Reference documentation.*
