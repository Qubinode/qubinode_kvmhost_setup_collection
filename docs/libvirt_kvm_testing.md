# Libvirt/KVM Molecule Testing Guide

## Requirements
- Host OS: RHEL 9.5/CentOS Stream 9
- User: lab-user (member of libvirt & kvm groups)
- Packages: libvirt-devel, libvirt-client, qemu-kvm, libvirt-daemon

## Pre-Installation Steps
```bash
./scripts/setup_dev_env.sh
scripts/libvirt_testenv.sh
```

## Configuration Steps

### 1. Session Mode Permissions
```bash
sudo usermod -aG libvirt,qemu,kvm,libvirt-qemu $(whoami)
newgrp libvirt
virsh -c qemu:///session list
```

### 2. Molecule Configuration
```yaml
# molecule/default/molecule.yml
driver:
  name: libvirt
  connection_uri: qemu:///session
  socket: /run/user/1000/libvirt/libvirt-sock

platforms:
  - name: kvm-testnode
    memory: 2048
    vcpus: 2
    disks:
      - name: vda
        size: 20G
    networks:
      - network: default
    os:
      variant: centos-stream9
```

### 3. Network Setup
```bash
virsh -c qemu:///session net-define <<EOF
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF

virsh -c qemu:///session net-start default
```

### 4. Storage Pool Configuration
```bash
mkdir -p $HOME/.local/libvirt/images
virsh -c qemu:///session pool-define-as --name default --type dir --target $HOME/.local/libvirt/images
virsh -c qemu:///session pool-start default
```

## Running Tests
```bash
MOLECULE_DEBUG=True molecule test --scenario-name default
```

## Troubleshooting

### Common Issues
1. **Permission Errors**:
   - Verify group membership: `groups | grep libvirt`
   - Check socket permissions: `ls -l /run/user/1000/libvirt/libvirt-sock`

2. **Network Failures**:
   - Confirm network status: `virsh -c qemu:///session net-list --all`
   - Check firewall rules: `sudo iptables -L -n -v`

3. **Storage Issues**:
   - Verify storage pool: `virsh -c qemu:///session pool-list`
   - Check directory permissions: `ls -ld $HOME/.local/libvirt/images`

4. **SELinux Contexts**:
   ```bash
   sudo ausearch -m avc -ts recent
   sudo setsebool -P virt_use_nfs 1
