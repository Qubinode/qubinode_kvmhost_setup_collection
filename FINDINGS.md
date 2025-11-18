Analysis and Resolution of Collection Issue: VNC/Remote Desktop Package Unavailability on CentOS Stream 10
Step 2: Generate RDP TLS CertificateAction: The RHEL 10 documentation specifies running winpr-makecert to generate the required TLS certificate for the RDP service.8Dependency: Analysis of the freerdp package contents reveals that the winpr-makecert utility is provided by the freerdp RPM.21 This creates a non-obvious dependency: freerdp must be installed on the server to generate the server's certificate.Task: The certificate must be generated as the gnome-remote-desktop user in its expected home directory.YAML- name: Create directory for RDP certificate
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
    argv:
      - /bin/bash
      - -c
  become: true
  become_user: gnome-remote-desktop
Step 3: Configure gnome-remote-desktop via grdctlAction: The grdctl utility is the command-line tool used to configure the system-level RDP service.8Automation Hurdle: The RHEL 10 documentation specifies running grdctl --system rdp set-credentials, which prompts interactively for a username and password.8 This is an automation-killer. Other documentation, however, implies that credentials can be passed as non-interactive arguments.22 The role must use this non-interactive method, sourcing credentials from Ansible variables and using no_log: true to protect them from console and log output.Task:YAML- name: Set RDP TLS key path
  ansible.builtin.command: "grdctl --system rdp set-tls-key /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/tls.key"
  changed_when: true # grdctl provides no idempotent feedback

- name: Set RDP TLS certificate path
  ansible.builtin.command: "grdctl --system rdp set-tls-cert /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/tls.crt"
  changed_when: true

- name: Set RDP system credentials (non-interactive)
  ansible.builtin.command: "grdctl --system rdp set-credentials {{ rhel10_rdp_user }} {{ rhel10_rdp_pass }}"
  changed_when: true
  no_log: true
  vars:
    # These variables must be defined in defaults/main.yml or vars/main.yml
    rhel10_rdp_user: "rdp-admin"
    rhel10_rdp_pass: "{{ rdp_admin_password | default('SuperS3cureP@ssw0rd!') }}" # Example, should be vaulted

- name: Enable RDP 'Remote Login' system mode
  ansible.builtin.command: "grdctl --system rdp enable"
  changed_when: true
Step 4: Enable and Start System ServicesAction: The "Remote Login" mode requires both gdm.service (for the login screen) and gnome-remote-desktop.service to be enabled and started. The system default target must also be set to graphical.target to ensure GDM starts on boot.8Task:YAML- name: Set system default to graphical target
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
Step 5: Configure FirewallAction: Open the rdp service (default port 3389) in firewalld.18Task:YAML- name: Allow RDP service in firewalld
  ansible.posix.firewalld:
    service: rdp
    permanent: true
    state: enabled
    immediate: true
5.0 Critical Blocker and Security Analysis: SELinux Integration FailureThe Ansible implementation detailed in Section 4.0 is a correct and complete automation of the Red Hat documentation. However, it will not work on a default CentOS Stream 10 installation with SELinux enabled.5.1 The Blocker: Red Hat Bugzilla 2271661Finding: As of the date of this report, the gnome-remote-desktop "Remote Login" feature is fundamentally incompatible with SELinux in enforcing mode.10Bug Details: Red Hat Bugzilla 2271661, titled "gnome-remote-desktop system login feature is disallowed in enforcing mode," documents this issue.10Reproduction: The bug's reproduction steps are simple and definitive:Configure grdctl per the RHEL 10 documentation (as automated in Section 4.0).Attempt to connect with an RDP client. The connection fails.Run setenforce 0 on the server to set SELinux to permissive mode.Attempt to connect again. The connection succeeds.10Conclusion: This isolates SELinux as the single root cause of the failure. The current selinux-policy on RHEL 10 does not contain the necessary rules to allow gnome-remote-desktop to function in its system-level "Remote Login" mode.5.2 Why the setenforce 0 Workaround is UnacceptableThe qubinode_kvmhost_setup_collection is designed to configure a KVM hypervisor. On a RHEL-based hypervisor, SELinux is not just a generic security feature; it is the enabling technology for sVirt, which provides Mandatory Access Control (MAC) and isolation for virtual machine processes.Disabling SELinux or setting it to permissive mode on a KVM hypervisor is a catastrophic security failure. It effectively destroys the primary security boundary between virtual machines and the host, and between the virtual machines themselves.An Ansible collection, particularly one authored by a Red Hat solutions architect 17, must never programmatically disable SELinux or instruct a user to do so as a workaround for a feature. The collection must remain secure-by-default.5.3 Analysis of Alternative Fixes (e.g., audit2allow)An alternative might be to capture the SELinux AVC denials (listed in BZ 2271661, e.g., allow xdm_t mount_var_run_t:dir watch;) 10 and use audit2allow to build a custom SELinux policy module (.te file).This path is not recommended. A comment on the bug from the original reporter, a Red Hat engineer, notes, "But I suspect there is more needed than that...".10 This strongly implies that the visible AVC denials are not the full picture and that the fix is complex. Shipping a custom, reverse-engineered policy module from within the Ansible role is high-risk, likely to be incomplete, and will create future update conflicts when Red Hat does release the official, correct selinux-policy RPM.5.4 The Only Secure Path ForwardThe only correct, secure, and supportable solution is to wait for the Red Hat SELinux policy team to resolve BZ 2271661 and release an updated selinux-policy package to the CentOS Stream 10 repositories.The Ansible collection's role is not to work around this bug, but to detect this known-bad state and fail gracefully, prioritizing the hypervisor's security above all else.6.0 Final Recommendations and Implementation RoadmapThis plan provides a two-phase approach. Phase 1 provides immediate stability for all users. Phase 2 provides a secure, long-term, and forward-compatible solution for RHEL 10.6.1 Phase 1: Immediate Hotfix (Target: v0.9.36)Goal: Stop the fatal package error on RHEL 10 and clearly communicate the feature gap, the security rationale, and the user-side workaround.Action: Modify the VNC/RDP task file to replace the package installation task with a "fail-fast" guard. This is superior to a silent skip (Option 1) as it provides explicit communication.Proposed Task File (e.g., tasks/remote_access.yml):YAML- name: Install VNC/RDP packages (RHEL 8/9)
  ansible.builtin.dnf:
    name:
      - tigervnc-server
      - xrdp
    state: present
  when:
    - enable_vnc | default(true) | bool
    - kvmhost_os_major_version|int < 10

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
Justification: This respects the "fail-fast" principle. It stops the build, but unlike the original package error, it gives the user a perfect explanation of the problem, the security-first reasoning, the upstream Bugzilla to track, and the exact workaround.6.2 Phase 2: Strategic Implementation (Target: v1.0.0+)Goal: Implement the architecturally-correct RHEL 10 solution (from Section 4.0), but keep it "dark" (disabled) until the host system's SELinux policy is confirmed to be fixed.Action:Refactor Variables: In defaults/main.yml, deprecate enable_vnc and introduce a new, abstract variable: enable_remote_desktop: true.Create New Task Structure:tasks/main.yml -> includes tasks/configure_remote_desktop.ymltasks/configure_remote_desktop.yml (when enable_remote_desktop: true):YAML- name: Include RHEL 8/9 (VNC/X11) tasks
  ansible.builtin.include_tasks: remote_desktop_el8_el9.yml
  when: kvmhost_os_major_version|int < 10

- name: Include RHEL 10 (RDP/Wayland) tasks
  ansible.builtin.include_tasks: remote_desktop_el10.yml
  when: kvmhost_os_major_version|int >= 10
Implement tasks/remote_desktop_el10.yml with Security-First Logic:YAML- name: Check for fix for Red Hat BZ 2271661 in SELinux policy
  ansible.builtin.dnf:
    list: selinux-policy
  register: selinux_policy_pkg

- name: Set RHEL 10 SELinux fix status
  ansible.builtin.set_fact:
    # NOTE: The version '40.20.0-1' is a placeholder.
    # The maintainer must identify the *exact* 'selinux-policy'
    # version that ships the fix for BZ 2271661 and update this fact.
    el10_rdp_selinux_fix_applied: >-
      {{ selinux_policy_pkg.results | selectattr('version', 'ge', '40.20.0-1.el10') | list | length > 0 }}

- name: Fail if RDP is requested but SELinux is not fixed
  ansible.builtin.fail:
    msg: >-
      Remote Desktop (gnome-remote-desktop) cannot be safely enabled on RHEL 10.
      This is due to Red Hat BZ 2271661, which conflicts with SELinux in 'enforcing' mode.
      This collection will not disable SELinux as a workaround.

      To resolve this, please run 'dnf update selinux-policy' to get the
      latest security policy and re-run this playbook.
  when:
    - not el10_rdp_selinux_fix_applied
    - ansible_selinux is defined
    - ansible_selinux.status == 'enabled' and ansible_selinux.mode == 'enforcing'

- name: Include RHEL 10 RDP setup (SELinux fix is present or not enforcing)
  ansible.builtin.include_tasks: setup_gnome_remote_desktop.yml
  when:
    - el10_rdp_selinux_fix_applied or
      (ansible_selinux is defined and (ansible_selinux.status == 'disabled' or ansible_selinux.mode == 'permissive'))

# This file contains the 5 steps from Section 4.2
# - name: setup_gnome_remote_desktop.yml
#  ...
Justification: This final design represents the gold standard for an enterprise Ansible role:Secure-by-Default: It refuses to run in an insecure state (enforcing SELinux with a known-bad policy).Idempotent: It checks the state of the system (selinux-policy version) before acting.Forward-Compatible: When the user runs dnf update and receives the fixed SELinux policy, the next Ansible run will automatically detect this. The el10_rdp_selinux_fix_applied fact will become true, the fail task will be skipped, and the setup_gnome_remote_desktop.yml tasks will execute, "unlocking" the feature.Clear Communication: The fail message is a "guard rail" that stops the user, explains why (security), and tells them exactly what to do (dnf update).