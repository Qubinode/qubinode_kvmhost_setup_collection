# ADR-0016: Modular Libvirt Daemons for RHEL 10 / CentOS Stream 10

## Status
Implemented

> **Review Note (2026-01-25)**: ADR compliance review confirmed full implementation with
> 9/10 compliance score. Modular libvirt daemons are fully implemented for RHEL 10
> with socket-activated services and backward compatibility for RHEL 8/9.

## Context

The qubinode_kvmhost_setup_collection enables and starts libvirt services as part of KVM hypervisor setup. Historically, this has been done using the monolithic `libvirtd` daemon, which handles all virtualization functionality in a single process.

### The RHEL 10 Architectural Change

RHEL 10 and CentOS Stream 10 introduce a fundamental architectural change to libvirt, transitioning from a monolithic daemon to modular daemons. This change is documented in the official libvirt documentation at https://libvirt.org/daemons.html#modular-driver-daemons.

#### Monolithic vs Modular Architecture

**Monolithic (RHEL 8/9)**:
- Single `libvirtd` daemon handles all drivers
- All functionality runs in one process
- Single point of failure
- Larger attack surface

**Modular (RHEL 10)**:
- Separate daemons for each driver/function
- Socket-activated for on-demand startup
- Process isolation between components
- Reduced attack surface per component

### Modular Daemon Components

RHEL 10 replaces `libvirtd` with the following socket-activated services:

| Service | Function |
|---------|----------|
| `virtqemud.socket` | QEMU/KVM virtual machine management |
| `virtnetworkd.socket` | Virtual network management |
| `virtstoraged.socket` | Storage pool and volume management |
| `virtnodedevd.socket` | Host device management (passthrough) |
| `virtsecretd.socket` | Secret/credential management |
| `virtlockd.socket` | Lock manager for disk images |
| `virtlogd.socket` | VM console log management |

### Benefits of Modular Architecture

1. **Security**: Each daemon runs with minimal privileges; compromise of one component doesn't affect others
2. **Reliability**: Failure in one daemon doesn't crash entire virtualization stack
3. **Resource Efficiency**: Socket activation means daemons only run when needed
4. **Maintainability**: Individual components can be updated independently
5. **Debugging**: Easier to isolate issues to specific components

### Issue Context

GitHub Issue #126 reports that the Ansible role fails on CentOS Stream 10 when attempting to enable the `libvirtd` service. The root cause is that RHEL 10 no longer provides `libvirtd` as the primary service - the monolithic daemon has been replaced by modular daemons that must be enabled via their socket units.

## Decision

Implement version-aware libvirt service management that:

1. **Detects OS version** using existing `kvmhost_is_rhel10` and `kvmhost_is_centos_stream10` facts
2. **Uses modular daemons** on RHEL 10+ via socket activation
3. **Maintains backward compatibility** with `libvirtd` on RHEL 8/9
4. **Handles `tuned` service** independently (consistent across all versions)

### Implementation Approach

#### Service Selection Logic

```
IF RHEL 10 or CentOS Stream 10:
    Enable modular libvirt sockets:
    - virtqemud.socket
    - virtnetworkd.socket
    - virtstoraged.socket
    - virtnodedevd.socket
    - virtsecretd.socket
    - virtlockd.socket
    - virtlogd.socket
ELSE (RHEL 8/9):
    Enable legacy libvirtd service
ENDIF

ALWAYS:
    Enable tuned service
```

#### Socket Activation Pattern

Socket-activated services use `.socket` units that:
- Listen for incoming connections
- Start the corresponding `.service` on-demand
- Allow immediate availability without running daemons
- Provide automatic restart on daemon failure

## Alternatives Considered

### 1. Force Monolithic Mode on RHEL 10
**Rejected**: RHEL 10 is designed for modular daemons. Forcing monolithic mode (if even possible) would go against Red Hat's supported configuration and could cause issues with future updates.

### 2. Ignore RHEL 10 for Now
**Rejected**: CentOS Stream 10 is already available and users are attempting deployments. Failing silently or with cryptic errors is poor user experience.

### 3. Require Manual Service Configuration
**Rejected**: The purpose of this Ansible collection is to automate KVM host setup. Requiring manual post-playbook steps defeats this purpose.

### 4. Maintain Single Service List
**Rejected**: The service architectures are fundamentally different. A single list cannot represent both `libvirtd` and the seven modular socket units.

## Implementation Details

### File Changes

#### 1. `roles/kvmhost_setup/defaults/main.yml`

Add new variable for modular daemons:

```yaml
# Modular libvirt daemons for RHEL 10+ (socket-activated)
# These replace the monolithic libvirtd on RHEL 10 / CentOS Stream 10
# Reference: https://libvirt.org/daemons.html#modular-driver-daemons
libvirt_modular_services:
  - virtqemud.socket
  - virtnetworkd.socket
  - virtstoraged.socket
  - virtnodedevd.socket
  - virtsecretd.socket
  - virtlockd.socket
  - virtlogd.socket
```

#### 2. `roles/kvmhost_setup/tasks/rhel_version_detection.yml`

Update `kvmhost_services` dictionary to use modular daemons for RHEL 10:

```yaml
kvmhost_services:
  rhel8:
    - libvirtd
    - NetworkManager
    - cockpit.socket
  rhel9:
    - libvirtd
    - NetworkManager
    - cockpit.socket
  rhel10:
    # Modular libvirt daemons (socket-activated)
    - virtqemud.socket
    - virtnetworkd.socket
    - virtstoraged.socket
    - virtnodedevd.socket
    - virtsecretd.socket
    - virtlockd.socket
    - virtlogd.socket
    - NetworkManager
    - cockpit.socket
  centos_stream10:
    # Modular libvirt daemons (socket-activated)
    - virtqemud.socket
    - virtnetworkd.socket
    - virtstoraged.socket
    - virtnodedevd.socket
    - virtsecretd.socket
    - virtlockd.socket
    - virtlogd.socket
    - NetworkManager
    - cockpit.socket
    - podman.socket
```

#### 3. `roles/kvmhost_setup/tasks/libvirt_setup.yml`

Replace unconditional service enablement with version-aware logic:

```yaml
- name: Set libvirt modular daemons fact for RHEL 10+
  ansible.builtin.set_fact:
    libvirt_use_modular_daemons: >-
      {{ (kvmhost_is_centos_stream10 | default(false)) or
         (kvmhost_is_rhel10 | default(false)) or
         (kvmhost_os_major_version | default('9') | int >= 10) }}

- name: Enable modular libvirt socket services (RHEL 10+)
  ansible.builtin.systemd:
    name: "{{ item }}"
    enabled: true
    state: started
  loop: "{{ libvirt_modular_services }}"
  when:
    - libvirt_use_modular_daemons | bool
    - not (ansible_virtualization_type == "container" or cicd_test | bool)

- name: Enable legacy libvirt services (RHEL 8/9)
  ansible.builtin.service:
    name: "{{ item }}"
    enabled: true
    state: started
  loop: "{{ libvirt_services }}"
  when:
    - not (libvirt_use_modular_daemons | default(false) | bool)
    - not (ansible_virtualization_type == "container" or cicd_test | bool)

- name: Enable tuned service (all versions)
  ansible.builtin.service:
    name: tuned
    enabled: true
    state: started
  when: not (ansible_virtualization_type == "container" or cicd_test | bool)
```

## Consequences

### Positive

1. **RHEL 10 Compatibility**: Resolves GitHub Issue #126 - role now works on CentOS Stream 10 and RHEL 10
2. **Security Aligned**: Uses Red Hat's recommended modular architecture for improved isolation
3. **Backward Compatible**: Existing RHEL 8/9 deployments continue to work without changes
4. **Future Proof**: Aligns with libvirt's long-term direction toward modular daemons
5. **Socket Activation Benefits**: Services start on-demand, reducing resource usage when idle
6. **Idempotent**: Conditional logic ensures repeated runs produce consistent results

### Negative

1. **Increased Complexity**: Conditional logic and multiple service lists add complexity
2. **Testing Burden**: Must test service enablement across RHEL 8, 9, and 10
3. **Documentation**: Users may need guidance on the architectural difference
4. **Troubleshooting**: Different service names may confuse users familiar with `libvirtd`

## Validation and Testing

### Test Cases

```bash
# Test on CentOS Stream 10
molecule test --scenario-name centos-stream10
# Expected: Modular socket services are enabled

# Test on RHEL 9 / CentOS Stream 9
molecule test --scenario-name default
# Expected: libvirtd service is enabled (legacy behavior)

# Verify idempotency
molecule converge && molecule converge
# Expected: No changes on second run

# Verify socket activation (on RHEL 10 host)
systemctl status virtqemud.socket
# Expected: active (listening)
```

### Manual Verification

```bash
# On RHEL 10 host after playbook run:
systemctl list-units 'virt*.socket' --state=active
# Expected output:
# virtqemud.socket    loaded active listening
# virtnetworkd.socket loaded active listening
# virtstoraged.socket loaded active listening
# virtnodedevd.socket loaded active listening
# virtsecretd.socket  loaded active listening
# virtlockd.socket    loaded active listening
# virtlogd.socket     loaded active listening

# Verify libvirt connectivity:
virsh list --all
# Expected: Successfully connects to hypervisor
```

## External References

1. **Libvirt Daemons Documentation**
   https://libvirt.org/daemons.html#modular-driver-daemons
   Official documentation on modular daemon architecture

2. **Red Hat RHEL 10 Release Notes**
   Documents the transition to modular libvirt daemons

3. **GitHub Issue #126**
   Original bug report for CentOS Stream 10 libvirtd failure

4. **systemd Socket Activation**
   https://www.freedesktop.org/software/systemd/man/systemd.socket.html
   Reference for socket-activated service pattern

## Related ADRs

- [ADR-0008: RHEL 9 and RHEL 10 Support Strategy](./adr-0008-rhel-9-and-rhel-10-support-strategy.md) - Parent strategy document
- [ADR-0015: Remote Desktop Architecture Decision](./adr-0015-remote-desktop-architecture.md) - Another RHEL 10 architectural change

## Date

2026-01-21

## Tags

rhel-10, centos-stream-10, libvirt, modular-daemons, socket-activation, virtqemud, backward-compatibility, kvm, hypervisor

## Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-01-21 | 1.0 | Claude | Initial ADR for modular libvirt daemon support |
