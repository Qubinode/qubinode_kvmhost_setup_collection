# kvmhost_storage

Advanced storage management for KVM hosts including LVM, performance optimization, and monitoring.

## Description

This role provides comprehensive storage management for KVM hosts as part of the Qubinode Collection's modular architecture (ADR-0002). It handles:

- **LVM Configuration**: Automated LVM setup for VM storage
- **Advanced Storage Pools**: Specialized libvirt storage pools for different use cases
- **Performance Optimization**: I/O scheduler tuning and kernel parameter optimization
- **Storage Monitoring**: Health checks, space monitoring, and alerting
- **Backup & Snapshots**: VM backup and snapshot management (optional)

## Requirements

- **Dependencies**: `kvmhost_base`, `kvmhost_libvirt` (configurable)
- **Collections**: `community.general`, `community.libvirt`, `ansible.posix`
- **Minimum Ansible**: 2.9
- **Storage**: Additional block device for LVM (if enabled)

## Role Variables

### Basic Configuration
```yaml
kvmhost_storage_enabled: true
kvmhost_storage_require_base: true
kvmhost_storage_require_libvirt: true
```

### LVM Configuration
```yaml
kvmhost_storage_lvm_enabled: false
kvmhost_storage_lvm_device: "sdb"  # Block device for LVM
kvmhost_storage_lvm_vg_name: "libvirt"
kvmhost_storage_lvm_force_create: false

kvmhost_storage_lvm_volumes:
  - name: vm_images
    size: "50%VG"
    mount_dir: "/var/lib/libvirt/images"
    fstype: "xfs"
    enabled: true
  - name: vm_backups
    size: "30%VG"
    mount_dir: "/var/lib/libvirt/backups"
    fstype: "xfs"
    enabled: false
```

### Advanced Storage Pools
```yaml
kvmhost_storage_pools_enabled: true
kvmhost_storage_advanced_pools:
  - name: performance
    type: dir
    path: "/var/lib/libvirt/performance"
    autostart: true
    enabled: false
  - name: backup
    type: dir
    path: "/var/lib/libvirt/backups"
    autostart: false
    enabled: false
```

### Performance Optimization
```yaml
kvmhost_storage_performance_enabled: true
kvmhost_storage_io_scheduler: "mq-deadline"  # none, mq-deadline, bfq, kyber
kvmhost_storage_queue_depth: 32

kvmhost_storage_mount_options:
  xfs: "defaults,noatime,nodiratime,logbsize=256k,allocsize=1m"
  ext4: "defaults,noatime,nodiratime,commit=60"
```

### Monitoring Configuration
```yaml
kvmhost_storage_monitoring_enabled: true
kvmhost_storage_space_threshold: 80  # Percentage
kvmhost_storage_inode_threshold: 80  # Percentage

kvmhost_storage_health_checks:
  - disk_usage
  - inode_usage
  - lvm_health
  - filesystem_errors
```

### Backup & Snapshots
```yaml
kvmhost_storage_backup_enabled: false
kvmhost_storage_backup_retention_days: 7
kvmhost_storage_snapshot_enabled: false
```

## Dependencies

This role depends on:
- `kvmhost_base` - for base system configuration
- `kvmhost_libvirt` - for libvirt storage pool integration

Dependencies can be disabled:
```yaml
kvmhost_storage_require_base: false
kvmhost_storage_require_libvirt: false
```

## Example Playbooks

### Basic Usage (No LVM)
```yaml
- hosts: kvm_hosts
  roles:
    - kvmhost_storage
```

### LVM Storage Configuration
```yaml
- hosts: kvm_hosts
  vars:
    kvmhost_storage_lvm_enabled: true
    kvmhost_storage_lvm_device: "sdb"
    kvmhost_storage_lvm_volumes:
      - name: vm_images
        size: "60%VG"
        mount_dir: "/var/lib/libvirt/images"
        fstype: "xfs"
        enabled: true
      - name: vm_backups
        size: "40%VG"
        mount_dir: "/var/lib/libvirt/backups"
        fstype: "xfs"
        enabled: true
  roles:
    - kvmhost_storage
```

### Performance-Optimized Configuration
```yaml
- hosts: production_kvm_hosts
  vars:
    kvmhost_storage_performance_enabled: true
    kvmhost_storage_io_scheduler: "none"  # For NVMe SSDs
    kvmhost_storage_monitoring_enabled: true
    kvmhost_storage_space_threshold: 75
    
    kvmhost_storage_advanced_pools:
      - name: production
        path: "/var/lib/libvirt/production"
        enabled: true
        autostart: true
      - name: staging
        path: "/var/lib/libvirt/staging"
        enabled: true
        autostart: false
  roles:
    - kvmhost_storage
```

### Development Environment
```yaml
- hosts: dev_kvm_hosts
  vars:
    kvmhost_storage_lvm_enabled: true
    kvmhost_storage_lvm_device: "vdb"
    kvmhost_storage_performance_enabled: false  # Relaxed for dev
    kvmhost_storage_backup_enabled: false
    kvmhost_storage_monitoring_enabled: true
    kvmhost_storage_space_threshold: 90  # More relaxed
  roles:
    - kvmhost_storage
```

## Features

### LVM Integration

The role provides comprehensive LVM support:
- **Physical Volume Creation**: Automated PV setup on specified devices
- **Volume Group Management**: Creates and manages VGs for VM storage
- **Logical Volume Creation**: Configurable LVs with percentage-based sizing
- **Filesystem Creation**: Automated filesystem creation with optimized mount options
- **Mount Management**: `/etc/fstab` configuration and mounting

### Storage Performance Optimization

Performance optimizations include:
- **I/O Scheduler Configuration**: Optimizes scheduler per workload type
- **Kernel Parameter Tuning**: VM-optimized kernel settings
- **Transparent Huge Pages**: Disables THP for better VM performance
- **Block Device Tuning**: Queue depth and readahead optimization
- **Filesystem Mount Options**: Performance-tuned mount options

### Advanced Storage Pools

Beyond basic libvirt pools:
- **Specialized Pools**: Performance, backup, staging, development pools
- **Flexible Configuration**: Per-pool autostart and permission settings
- **Integration**: Seamless integration with libvirt ecosystem

### Monitoring & Health Checks

Comprehensive monitoring includes:
- **Space Monitoring**: Configurable thresholds for disk usage
- **Inode Monitoring**: Prevents filesystem exhaustion
- **LVM Health Checks**: Volume group and logical volume status
- **Filesystem Error Detection**: Automated error log analysis
- **Cron Integration**: Scheduled monitoring with logging

### Legacy Compatibility

Maintains compatibility with:
- `swygue_lvm` role variables
- Original `kvmhost_setup` storage variables
- Existing storage configurations

## Storage Layout Examples

### Development Setup
```
/dev/sdb (20GB)
└── VG: libvirt
    ├── LV: vm_images (16GB) → /var/lib/libvirt/images
    └── LV: vm_snapshots (4GB) → /var/lib/libvirt/snapshots
```

### Production Setup
```
/dev/sdb (500GB)
└── VG: libvirt
    ├── LV: vm_images (300GB) → /var/lib/libvirt/images
    ├── LV: vm_backups (150GB) → /var/lib/libvirt/backups
    └── LV: vm_snapshots (50GB) → /var/lib/libvirt/snapshots

Additional Pools:
├── performance → /var/lib/libvirt/performance
└── staging → /var/lib/libvirt/staging
```

## I/O Scheduler Recommendations

| Storage Type | Recommended Scheduler | Use Case |
|--------------|----------------------|----------|
| **Rotating Disks** | `mq-deadline` | Traditional HDDs, balanced performance |
| **SATA SSDs** | `mq-deadline` | SATA SSDs with moderate parallelism |
| **NVMe SSDs** | `none` | High-performance NVMe with hardware queuing |
| **Hybrid/Mixed** | `bfq` | Mixed workloads, fairness important |

## Filesystem Recommendations

| Filesystem | Use Case | Mount Options |
|------------|----------|---------------|
| **XFS** | Large files, high performance | `noatime,nodiratime,logbsize=256k` |
| **EXT4** | General purpose, compatibility | `noatime,nodiratime,commit=60` |

## Monitoring Commands

The role provides several monitoring utilities:

```bash
# Run health check
/usr/local/bin/kvmhost-storage-health

# Run monitoring (also in cron)
/usr/local/bin/kvmhost-storage-monitor

# Check logs
tail -f /var/log/kvmhost-storage.log

# Manual storage status
virsh pool-list --all
lvs
vgs
df -h
```

## Troubleshooting

### Common Issues

1. **LVM Device Not Found**: Ensure the device exists and is not already in use
2. **Insufficient Space**: Check volume sizes don't exceed VG capacity
3. **Permission Denied**: Verify libvirt directories have correct ownership
4. **Performance Issues**: Review I/O scheduler settings for your storage type

### Debug Mode
```yaml
kvmhost_storage_debug_enabled: true
```

### Manual LVM Commands
```bash
# Check physical volumes
pvdisplay

# Check volume groups
vgdisplay

# Check logical volumes
lvdisplay

# Check filesystem usage
df -h /var/lib/libvirt/*
```

## Integration

This role integrates with:
- **kvmhost_libvirt**: Uses libvirt storage pools
- **kvmhost_base**: Requires base system setup
- **Monitoring Systems**: Provides structured logging
- **Backup Solutions**: Prepared directories and scripts

## Performance Impact

Expected performance improvements:
- **I/O Scheduler Optimization**: 10-30% improvement for mixed workloads
- **Kernel Parameter Tuning**: 5-15% improvement for VM-heavy workloads
- **Filesystem Optimization**: 5-20% improvement for large file operations
- **LVM Striping**: Up to 2x improvement with multiple devices (future)

## License

Apache-2.0

## Author Information

Qubinode Community - Part of the Qubinode KVM Host Setup Collection
