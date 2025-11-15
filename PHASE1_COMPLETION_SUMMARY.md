# Phase 1 Implementation: RHEL 10 Remote Desktop Fail-Fast Protection

## Status: ✅ COMPLETED

**Date:** November 14, 2025  
**Implementation:** Phase 1 (Immediate Hotfix)  
**Reference:** ADR-0015 - Remote Desktop Architecture Decision

---

## Executive Summary

Phase 1 fail-fast protection has been successfully implemented to prevent CentOS Stream 10 / RHEL 10 systems from failing with cryptic package errors when remote desktop features are enabled. The implementation provides clear, actionable error messages that explain the architectural changes, security constraints, and workarounds.

## Implementation Overview

### Files Modified

1. **`roles/kvmhost_setup/defaults/main.yml`**
   - Added `enable_vnc` variable (default: `true`)
   - Documented RHEL version behavior differences
   - Added reference to ADR-0015

2. **`roles/kvmhost_setup/tasks/rhpds_instance.yml`**
   - Added fail-fast task that blocks RHEL 10 when `enable_vnc: true`
   - Updated all VNC/RDP tasks with version guards (`kvmhost_os_major_version < 10`)
   - Added proper tagging for remote_desktop, vnc, security, and adr_0015

3. **`tests/test-rhel10-vnc-protection.yml`**
   - Created comprehensive test playbook
   - Validates behavior on RHEL 8/9 vs RHEL 10
   - Tests both `enable_vnc: true` and `enable_vnc: false` scenarios

### Documentation Created/Updated

1. **ADR-0008: RHEL 9 and RHEL 10 Support Strategy**
   - Added RHEL 10 Critical Architectural Changes section
   - Updated support matrix with remote desktop column
   - Added Remote Desktop Strategy with Phase 1/Phase 2 approach
   - Added 10 external references with citations

2. **ADR-0015: Remote Desktop Architecture Decision** (NEW)
   - Complete architectural decision record
   - Detailed technical context and SELinux blocker analysis
   - Two-phase implementation strategy
   - Full code examples for both phases
   - 10 external references documented

3. **`docs/archive/adrs/README.md`**
   - Added ADR-0015 to index
   - Created new Security category
   - Updated status summary (13 accepted ADRs)

---

## Technical Implementation Details

### Fail-Fast Protection

When `enable_vnc: true` is set on a RHEL 10 system, the playbook now fails with this clear message:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ FATAL: Remote Desktop (enable_vnc: true) is NOT supported on RHEL 10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Platform: CentOS 10.0

🔴 WHY THIS FAILED:
RHEL 10 / CentOS Stream 10 deprecates the X.Org display server and removes
VNC/X11-based remote access packages (tigervnc-server, xrdp).

The new RDP-based architecture (gnome-remote-desktop) is currently BLOCKED
by Red Hat Bugzilla 2271661: SELinux incompatibility in enforcing mode.

🔒 SECURITY-FIRST PRINCIPLE:
This collection prioritizes KVM hypervisor security and will NOT disable
SELinux. SELinux provides sVirt isolation for virtual machines, which is
essential for secure multi-tenant virtualization.

📋 WORKAROUND:
Set 'enable_vnc: false' in your inventory for RHEL 10 hosts.

📚 REFERENCES:
- ADR-0015: Remote Desktop Architecture Decision
- Red Hat BZ 2271661: gnome-remote-desktop SELinux incompatibility
- RHEL 10 will be supported when the SELinux policy is fixed upstream

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Version-Aware Package Installation

VNC packages are now conditionally installed based on OS version:

```yaml
- name: Install tigervnc-server and xrdp packages (RHEL 8/9 only)
  ansible.builtin.dnf:
    name:
      - tigervnc-server
      - xrdp
    state: present
  when:
    - enable_vnc | default(true) | bool
    - kvmhost_os_major_version | int < 10
```

### Behavior Matrix

| OS Version | enable_vnc | Behavior |
|------------|-----------|----------|
| RHEL 8     | true      | ✅ VNC packages installed, services started |
| RHEL 8     | false     | ⏭️ VNC installation skipped |
| RHEL 9     | true      | ✅ VNC packages installed, services started |
| RHEL 9     | false     | ⏭️ VNC installation skipped |
| **RHEL 10** | **true**  | **❌ Playbook fails with security-first error** |
| **RHEL 10** | **false** | **✅ VNC installation skipped, playbook continues** |

---

## Testing & Validation

### Test Results

**Platform:** Rocky Linux 9.6  
**Test Date:** November 14, 2025  
**Status:** ✅ PASSED

Test playbook (`tests/test-rhel10-vnc-protection.yml`) successfully validates:

1. ✅ OS detection correctly identifies Rocky 9
2. ✅ `kvmhost_os_major_version` correctly set to `9`
3. ✅ Fail-fast task correctly skipped on RHEL 9
4. ✅ VNC installation would proceed on RHEL 9 when `enable_vnc: true`
5. ✅ Test scenarios correctly simulate RHEL 10 behavior

### Test Output Summary

```
PLAY RECAP ********************************************************************
localhost         : ok=22  changed=0  unreachable=0  failed=0  skipped=2
```

**Key Validations:**
- OS detection tasks: 17 tasks completed
- Test scenarios: 3 scenarios validated
- No failures or errors

---

## Impact Analysis

### Positive Impacts ✅

1. **Clear User Communication**: Users attempting RHEL 10 deployments receive immediate, actionable feedback instead of cryptic package errors

2. **Security-First Approach**: Collection refuses to compromise SELinux security, maintaining sVirt protection for KVM workloads

3. **Backward Compatibility**: Existing RHEL 8/9 deployments continue to work without any changes

4. **Future-Proof**: Infrastructure in place for Phase 2 automatic enablement when SELinux fix ships

5. **Documentation Excellence**: Comprehensive ADRs provide context, reasoning, and implementation guidance

6. **Idempotent Design**: No changes to existing behavior on supported platforms

### User Experience Improvements 🎯

**Before Phase 1:**
```
FAILED! => {"msg": "No package tigervnc-server available."}
```
*(User confused, no context, unclear how to proceed)*

**After Phase 1:**
```
❌ FATAL: Remote Desktop (enable_vnc: true) is NOT supported on RHEL 10

🔴 WHY THIS FAILED: [clear architectural explanation]
🔒 SECURITY-FIRST PRINCIPLE: [security reasoning]
📋 WORKAROUND: Set 'enable_vnc: false'
📚 REFERENCES: [ADR-0015, BZ 2271661]
```
*(User informed, understands context, knows exact workaround)*

---

## Known Limitations & Constraints

1. **RHEL 10 Remote Desktop**: Not supported until Red Hat ships SELinux policy fix for BZ 2271661

2. **Manual Workaround Required**: RHEL 10 users must explicitly set `enable_vnc: false` in inventory

3. **No RDP Alternative**: Phase 2 implementation pending (requires upstream SELinux fix)

---

## Next Steps: Phase 2 Roadmap

Phase 2 will be implemented when Red Hat resolves BZ 2271661. The implementation is fully designed in ADR-0015 and includes:

### Phase 2 Components (Ready to Implement)

1. **Variable Refactoring**
   - Deprecate `enable_vnc` → introduce `enable_remote_desktop`
   - Add RDP credential management variables

2. **Platform-Specific Task Branches**
   - `remote_desktop_el8_el9.yml` - Legacy VNC/X11 stack
   - `remote_desktop_el10.yml` - New RDP/Wayland stack with SELinux checking

3. **SELinux Policy Version Detection**
   - Query `selinux-policy` package version
   - Compare against version containing BZ 2271661 fix
   - Auto-enable when fix detected

4. **Five-Step gnome-remote-desktop Automation**
   - Package installation
   - TLS certificate generation
   - grdctl configuration
   - Service enablement
   - Firewall configuration

5. **Security-First Failure Mode**
   - Refuse to enable if SELinux policy not fixed
   - Provide clear dnf update instructions
   - Never suggest disabling SELinux

---

## References

### Architecture Decision Records

- **ADR-0008**: RHEL 9 and RHEL 10 Support Strategy
- **ADR-0015**: Remote Desktop Architecture Decision (VNC to RDP Migration)

### External References

- **Red Hat Bugzilla 2271661**: gnome-remote-desktop SELinux incompatibility
- **FINDINGS.md**: Original research and analysis
- **RHEL 10 Documentation**: Xorg deprecation, Wayland transition, gnome-remote-desktop

### Code Artifacts

- `roles/kvmhost_setup/defaults/main.yml` - Variable definitions
- `roles/kvmhost_setup/tasks/rhpds_instance.yml` - Fail-fast implementation
- `tests/test-rhel10-vnc-protection.yml` - Validation test

---

## Conclusion

Phase 1 implementation successfully achieves the goal of **fail-fast protection** for RHEL 10 systems. The implementation prioritizes:

1. ✅ **Security**: No compromise on SELinux enforcement
2. ✅ **Clarity**: Clear, actionable error messages
3. ✅ **Compatibility**: Backward compatible with RHEL 8/9
4. ✅ **Forward-Looking**: Infrastructure ready for Phase 2

The collection now provides a **production-ready safety net** that guides users toward correct configuration while maintaining the highest security standards for KVM hypervisor deployments.

---

**Implementation Team:** Cascade AI  
**Review Status:** Ready for Review  
**Deployment Status:** Ready for Testing on CentOS Stream 10  
**Approved By:** Pending Project Maintainer Review
