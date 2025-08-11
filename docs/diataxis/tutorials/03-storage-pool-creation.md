# Storage Pool Creation

This tutorial teaches you how to create and manage storage pools for your virtual machines. Storage pools are essential for organizing and managing VM disk images efficiently.

## 🎯 What You'll Learn

In this tutorial, you will:
- Understand different storage pool types
- Create directory-based storage pools
- Set up LVM-based storage pools
- Configure storage pool permissions
- Create your first VM disk image
- Understand storage best practices

## 📋 Prerequisites

Before starting this tutorial:
- Complete [Your First KVM Host Setup](01-first-kvm-host-setup.md)
- Complete [Basic Network Configuration](02-basic-network-configuration.md)
- Have a working KVM host with libvirt configured
- Understand basic storage concepts (directories, LVM, disk space)

## 💾 Understanding Storage Pool Types

### Directory Pools
- Store VM disks as files in a directory
- Simple to set up and manage
- Good for: Development, small deployments
- Location: Usually `/var/lib/libvirt/images`

### LVM Pools
- Use LVM logical volumes for VM storage
- Better performance and management
- Good for: Production, large deployments
- Requires: LVM volume group

### Network Storage Pools
- Use network-attached storage (NFS, iSCSI)
- Shared storage across multiple hosts
- Good for: Clustered environments, migration

## 🚀 Step 1: Check Current Storage

First, let's examine your current storage configuration:

```bash
# List existing storage pools
sudo virsh pool-list --all

# Check default pool details
sudo virsh pool-info default
sudo virsh pool-dumpxml default

# Check available disk space
df -h /var/lib/libvirt/images
```

## 📝 Step 2: Create Additional Directory Pool

Let's create a dedicated storage pool for development VMs:

Create `configure-storage-pools.yml`:
```yaml
---
- name: Configure Storage Pools
  hosts: kvm-host
  become: true
  vars:
    storage_pools:
      - name: "development"
        type: "dir"
        path: "/var/lib/libvirt/images/development"
        owner: "root"
        group: "root"
        mode: "0755"
      - name: "production"
        type: "dir"
        path: "/var/lib/libvirt/images/production"
        owner: "root"
        group: "root"
        mode: "0755"
        
  tasks:
    - name: Create storage directories
      ansible.builtin.file:
        path: "{{ item.path }}"
        state: directory
        owner: "{{ item.owner }}"
        group: "{{ item.group }}"
        mode: "{{ item.mode }}"
      loop: "{{ storage_pools }}"
      when: item.type == "dir"

    - name: Create storage pool XML definitions
      ansible.builtin.template:
        src: dir-pool.xml.j2
        dest: "/tmp/{{ item.name }}-pool.xml"
      loop: "{{ storage_pools }}"
      when: item.type == "dir"

    - name: Define storage pools
      community.libvirt.virt_pool:
        command: define
        name: "{{ item.name }}"
        xml: "{{ lookup('file', '/tmp/' + item.name + '-pool.xml') }}"
      loop: "{{ storage_pools }}"
      when: item.type == "dir"

    - name: Start and autostart storage pools
      community.libvirt.virt_pool:
        name: "{{ item.name }}"
        state: active
        autostart: true
      loop: "{{ storage_pools }}"
```

Create the storage pool template `templates/dir-pool.xml.j2`:
```xml
<pool type="dir">
  <name>{{ pool_name }}</name>
  <target>
    <path>{{ pool_path }}</path>
    <permissions>
      <mode>{{ pool_mode }}</mode>
      <owner>{{ pool_owner }}</owner>
      <group>{{ pool_group }}</group>
    </permissions>
  </target>
</pool>
```

## ⚙️ Step 3: Set Up LVM Storage Pool (Optional)

If you want better performance and management, create an LVM-based pool:

First, check if you have available space for LVM:
```bash
# Check available disk space
sudo vgdisplay
sudo pvdisplay
sudo lsblk
```

If you have a spare disk or partition, add LVM configuration to your vars:
```yaml
    lvm_storage:
      - name: "vm-storage"
        vg_name: "vg_vms"
        device: "/dev/sdb"  # Replace with your available device
        size: "50G"
```

Add LVM tasks to your playbook:
```yaml
    - name: Create LVM volume group for VMs
      community.general.lvg:
        vg: "{{ item.vg_name }}"
        pvs: "{{ item.device }}"
      loop: "{{ lvm_storage | default([]) }}"
      when: lvm_storage is defined

    - name: Create LVM storage pool XML
      ansible.builtin.template:
        src: lvm-pool.xml.j2
        dest: "/tmp/{{ item.name }}-lvm-pool.xml"
      loop: "{{ lvm_storage | default([]) }}"
      when: lvm_storage is defined
```

## 🔧 Step 4: Run Storage Configuration

Execute your storage configuration:

```bash
ansible-playbook -i inventory.yml configure-storage-pools.yml
```

## ✅ Step 5: Verify Storage Pools

Check that your storage pools were created:

```bash
# List all storage pools
sudo virsh pool-list --all

# Check pool details
sudo virsh pool-info development
sudo virsh pool-info production

# Verify pool paths
ls -la /var/lib/libvirt/images/
```

## 💿 Step 6: Create Your First VM Disk

Now let's create a disk image in one of your new pools:

```bash
# Create a 20GB disk in the development pool
sudo virsh vol-create-as development test-vm-disk.qcow2 20G --format qcow2

# List volumes in the pool
sudo virsh vol-list development

# Check disk details
sudo virsh vol-info test-vm-disk.qcow2 development
```

## 🔒 Step 7: Set Up Storage Permissions

Ensure proper permissions for libvirt access:

```bash
# Set SELinux contexts (if SELinux is enabled)
sudo setsebool -P virt_use_nfs 1
sudo restorecon -R /var/lib/libvirt/images/

# Verify permissions
ls -laZ /var/lib/libvirt/images/
```

## 🧪 Step 8: Test Storage Performance

Basic performance test of your storage:

```bash
# Test write performance
sudo dd if=/dev/zero of=/var/lib/libvirt/images/development/test-file bs=1M count=1000 conv=fdatasync

# Test read performance
sudo dd if=/var/lib/libvirt/images/development/test-file of=/dev/null bs=1M

# Clean up test file
sudo rm /var/lib/libvirt/images/development/test-file
```

## 🎉 What You've Accomplished

Excellent! You now have:
- ✅ Multiple storage pools for different purposes
- ✅ Understanding of directory vs LVM storage
- ✅ Proper permissions and security contexts
- ✅ Your first VM disk image
- ✅ Knowledge of storage performance testing
- ✅ Organized storage structure for VMs

## 💡 Storage Best Practices

### Pool Organization
- **development**: For testing and development VMs
- **production**: For production workloads
- **templates**: For VM templates and base images
- **backups**: For VM backups and snapshots

### Naming Conventions
- Use descriptive pool names
- Include environment in disk names: `dev-webserver.qcow2`
- Use consistent file extensions: `.qcow2` for QEMU images

### Performance Tips
- Use LVM for better performance in production
- Consider SSD storage for database VMs
- Monitor disk space regularly
- Use thin provisioning when appropriate

## 🔄 Next Steps

With storage configured, you can:

1. **Create your first VM** - Use your new storage pools
2. **Explore advanced storage** - Check [How-To Guides](../how-to-guides/manage-storage-pools.md)
3. **Set up automated backups** - See [Configure Backup Automation](../how-to-guides/configure-backup-automation.md)
4. **Learn about VM templates** - Try [Deploy VMs from Templates](../how-to-guides/deploy-vm-templates.md)

## 🆘 Troubleshooting

### Common Issues

**Problem**: "Permission denied creating storage pool"
**Solution**: Check directory permissions and SELinux contexts

**Problem**: "LVM volume group not found"
**Solution**: Verify the device exists and isn't already in use: `sudo pvdisplay`

**Problem**: "Storage pool already exists"
**Solution**: Use `sudo virsh pool-undefine POOL_NAME` to remove existing pools

### Storage Monitoring

Monitor your storage usage:
```bash
# Check pool capacity
sudo virsh pool-info POOL_NAME

# Monitor disk usage
df -h /var/lib/libvirt/images/

# Check for thin provisioning
sudo qemu-img info /path/to/disk.qcow2
```

## 🔗 Related Documentation

- **Previous**: [Basic Network Configuration](02-basic-network-configuration.md)
- **Next**: [Multi-Host KVM Environment](04-multi-host-environment.md)
- **Advanced**: [Manage Storage Pools](../how-to-guides/manage-storage-pools.md)
- **Reference**: [Storage Variables](../reference/variables/role-variables.md#storage)

---

*This tutorial covered fundamental storage concepts. For production storage strategies and advanced configurations, explore our How-To Guides and Reference documentation.*
