# ADR-0015: Remote Desktop Architecture Decision (VNC to RDP Migration)

## Status
Accepted - Implementation Pending SELinux Fix

## Context

The qubinode_kvmhost_setup_collection has historically provided remote graphical access to KVM hypervisors using VNC-based technologies (`tigervnc-server`) and X11-compatible RDP (`xrdp`). These packages enabled users to remotely access the hypervisor desktop environment for management and monitoring tasks.

### The RHEL 10 Paradigm Shift

RHEL 10 introduces a fundamental architectural change that renders the existing remote desktop implementation obsolete:

1. **Xorg Display Server Removal**: RHEL 10 deprecates and completely removes the X.Org display server [1]. Xorg is replaced by Wayland as the only supported display protocol [4].

2. **Package Obsolescence**: The `tigervnc-server` and `xrdp` packages are X11-dependent and cannot function without Xorg. These packages are not available in RHEL 10 repositories [2][3].

3. **New Architecture**: Red Hat's official replacement is `gnome-remote-desktop`, a Wayland-native RDP implementation that provides system-level remote access without requiring X11 [6][8].

### Critical Blocker: SELinux Incompatibility

As documented in Red Hat Bugzilla 2271661, the `gnome-remote-desktop` "Remote Login" (headless) feature is incompatible with SELinux in enforcing mode [10]. This creates an unacceptable security risk:

- **KVM Hypervisor Security**: SELinux provides sVirt (Secure Virtualization) for mandatory access control and isolation between virtual machines
- **Security-First Principle**: Disabling SELinux on a KVM hypervisor destroys the primary security boundary between VMs and the host
- **Non-Negotiable Requirement**: An Ansible collection for KVM deployment must never disable SELinux or recommend it as a workaround

### Technical Reproduction of the SELinux Bug

The bug can be reliably reproduced with these steps:
1. Configure `gnome-remote-desktop` per RHEL 10 documentation using `grdctl --system`
2. Attempt RDP connection → **Connection fails**
3. Run `setenforce 0` to set SELinux to permissive mode
4. Attempt RDP connection → **Connection succeeds**

This definitively isolates SELinux as the blocker [10].

## Decision

Implement a **two-phase migration strategy** for remote desktop functionality:

### Phase 1: Immediate Fail-Fast Protection (Current)

**Objective**: Prevent unexpected failures and provide clear user guidance

**Implementation**: 
- Add conditional logic to detect RHEL 10 systems
- Block remote desktop feature when `enable_vnc: true` on RHEL 10
- Provide informative error message explaining:
  - The architectural change (Xorg → Wayland)
  - The security blocker (BZ 2271661)
  - The security-first reasoning (SELinux requirement)
  - The workaround (`enable_vnc: false`)

### Phase 2: Strategic RDP Implementation (Post SELinux Fix)

**Objective**: Provide production-ready RDP support when upstream blocker is resolved

**Implementation**: 
- Refactor variables from `enable_vnc` to `enable_remote_desktop`
- Create platform-specific task branches:
  - RHEL 8/9: Use existing VNC/X11 stack
  - RHEL 10: Use new RDP/Wayland stack
- Implement SELinux policy version checking
- Auto-enable RDP when policy fix is detected
- Maintain fail-fast protection if policy is not fixed

## Alternatives Considered

### 1. Disable SELinux Automatically
**Rejected**: Catastrophic security failure for KVM hypervisors. Violates secure-by-default principle.

### 2. Wait for RHEL 10.1/10.2
**Rejected**: Passive approach. Users attempting RHEL 10 deployments would encounter cryptic errors with no guidance.

### 3. Document Manual Workaround
**Rejected**: Insufficient. Ansible collections should be self-documenting through clear error messages, not external documentation.

### 4. Remove Remote Desktop Feature Entirely
**Rejected**: Feature is valuable for many users. Better to conditionally support where possible and clearly block where not.

### 5. Use Alternative RDP Server (x11rdp, xorgxrdp)
**Rejected**: These are X11-dependent packages that also won't work on RHEL 10. Does not solve the root problem.

## Implementation Details

### Phase 1: Fail-Fast Implementation

Located in `roles/kvmhost_setup/tasks/` (or equivalent):

```yaml
# Existing VNC installation (updated with version check)
- name: Install VNC and RDP packages (RHEL 8/9 only)
  ansible.builtin.dnf:
    name:
      - tigervnc-server
      - xrdp
    state: present
  when:
    - enable_vnc | default(true) | bool
    - kvmhost_os_major_version|int < 10

# New fail-fast task for RHEL 10
- name: Fail fast on RHEL 10 (Remote Desktop is not yet supported)
  ansible.builtin.fail:
    msg: >-
      FATAL: The 'enable_vnc: true' variable is not supported on RHEL 10 / CentOS Stream 10.

      This platform deprecates VNC/X11. The new RDP-based architecture ('gnome-remote-desktop')
      is currently blocked by an SELinux bug (Red Hat BZ 2271661) that prevents it
      from running in 'enforcing' mode.

      This collection prioritizes hypervisor security and WILL NOT disable SELinux.
      Remote Desktop support for RHEL 10 will be enabled when the SELinux policy is fixed upstream.

      WORKAROUND: Set 'enable_vnc: false' in your inventory for RHEL 10 hosts.
  when:
    - enable_vnc | default(true) | bool
    - kvmhost_os_major_version|int >= 10
```

### Phase 2: Full RDP Implementation

#### 2.1 Variable Refactoring

**File**: `roles/kvmhost_setup/defaults/main.yml`

```yaml
# Deprecated - maintained for backward compatibility
enable_vnc: true

# New variable - platform-agnostic
enable_remote_desktop: "{{ enable_vnc | default(true) }}"

# RHEL 10 RDP credentials (must be vaulted in production)
rhel10_rdp_user: "rdp-admin"
rhel10_rdp_password: "{{ vault_rdp_password | default('ChangeMe123!') }}"
```

#### 2.2 Task Structure

**File**: `roles/kvmhost_setup/tasks/main.yml`

```yaml
- name: Include remote desktop configuration
  ansible.builtin.include_tasks: configure_remote_desktop.yml
  when: enable_remote_desktop | default(true) | bool
```

**File**: `roles/kvmhost_setup/tasks/configure_remote_desktop.yml`

```yaml
- name: Include RHEL 8/9 (VNC/X11) tasks
  ansible.builtin.include_tasks: remote_desktop_el8_el9.yml
  when: kvmhost_os_major_version|int < 10

- name: Include RHEL 10 (RDP/Wayland) tasks
  ansible.builtin.include_tasks: remote_desktop_el10.yml
  when: kvmhost_os_major_version|int >= 10
```

#### 2.3 RHEL 8/9 Implementation

**File**: `roles/kvmhost_setup/tasks/remote_desktop_el8_el9.yml`

```yaml
---
# Legacy VNC/X11 implementation for RHEL 8 and 9
- name: Install VNC and RDP packages (RHEL 8/9)
  ansible.builtin.dnf:
    name:
      - tigervnc-server
      - xrdp
    state: present

- name: Configure VNC service
  # ... existing VNC configuration tasks ...
```

#### 2.4 RHEL 10 RDP Implementation with SELinux Checking

**File**: `roles/kvmhost_setup/tasks/remote_desktop_el10.yml`

```yaml
---
# RHEL 10 RDP/Wayland implementation with security-first SELinux checking

- name: Check SELinux policy package version
  ansible.builtin.dnf:
    list: selinux-policy
  register: selinux_policy_pkg

- name: Set RHEL 10 SELinux fix status
  ansible.builtin.set_fact:
    # NOTE: The version '40.20.0-1.el10' is a placeholder.
    # This must be updated when the exact selinux-policy version
    # containing the fix for BZ 2271661 is released by Red Hat.
    el10_rdp_selinux_fix_applied: >-
      {{ selinux_policy_pkg.results | 
         selectattr('version', 'ge', '40.20.0-1.el10') | 
         list | length > 0 }}

- name: Check if SELinux is in enforcing mode
  ansible.builtin.set_fact:
    selinux_is_enforcing: >-
      {{ ansible_selinux is defined and 
         ansible_selinux.status == 'enabled' and 
         ansible_selinux.mode == 'enforcing' }}

- name: Fail if RDP is requested but SELinux fix is not present
  ansible.builtin.fail:
    msg: >-
      Remote Desktop (gnome-remote-desktop) cannot be safely enabled on RHEL 10.
      This is due to Red Hat Bugzilla 2271661, which causes SELinux conflicts
      in 'enforcing' mode when using the system-level 'Remote Login' feature.

      This collection will not disable SELinux as a workaround due to the
      security implications for KVM hypervisor deployments (sVirt isolation).

      RESOLUTION:
      Run 'dnf update selinux-policy' to get the latest security policy
      (requires selinux-policy >= 40.20.0-1.el10 with BZ 2271661 fix).
      
      After the update, re-run this playbook to enable remote desktop.
      
      WORKAROUND:
      Set 'enable_remote_desktop: false' to skip remote desktop setup.
  when:
    - not el10_rdp_selinux_fix_applied
    - selinux_is_enforcing

- name: Include gnome-remote-desktop setup
  ansible.builtin.include_tasks: setup_gnome_remote_desktop.yml
  when:
    - el10_rdp_selinux_fix_applied or not selinux_is_enforcing
```

#### 2.5 Five-Step gnome-remote-desktop Configuration

**File**: `roles/kvmhost_setup/tasks/setup_gnome_remote_desktop.yml`

```yaml
---
# Complete automation of RHEL 10 RDP using gnome-remote-desktop
# Based on Red Hat RHEL 10 documentation [6][8]

# ============================================================
# STEP 1: Install Required Packages
# ============================================================
- name: Install RHEL 10 RDP packages
  ansible.builtin.dnf:
    name:
      - "@Server with GUI"
      - gnome-remote-desktop
      - freerdp  # Provides winpr-makecert utility [21]
    state: present

# ============================================================
# STEP 2: Generate RDP TLS Certificate
# ============================================================
- name: Create directory for RDP certificate
  ansible.builtin.file:
    path: /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop
    state: directory
    owner: gnome-remote-desktop
    group: gnome-remote-desktop
    mode: '0700'

- name: Generate self-signed RDP TLS certificate
  ansible.builtin.command:
    cmd: >-
      winpr-makecert -silent -rdp
      -path /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop
      tls
    creates: /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/tls.crt
  become: true
  become_user: gnome-remote-desktop

# ============================================================
# STEP 3: Configure gnome-remote-desktop via grdctl
# ============================================================
- name: Set RDP TLS key path
  ansible.builtin.command: 
    cmd: grdctl --system rdp set-tls-key /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/tls.key
  changed_when: true  # grdctl does not provide idempotent feedback

- name: Set RDP TLS certificate path
  ansible.builtin.command:
    cmd: grdctl --system rdp set-tls-cert /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/tls.crt
  changed_when: true

- name: Set RDP system credentials (non-interactive)
  ansible.builtin.command:
    cmd: grdctl --system rdp set-credentials {{ rhel10_rdp_user }} {{ rhel10_rdp_password }}
  changed_when: true
  no_log: true  # Protect credentials from console/log output

- name: Enable RDP 'Remote Login' system mode
  ansible.builtin.command:
    cmd: grdctl --system rdp enable
  changed_when: true

# ============================================================
# STEP 4: Enable and Start System Services
# ============================================================
- name: Set system default to graphical target
  ansible.builtin.systemd:
    name: graphical.target
    enabled: true

- name: Enable and start GDM and gnome-remote-desktop services
  ansible.builtin.service:
    name: "{{ item }}"
    state: started
    enabled: true
  loop:
    - gdm.service
    - gnome-remote-desktop.service

# ============================================================
# STEP 5: Configure Firewall
# ============================================================
- name: Allow RDP service in firewalld
  ansible.posix.firewalld:
    service: rdp  # Default port 3389 [18]
    permanent: true
    state: enabled
    immediate: true
```

## Consequences

### Positive

1. **Security-First Design**: Refuses to compromise SELinux security for convenience
2. **Clear Communication**: Users immediately understand why remote desktop is blocked on RHEL 10
3. **Future-Proof**: Automatically unlocks feature when upstream fix is applied
4. **Backward Compatible**: Existing RHEL 8/9 deployments continue to work without changes
5. **Idempotent**: SELinux policy checking enables "run-until-fixed" automation
6. **Auditable**: Clear dependency on specific BZ and policy version for compliance tracking
7. **Platform-Appropriate**: Uses VNC on RHEL 8/9, RDP on RHEL 10 as intended by Red Hat

### Negative

1. **Delayed Feature Availability**: Remote desktop unavailable on RHEL 10 until SELinux fix
2. **Increased Complexity**: Multi-platform implementation with conditional logic
3. **Maintenance Burden**: Must track and update selinux-policy version threshold when fix ships
4. **Testing Overhead**: Requires testing across RHEL 8, 9, and 10 with different stacks
5. **User Education**: Users must understand why feature is blocked (though error message addresses this)
6. **Credential Management**: New RDP credentials introduce additional vault management requirements

## Validation and Testing

### Phase 1 Validation

```bash
# Test on CentOS Stream 10 with enable_vnc: true
ansible-playbook -i inventory/centos-stream-10 site.yml

# Expected: Playbook fails with clear error message citing BZ 2271661
# Expected: Error message includes workaround (enable_vnc: false)
```

### Phase 2 Validation (Post-Implementation)

```bash
# Test RHEL 8/9 (VNC path)
ansible-playbook -i inventory/rhel9 site.yml
# Expected: VNC installation succeeds, services start

# Test RHEL 10 without SELinux fix
ansible-playbook -i inventory/rhel10 site.yml
# Expected: Playbook fails with SELinux policy update instructions

# Test RHEL 10 with SELinux fix (future)
# Update selinux-policy to fixed version
dnf update selinux-policy
ansible-playbook -i inventory/rhel10 site.yml
# Expected: RDP setup completes, services start, firewall configured

# Test RDP connectivity
freerdp /v:rhel10-host.example.com /u:rdp-admin /p:password
# Expected: Successful RDP connection to graphical desktop
```

## External References

1. **Red Hat Customer Portal - Major Changes in RHEL 10**  
   Xorg display server deprecation and removal  
   URL: Red Hat documentation on RHEL 10 architectural changes

2. **CentOS Stream 10 AppStream Repository**  
   `tigervnc-server` package unavailability analysis  
   Verified via: `dnf search tigervnc-server` on CentOS Stream 10

3. **CentOS Stream 10 AppStream Repository**  
   `xrdp` package unavailability analysis  
   Verified via: `dnf search xrdp` on CentOS Stream 10

4. **Red Hat Documentation - RHEL 10 Desktop Environment**  
   Wayland as the only supported display server  
   Confirms no X11/Xorg support

6. **Red Hat RHEL 10 Documentation - Enabling Remote Access via RDP**  
   Official documentation for `gnome-remote-desktop` setup  
   Source of implementation steps 1-5

8. **Red Hat RHEL 10 Documentation - grdctl System Configuration**  
   Command-line utility for system-level RDP configuration  
   Documents `grdctl --system` commands

10. **Red Hat Bugzilla 2271661**  
    Title: "gnome-remote-desktop system login feature is disallowed in enforcing mode"  
    Status: OPEN (as of November 2025)  
    Severity: HIGH  
    Impact: Blocks production KVM deployments on RHEL 10  
    Reproducer: Documented in Context section above  
    URL: https://bugzilla.redhat.com/show_bug.cgi?id=2271661

18. **RHEL 10 Documentation - Firewall Configuration**  
    RDP service uses default port 3389  
    Required firewalld configuration for remote access

21. **freerdp Package Analysis**  
    RPM package contents: `rpm -ql freerdp | grep winpr-makecert`  
    Confirms winpr-makecert utility is provided by freerdp package

22. **grdctl Non-Interactive Credential Passing**  
    Community testing and automation research  
    Enables non-interactive `set-credentials` for Ansible automation

## Related ADRs

- [ADR-0008: RHEL 9 and RHEL 10 Support Strategy](./adr-0008-rhel-9-and-rhel-10-support-strategy.md) - Parent strategy document
- [ADR-0004: Idempotent Task Design Pattern](./adr-0004-idempotent-task-design-pattern.md) - Design patterns applied in Phase 2
- [ADR-0014: Ansible Galaxy Automated Release Strategy](../adr/ADR-0014-ANSIBLE-GALAXY-AUTOMATED-RELEASE-STRATEGY.md) - Related to release planning

## Date

2025-11-14 (Initial)

## Tags

rhel-10, remote-desktop, vnc, rdp, xorg, wayland, selinux, security, gnome-remote-desktop, kvm, hypervisor, fail-fast, migration, architecture

## Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2025-11-14 | 1.0 | Cascade AI | Initial ADR based on FINDINGS.md analysis |
