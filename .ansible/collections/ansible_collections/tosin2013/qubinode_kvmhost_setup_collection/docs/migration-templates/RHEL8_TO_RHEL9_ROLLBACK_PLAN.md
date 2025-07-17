# Rollback Plan: RHEL 9 → RHEL 8

**Rollback Plan Created**: July 14, 2025  
**Migration Target**: RHEL 8 → RHEL 9  
**Rollback Scenario**: Emergency restoration to RHEL 8  

## Rollback Triggers

### Automatic Rollback Conditions
1. **System Boot Failure**: System fails to boot after upgrade
2. **Critical Service Failure**: Essential services fail to start
3. **Data Corruption**: Evidence of data loss or corruption
4. **Performance Degradation**: Unacceptable performance impact (>50% degradation)

### Manual Rollback Conditions
1. **Application Compatibility**: Critical applications fail compatibility testing
2. **Business Requirements**: Business requirements not met after migration
3. **Security Concerns**: New security vulnerabilities discovered
4. **Stakeholder Decision**: Management decision to rollback

---

## Rollback Strategy

### Primary Rollback Method: **Full System Restore**
- **Approach**: Complete system restoration from pre-migration backup
- **Duration**: 2-3 hours
- **Data Loss**: Minimal (limited to migration window activities)

### Alternative Method: **VM-only Rollback**
- **Approach**: Restore VMs to RHEL 8 host if host migration succeeded
- **Duration**: 1-2 hours
- **Use Case**: When host migration succeeded but VM compatibility issues

---

## Rollback Decision Tree

```
Migration Issues Detected
         |
         v
    Critical Issue?
    /            \
  Yes              No
   |                |
   v                v
Immediate         Document
Rollback          & Monitor
   |                |
   v                v
Execute           Continue
Rollback          Migration
Plan
```

---

## Rollback Procedures

### Phase 1: Rollback Initiation (R+0 minutes)

#### Step 1: Emergency Assessment (R+0 minutes)
**Duration**: 15 minutes  
**Responsibility**: Migration Lead

##### 1.1 Issue Identification
- [ ] Document specific failure symptoms
- [ ] Assess impact on business operations
- [ ] Determine rollback urgency level
- [ ] Notify stakeholders of rollback decision

**Checkpoint R1.1**: Rollback decision confirmed  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**Issue Type**: _____________________  

##### 1.2 Team Mobilization
- [ ] Assemble rollback team
- [ ] Establish communication channels
- [ ] Activate emergency procedures
- [ ] Prepare rollback environment

**Checkpoint R1.2**: Team mobilized  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Phase 2: System Preparation (R+15 minutes)

#### Step 2: Current State Backup (R+15 minutes)
**Duration**: 20 minutes  
**Responsibility**: Infrastructure Team

```bash
# Create snapshot of current failed state for analysis
ansible-playbook -i inventories/local/hosts playbooks/emergency-backup.yml \
  --extra-vars "backup_type=failed_state backup_date=$(date +%Y%m%d-%H%M%S)"
```

**Checkpoint R2.1**: Failed state backed up  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

#### Step 3: Backup Verification (R+35 minutes)
**Duration**: 10 minutes  
**Responsibility**: Infrastructure Team

```bash
# Verify pre-migration backup integrity
./scripts/verify-backup-integrity.sh /backup/pre-migration/
```

**Checkpoint R3.1**: Backup integrity verified  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Phase 3: System Rollback (R+45 minutes)

#### Step 4: Boot from Recovery Media (R+45 minutes)
**Duration**: 10 minutes  
**Responsibility**: Infrastructure Team

1. Insert RHEL 8 rescue media
2. Boot system in rescue mode
3. Access rescue environment
4. Mount backup storage

**Checkpoint R4.1**: Recovery environment active  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

#### Step 5: System Restoration (R+55 minutes)
**Duration**: 60 minutes  
**Responsibility**: Infrastructure Team

```bash
# Restore system from full backup
./scripts/restore-full-system.sh /backup/pre-migration/system-backup.tar.gz

# Restore bootloader
grub2-install /dev/sda
grub2-mkconfig -o /boot/grub2/grub.cfg
```

**Checkpoint R5.1**: System files restored  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

#### Step 6: System Reboot (R+115 minutes)
**Duration**: 10 minutes  
**Responsibility**: Infrastructure Team

1. Remove rescue media
2. Reboot system
3. Monitor boot process
4. Verify RHEL 8 boot successful

**Checkpoint R6.1**: System rebooted to RHEL 8  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Phase 4: Service Restoration (R+125 minutes)

#### Step 7: Base System Validation (R+125 minutes)
**Duration**: 15 minutes  
**Responsibility**: Infrastructure Team

```bash
# Verify system identity
cat /etc/os-release

# Check system services
systemctl status

# Verify network connectivity
ping -c 3 google.com
```

**Checkpoint R7.1**: Base system operational  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

#### Step 8: Configuration Restoration (R+140 minutes)
**Duration**: 20 minutes  
**Responsibility**: Infrastructure Team

```bash
# Restore libvirt configurations
if [[ -f /backup/pre-migration/libvirt-config.backup ]]; then
  cp /backup/pre-migration/libvirt-config.backup /etc/libvirt/
fi
```

**Checkpoint R8.1**: Configurations restored  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

#### Step 9: Virtual Machine Restoration (R+160 minutes)
**Duration**: 30 minutes  
**Responsibility**: Virtualization Team

```bash
# Restore VM definitions
if [[ -d /backup/pre-migration/vm-definitions/ ]]; then
  for vm_xml in /backup/pre-migration/vm-definitions/*.xml; do
    virsh define "$vm_xml"
  done
fi

# Start VMs
for vm in $(virsh list --name --inactive); do
  virsh start "$vm"
done
```

**Checkpoint R9.1**: VMs restored and started  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**VMs Restored**: _____  

### Phase 5: Validation and Recovery (R+190 minutes)

#### Step 10: System Validation (R+190 minutes)
**Duration**: 30 minutes  
**Responsibility**: QA Team

##### 10.1 Infrastructure Validation
- [ ] All system services operational
- [ ] Network connectivity restored
- [ ] Storage systems accessible
- [ ] KVM infrastructure functional

##### 10.2 Application Validation
- [ ] Critical applications operational
- [ ] Database connectivity verified
- [ ] Web services responding
- [ ] Backup systems functional

**Checkpoint R10.1**: System validation completed  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

#### Step 11: Performance Verification (R+220 minutes)
**Duration**: 20 minutes  
**Responsibility**: Performance Team

```bash
# Run performance baseline tests
./scripts/performance-baseline.sh

# Compare with pre-migration metrics
./scripts/compare-performance.sh
```

**Checkpoint R11.1**: Performance verified  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

---

## Post-Rollback Activities

### Immediate Actions (within 2 hours)
- [ ] **Stakeholder Notification**: Inform all stakeholders of rollback completion
- [ ] **Service Monitoring**: Implement enhanced monitoring for 24 hours
- [ ] **Documentation**: Document rollback process and issues encountered
- [ ] **Backup Verification**: Verify all backup systems operational

### Short-term Actions (within 48 hours)
- [ ] **Root Cause Analysis**: Conduct thorough analysis of migration failure
- [ ] **Process Review**: Review migration procedures and identify improvements
- [ ] **Testing Enhancement**: Enhance pre-migration testing procedures
- [ ] **Communication Review**: Review communication and escalation procedures

### Long-term Actions (within 2 weeks)
- [ ] **Migration Planning**: Develop improved migration strategy
- [ ] **Team Training**: Provide additional training based on lessons learned
- [ ] **Process Updates**: Update migration and rollback procedures
- [ ] **Technology Review**: Evaluate alternative migration approaches

---

## Rollback Success Criteria

### Technical Success Indicators
- [ ] **System Identity**: System reports RHEL 8 version
- [ ] **Service Functionality**: All critical services operational
- [ ] **VM Operations**: All VMs running and accessible
- [ ] **Network Connectivity**: All network services functional
- [ ] **Data Integrity**: No data loss detected
- [ ] **Performance**: Performance at pre-migration levels

### Business Success Indicators
- [ ] **Service Availability**: Business services fully operational
- [ ] **User Access**: All users can access required systems
- [ ] **Data Access**: All business data accessible
- [ ] **Process Continuity**: Business processes uninterrupted

---

## Rollback Team Contacts

| Role | Name | Contact | Escalation |
|------|------|---------|------------|
| **Rollback Lead** | _________________ | _________________ | _________________ |
| **Infrastructure** | _________________ | _________________ | _________________ |
| **Virtualization** | _________________ | _________________ | _________________ |
| **Applications** | _________________ | _________________ | _________________ |
| **Executive Sponsor** | _________________ | _________________ | _________________ |

---

## Emergency Contacts

### Business Contacts
- **Business Continuity**: _________________
- **Communications**: _________________
- **Legal/Compliance**: _________________

### Technical Contacts
- **Vendor Support**: _________________
- **Infrastructure Vendor**: _________________
- **Backup Vendor**: _________________

---

## Rollback Log

**Rollback Initiated**: ___:___ on ___________  
**Rollback Completed**: ___:___ on ___________  
**Total Duration**: _____ hours _____ minutes  
**Business Impact**: ___________________________________  
**Data Loss**: _________________________________________  
**Root Cause**: _______________________________________  

**Rollback Status**: 
- [ ] **Successful** - Full restoration achieved
- [ ] **Partial Success** - Some issues remain (details: _____________)
- [ ] **Failed** - Escalation required (contact: _____________)

**Lessons Learned**: ___________________________________  
**Process Improvements**: ______________________________  

---

*This rollback plan is part of the Qubinode KVM Host Setup Collection migration framework. This plan should be reviewed and updated regularly based on infrastructure changes and lessons learned.*
