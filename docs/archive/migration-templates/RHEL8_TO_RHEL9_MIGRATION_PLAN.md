# Migration Plan: RHEL 8 → RHEL 9

**Migration Plan Created**: July 14, 2025  
**Migration Type**: RHEL 8 → RHEL 9  
**Estimated Duration**: 4-6 hours  
**Downtime Window**: 2-3 hours  

## Migration Overview

This plan provides step-by-step procedures for migrating a KVM host from RHEL 8 to RHEL 9 using the Qubinode KVM Host Setup Collection.

### Migration Strategy: **In-place Upgrade**
- **Approach**: leapp upgrade utility
- **Fallback**: Full system restore from backup
- **Validation**: Comprehensive post-migration testing

---

## Pre-Migration Phase (T-24 hours)

### Step 1: Environment Preparation
**Duration**: 2 hours  
**Responsibility**: Infrastructure Team

#### 1.1 Backup Verification
```bash
# Verify all backups are complete and valid
ansible-playbook -i inventories/local/hosts playbooks/backup-validation.yml \
  --extra-vars "backup_type=full migration_date=$(date +%Y%m%d)"
```

**Checkpoint P1.1**: All backups verified  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

#### 1.2 System Health Check
```bash
# Run comprehensive system health check
./scripts/pre-migration-health-check.sh
```

**Checkpoint P1.2**: System health validated  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 2: Dependency Management
**Duration**: 1 hour  
**Responsibility**: Application Team

#### 2.1 Service Dependencies
- [ ] Notify dependent services of maintenance window
- [ ] Configure external monitoring exclusions
- [ ] Prepare rollback communication plan

**Checkpoint P2.1**: Dependencies managed  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

---

## Migration Phase (T+0 hours)

### Step 3: Pre-Migration Backup (T+0 minutes)
**Duration**: 30 minutes  
**Responsibility**: Infrastructure Team

```bash
# Create final pre-migration backup
ansible-playbook -i inventories/local/hosts playbooks/backup-pre-migration.yml
```

**Checkpoint M3.1**: Final backup completed  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 4: VM Shutdown (T+30 minutes)
**Duration**: 15 minutes  
**Responsibility**: Virtualization Team

```bash
# Gracefully shutdown all VMs
for vm in $(virsh list --name); do
  echo "Shutting down VM: $vm"
  virsh shutdown "$vm"
done

# Wait for clean shutdown
sleep 300

# Force shutdown any remaining VMs
for vm in $(virsh list --name); do
  echo "Force stopping VM: $vm"
  virsh destroy "$vm"
done
```

**Checkpoint M4.1**: All VMs stopped  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**VMs Shutdown**: _____  

### Step 5: System Preparation (T+45 minutes)
**Duration**: 15 minutes  
**Responsibility**: Infrastructure Team

```bash
# Install leapp utility
dnf install -y leapp-upgrade

# Download RHEL 9 data
leapp preupgrade

# Review preupgrade report
cat /var/log/leapp/leapp-report.txt
```

**Checkpoint M5.1**: System prepared for upgrade  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 6: RHEL Upgrade (T+60 minutes)
**Duration**: 90 minutes  
**Responsibility**: Infrastructure Team

```bash
# Start the upgrade process
leapp upgrade

# System will reboot automatically
# Monitor console for progress
```

**Checkpoint M6.1**: Upgrade initiated  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

**Checkpoint M6.2**: System rebooted  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

---

## Post-Migration Phase (T+150 minutes)

### Step 7: System Validation (T+150 minutes)
**Duration**: 20 minutes  
**Responsibility**: Infrastructure Team

```bash
# Verify RHEL 9 installation
cat /etc/os-release

# Check system status
systemctl status

# Verify kernel version
uname -r

# Check available memory and storage
free -h
df -h
```

**Checkpoint P7.1**: System validation completed  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**RHEL Version**: _____  

### Step 8: KVM Infrastructure Restoration (T+170 minutes)
**Duration**: 30 minutes  
**Responsibility**: Virtualization Team

```bash
# Install KVM and virtualization packages
dnf groupinstall -y "Virtualization Host"

# Start libvirt services
systemctl enable --now libvirtd

# Restore libvirt configurations
ansible-playbook -i inventories/local/hosts playbooks/restore-libvirt-config.yml
```

**Checkpoint P8.1**: KVM infrastructure restored  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 9: Qubinode Collection Update (T+200 minutes)
**Duration**: 15 minutes  
**Responsibility**: Automation Team

```bash
# Update Ansible and collections
pip3 install --upgrade ansible-core

# Install latest Qubinode collection
ansible-galaxy collection install -U qubinode.kvmhost_setup_collection

# Verify collection installation
ansible-galaxy collection list | grep qubinode
```

**Checkpoint P9.1**: Collection updated  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**Collection Version**: _____  

### Step 10: KVM Host Reconfiguration (T+215 minutes)
**Duration**: 45 minutes  
**Responsibility**: Infrastructure Team

```bash
# Run full KVM host setup
ansible-playbook -i inventories/local/hosts playbooks/kvmhost-setup.yml \
  --extra-vars "rhel_version=9"

# Verify all roles completed successfully
```

**Checkpoint P10.1**: KVM host reconfigured  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 11: VM Restoration (T+260 minutes)
**Duration**: 20 minutes  
**Responsibility**: Virtualization Team

```bash
# Start all VMs
for vm in $(virsh list --name --inactive); do
  echo "Starting VM: $vm"
  virsh start "$vm"
done

# Verify VM status
virsh list --all
```

**Checkpoint P11.1**: VMs restored  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**VMs Started**: _____  

---

## Validation Phase (T+280 minutes)

### Step 12: Comprehensive Testing (T+280 minutes)
**Duration**: 40 minutes  
**Responsibility**: QA Team

#### 12.1 System Validation
```bash
# Run system validation tests
ansible-playbook -i inventories/local/hosts playbooks/post-migration-validation.yml
```

#### 12.2 Application Testing
- [ ] Test all critical applications
- [ ] Verify database connectivity
- [ ] Check web service functionality
- [ ] Validate backup systems

#### 12.3 Performance Validation
- [ ] CPU performance within expected range
- [ ] Memory utilization normal
- [ ] Storage I/O performance acceptable
- [ ] Network connectivity functional

**Checkpoint V12.1**: All validation tests passed  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

---

## Migration Completion (T+320 minutes)

### Step 13: Final Documentation (T+320 minutes)
**Duration**: 20 minutes  
**Responsibility**: Documentation Team

- [ ] Update system inventory
- [ ] Document configuration changes
- [ ] Update monitoring configurations
- [ ] Archive migration artifacts

**Checkpoint F13.1**: Documentation completed  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 14: Stakeholder Notification (T+340 minutes)
**Duration**: 10 minutes  
**Responsibility**: Project Manager

- [ ] Notify stakeholders of successful migration
- [ ] Update service status pages
- [ ] Schedule post-migration review meeting
- [ ] Archive migration documentation

**Checkpoint F14.1**: Stakeholders notified  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

---

## Success Criteria

### Migration Success Indicators
- [ ] **System Health**: All system services operational
- [ ] **VM Functionality**: All VMs started and accessible
- [ ] **Network Connectivity**: All network services functional
- [ ] **Storage Access**: All storage pools and volumes accessible
- [ ] **Application Services**: Critical applications operational
- [ ] **Performance**: System performance within acceptable range

### Post-Migration Tasks (within 48 hours)
- [ ] Monitor system stability
- [ ] Verify backup operations
- [ ] Update documentation
- [ ] Conduct lessons learned session
- [ ] Plan follow-up optimizations

---

## Migration Team Contacts

| Role | Name | Contact | Backup |
|------|------|---------|--------|
| **Migration Lead** | _________________ | _________________ | _________________ |
| **Infrastructure** | _________________ | _________________ | _________________ |
| **Virtualization** | _________________ | _________________ | _________________ |
| **Application** | _________________ | _________________ | _________________ |
| **QA/Testing** | _________________ | _________________ | _________________ |

---

## Migration Log

**Migration Started**: ___:___ on ___________  
**Migration Completed**: ___:___ on ___________  
**Total Duration**: _____ hours _____ minutes  
**Issues Encountered**: _________________________________  
**Lessons Learned**: ___________________________________  

**Migration Status**: 
- [ ] **Successful**
- [ ] **Successful with Issues** (details: _____________)
- [ ] **Failed** (rollback initiated)

---

*This migration plan is part of the Qubinode KVM Host Setup Collection migration framework. For rollback procedures, see the corresponding rollback plan.*
