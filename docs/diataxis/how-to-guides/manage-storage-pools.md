# How to Manage Storage Pools

This guide shows you how to effectively manage storage pools throughout their lifecycle - from creation to maintenance to cleanup.

## 🎯 Goal

Learn to manage storage pools for:
- Creating and deleting storage pools
- Resizing and expanding pools
- Moving storage between pools
- Monitoring storage usage and performance
- Implementing storage policies

## 📋 Prerequisites

- Completed [Storage Pool Creation](../tutorials/03-storage-pool-creation.md) tutorial
- Basic understanding of storage concepts
- Administrative access to KVM host
- Existing storage pools to manage

## 🛠️ Managing Pool Lifecycle

### Create New Storage Pools

#### Directory Pool Creation
```bash
# Create directory
sudo mkdir -p /var/lib/libvirt/images/new-pool
sudo chown root:root /var/lib/libvirt/images/new-pool
sudo chmod 755 /var/lib/libvirt/images/new-pool

# Define pool
sudo virsh pool-define-as new-pool dir - - - - /var/lib/libvirt/images/new-pool

# Start and autostart
sudo virsh pool-start new-pool
sudo virsh pool-autostart new-pool
```

#### LVM Pool Creation
```bash
# Create logical volume
sudo lvcreate -L 100G -n lv_new_pool vg_storage

# Define LVM pool
sudo virsh pool-define-as new-lvm-pool logical - - vg_storage /dev/vg_storage

# Start pool
sudo virsh pool-start new-lvm-pool
sudo virsh pool-autostart new-lvm-pool
```

### Delete Storage Pools

**⚠️ Warning**: This will destroy all data in the pool!

```bash
# Stop the pool
sudo virsh pool-destroy pool-name

# Undefine the pool
sudo virsh pool-undefine pool-name

# Remove directory (for directory pools)
sudo rm -rf /var/lib/libvirt/images/pool-name

# Remove LVM volume (for LVM pools)
sudo lvremove /dev/vg_storage/lv_pool_name
```

## 📊 Monitoring Storage Usage

### Check Pool Status
```bash
# List all pools with status
sudo virsh pool-list --all

# Get detailed pool information
sudo virsh pool-info pool-name

# Check pool capacity and usage
sudo virsh pool-info pool-name | grep -E "(Capacity|Allocation|Available)"
```

### Monitor Disk Usage
```bash
# Check filesystem usage (directory pools)
df -h /var/lib/libvirt/images/

# Check LVM usage (LVM pools)
sudo vgdisplay vg_storage
sudo lvdisplay /dev/vg_storage/lv_pool

# List volumes in pool
sudo virsh vol-list pool-name
```

### Storage Performance Monitoring
```bash
# Monitor I/O statistics
iostat -x 1 5

# Check for storage bottlenecks
iotop -o

# Monitor specific pool performance
sudo virsh domblkstat VM_NAME DISK_PATH
```

## 🔄 Pool Maintenance Operations

### Refresh Pool Contents
```bash
# Refresh pool to detect external changes
sudo virsh pool-refresh pool-name

# Verify volumes are detected
sudo virsh vol-list pool-name
```

### Resize Storage Pools

#### Expand Directory Pool
```bash
# For directory pools, expand the underlying filesystem
sudo resize2fs /dev/mapper/vg-lv_storage

# Refresh the pool
sudo virsh pool-refresh pool-name
```

#### Expand LVM Pool
```bash
# Extend the logical volume
sudo lvextend -L +50G /dev/vg_storage/lv_pool

# Refresh the pool
sudo virsh pool-refresh pool-name
```

### Move Volumes Between Pools

```bash
# Copy volume to new pool
sudo virsh vol-clone --pool source-pool volume-name target-pool

# Verify copy
sudo virsh vol-info volume-name target-pool

# Remove from source pool (after verification)
sudo virsh vol-delete volume-name source-pool
```

## 🔒 Storage Security and Permissions

### Set Proper Permissions
```bash
# For directory pools
sudo chown -R root:root /var/lib/libvirt/images/pool-name
sudo chmod -R 755 /var/lib/libvirt/images/pool-name

# Set SELinux contexts
sudo setsebool -P virt_use_nfs 1
sudo restorecon -R /var/lib/libvirt/images/
```

### Secure Storage Access
```bash
# Create dedicated storage group
sudo groupadd libvirt-storage

# Add users to storage group
sudo usermod -a -G libvirt-storage username

# Set group permissions
sudo chgrp -R libvirt-storage /var/lib/libvirt/images/pool-name
sudo chmod -R g+rw /var/lib/libvirt/images/pool-name
```

## 📈 Storage Optimization

### Performance Tuning

#### I/O Scheduler Optimization
```bash
# Check current scheduler
cat /sys/block/sda/queue/scheduler

# Set optimal scheduler for SSDs
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler

# Make permanent in /etc/udev/rules.d/60-scheduler.rules
echo 'ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"' | sudo tee /etc/udev/rules.d/60-scheduler.rules
```

#### Storage Pool Optimization
```bash
# Enable discard for SSD pools
sudo virsh pool-edit pool-name
# Add: <features><discard/></features>

# Set optimal allocation policies
sudo virsh pool-edit pool-name
# Modify allocation and capacity settings
```

### Capacity Planning

#### Monitor Growth Trends
```bash
# Create monitoring script
cat > /usr/local/bin/storage-monitor.sh << 'EOF'
#!/bin/bash
for pool in $(virsh pool-list --name); do
    echo "Pool: $pool"
    virsh pool-info $pool | grep -E "(Capacity|Allocation|Available)"
    echo "---"
done
EOF

sudo chmod +x /usr/local/bin/storage-monitor.sh

# Run monitoring
sudo /usr/local/bin/storage-monitor.sh
```

#### Set Up Alerts
```bash
# Create alert script for low space
cat > /usr/local/bin/storage-alert.sh << 'EOF'
#!/bin/bash
THRESHOLD=90
for pool in $(virsh pool-list --name); do
    USAGE=$(virsh pool-info $pool | grep "Allocation" | awk '{print $2}' | sed 's/[^0-9.]//g')
    CAPACITY=$(virsh pool-info $pool | grep "Capacity" | awk '{print $2}' | sed 's/[^0-9.]//g')
    PERCENT=$(echo "scale=2; $USAGE/$CAPACITY*100" | bc)
    if (( $(echo "$PERCENT > $THRESHOLD" | bc -l) )); then
        echo "WARNING: Pool $pool is ${PERCENT}% full"
    fi
done
EOF

sudo chmod +x /usr/local/bin/storage-alert.sh
```

## 🔧 Advanced Pool Management

### Automated Pool Creation with Ansible

Create a comprehensive playbook for pool management:

```yaml
---
- name: Advanced Storage Pool Management
  hosts: kvm-host
  become: true
  vars:
    storage_configuration:
      pools:
        - name: "ssd-pool"
          type: "dir"
          path: "/var/lib/libvirt/images/ssd"
          performance_tier: "high"
        - name: "archive-pool"
          type: "dir"
          path: "/var/lib/libvirt/images/archive"
          performance_tier: "low"
      policies:
        cleanup_enabled: true
        monitoring_enabled: true
        backup_enabled: true
        
  tasks:
    - name: Create storage directories
      ansible.builtin.file:
        path: "{{ item.path }}"
        state: directory
        mode: '0755'
      loop: "{{ storage_configuration.pools }}"

    - name: Apply performance optimizations
      ansible.builtin.shell: |
        # Apply SSD optimizations
        if [ "{{ item.performance_tier }}" = "high" ]; then
          echo mq-deadline > /sys/block/$(basename $(df {{ item.path }} | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//'))/queue/scheduler
        fi
      loop: "{{ storage_configuration.pools }}"
      when: item.performance_tier is defined
```

### Pool Migration and Backup

#### Backup Pool Configuration
```bash
# Export pool XML
sudo virsh pool-dumpxml pool-name > pool-name-backup.xml

# Backup pool contents
sudo tar -czf pool-name-backup.tar.gz /var/lib/libvirt/images/pool-name/
```

#### Restore Pool Configuration
```bash
# Restore pool definition
sudo virsh pool-define pool-name-backup.xml

# Restore pool contents
sudo tar -xzf pool-name-backup.tar.gz -C /

# Start restored pool
sudo virsh pool-start pool-name
```

## 📋 Storage Pool Policies

### Implement Storage Quotas

```bash
# Set filesystem quotas (if supported)
sudo quotacheck -cum /var/lib/libvirt/images
sudo quotaon /var/lib/libvirt/images

# Set user quotas
sudo setquota -u libvirt-qemu 50G 60G 0 0 /var/lib/libvirt/images
```

### Automated Cleanup

Create cleanup policies:
```bash
# Remove old snapshots
find /var/lib/libvirt/images/ -name "*.snapshot" -mtime +30 -delete

# Clean up temporary files
find /var/lib/libvirt/images/ -name "*.tmp" -mtime +1 -delete

# Archive old VM disks
find /var/lib/libvirt/images/ -name "*.qcow2" -mtime +90 -exec mv {} /var/lib/libvirt/images/archive/ \;
```

## 🔍 Troubleshooting

### Common Storage Issues

**Problem**: "Pool is not active"
**Solution**: 
```bash
sudo virsh pool-start pool-name
sudo virsh pool-autostart pool-name
```

**Problem**: "Permission denied accessing pool"
**Solution**:
```bash
sudo chown -R root:root /var/lib/libvirt/images/pool-name
sudo restorecon -R /var/lib/libvirt/images/pool-name
```

**Problem**: "Pool out of space"
**Solution**:
```bash
# Check usage
df -h /var/lib/libvirt/images/
# Clean up or expand storage
# Move VMs to other pools if needed
```

## 📚 Best Practices

### Pool Organization
- **Separate by purpose**: development, staging, production
- **Separate by performance**: SSD pools for databases, HDD for archives
- **Separate by security**: isolated pools for sensitive workloads

### Naming Conventions
- Use descriptive names: `prod-db-pool`, `dev-web-pool`
- Include performance tier: `ssd-high-perf`, `hdd-archive`
- Include location if relevant: `datacenter1-pool`

### Capacity Management
- Monitor usage regularly
- Set up automated alerts at 80% capacity
- Plan for growth with 20% buffer
- Implement automated cleanup policies

## 🔗 Related Documentation

- **Tutorial**: [Storage Pool Creation](../tutorials/03-storage-pool-creation.md)
- **Reference**: [Storage Variables](../reference/variables/role-variables.md#storage)
- **Explanation**: [Storage Pool Management](../explanations/storage-pool-management.md)
- **Advanced**: [Configure Backup Automation](configure-backup-automation.md)

---

*This guide covered comprehensive storage pool management. For initial setup, see the tutorials. For specific storage variables and options, check the reference documentation.*
