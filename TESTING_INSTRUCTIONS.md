# Testing Instructions for Version 0.10.0

**Target Platform:** CentOS Stream 10 / RHEL 10  
**Feature:** Phase 2 Remote Desktop (gnome-remote-desktop)

---

## Prerequisites

### On CentOS Stream 10 / RHEL 10 Test Machine:

1. **Clean Installation Recommended**
2. **System Requirements:**
   - CentOS Stream 10 or RHEL 10
   - Minimum 4GB RAM
   - Network connectivity
   - Root or sudo access

3. **Install Ansible:**
```bash
sudo dnf install -y ansible-core
```

4. **Install Collection:**
```bash
ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection:0.10.0 --force
```

---

## Test Scenarios

### Test 1: Default Behavior (Should Fail Securely)

**Purpose:** Verify security-first failure mode

```bash
# Create test playbook
cat > test-rdp-default.yml << 'EOF'
---
- name: Test RDP Default Behavior
  hosts: localhost
  connection: local
  become: true
  
  vars:
    enable_remote_desktop: true
    enable_cockpit: true
  
  roles:
    - role: tosin2013.qubinode_kvmhost_setup_collection.kvmhost_setup
      tags: remote_desktop
EOF

# Run test
ansible-playbook test-rdp-default.yml --tags remote_desktop
```

**Expected Result:**
```
🔒 SECURITY VALIDATION FAILED

Remote Desktop (gnome-remote-desktop) cannot be safely enabled
on RHEL 10 at this time.

Current System State:
- SELinux Mode: enforcing
- BZ 2271661 Fix: NOT DETECTED

⏭️  WORKAROUNDS:
Option 1: enable_remote_desktop: false
Option 2: force_gnome_remote_desktop_el10: true (DEV/TEST ONLY)
```

**✅ Pass Criteria:** Playbook fails with clear security error message

---

### Test 2: Force Flag Override (Should Install)

**Purpose:** Verify force flag allows installation with warnings

```bash
# Run with force flag
ansible-playbook test-rdp-default.yml --tags remote_desktop \
  -e "force_gnome_remote_desktop_el10=true"
```

**Expected Result:**
```
⚠️  SECURITY OVERRIDE ACTIVE

You have chosen to bypass SELinux policy validation...

⚠️  EXPECTED BEHAVIOR:
- Installation will proceed
- Services will start
- RDP connections may FAIL due to SELinux denials

✅ Step 1/5: Package Installation Complete
✅ Step 2/5: TLS Certificate Generation Complete
✅ Step 3/5: grdctl Configuration Complete
✅ Step 4/5: System Services Enabled
✅ Step 5/5: Firewall Configuration Complete

✅ RHEL 10 Remote Desktop Setup Complete
```

**✅ Pass Criteria:**
- Warning displayed about security override
- All 5 steps complete successfully
- No fatal errors

---

### Test 3: Verify Installation

**Purpose:** Check that all components are installed and running

```bash
# Check packages
rpm -q gnome-remote-desktop freerdp

# Check services
systemctl status gdm.service gnome-remote-desktop.service

# Check certificates
ls -la /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/

# Check firewall
firewall-cmd --list-services | grep rdp

# Check grdctl status
grdctl --system rdp status
```

**✅ Pass Criteria:**
- Packages installed
- Services running
- Certificates present
- Firewall configured
- grdctl shows RDP enabled

---

### Test 4: Test RDP Connection

**Purpose:** Verify RDP functionality (may fail due to SELinux)

#### Option A: From Windows Client
```
1. Open Remote Desktop Connection
2. Computer: <centos10-ip>:3389
3. Username: test-rdp (or configured user)
4. Password: TestPass123! (or configured password)
5. Click Connect
```

#### Option B: From Linux Client
```bash
# Install freerdp client
sudo dnf install freerdp

# Test connection
xfreerdp /v:<centos10-ip>:3389 /u:test-rdp /p:TestPass123! /cert:ignore
```

**Expected Results:**

**If SELinux Fix Present:** ✅ Connection successful  
**If SELinux Fix NOT Present:** ❌ Connection may fail with errors

**Check SELinux denials if connection fails:**
```bash
sudo ausearch -m avc -ts recent | grep gnome-remote-desktop
```

**Workaround for testing (NOT for production):**
```bash
# Temporarily set SELinux to permissive
sudo setenforce 0

# Retry connection
xfreerdp /v:localhost:3389 /u:test-rdp /p:TestPass123! /cert:ignore

# If successful, SELinux is the blocker
# Return to enforcing
sudo setenforce 1
```

**✅ Pass Criteria:**
- Connection attempt reaches RDP server
- If fails, SELinux denials are logged (confirms BZ 2271661)

---

### Test 5: Phase 2 Comprehensive Test

**Purpose:** Run full test suite

```bash
# Clone or copy test playbook
ansible-galaxy collection install tosin2013.qubinode_kvmhost_setup_collection:0.10.0

# Find collection path
COLLECTION_PATH=$(ansible-galaxy collection list | grep qubinode_kvmhost_setup_collection | awk '{print $2}')

# Run Phase 2 test
cd ~/.ansible/collections/ansible_collections/tosin2013/qubinode_kvmhost_setup_collection/
ansible-playbook tests/test-phase2-remote-desktop.yml
```

**✅ Pass Criteria:**
- OS detection: ✅ CentOS Stream 10 / RHEL 10
- SELinux check: ✅ Detects policy version
- Test summary shows RHEL 10 path selected

---

## Test Report Template

Please provide this information after testing:

```yaml
Test Report:
  Date: YYYY-MM-DD
  Tester: Your Name
  Collection Version: 0.10.0
  
  System Information:
    OS: CentOS Stream 10 / RHEL 10.0
    Kernel: [uname -r output]
    SELinux Mode: [getenforce output]
    SELinux Policy: [rpm -q selinux-policy output]
  
  Test Results:
    Test 1 (Default Behavior): PASS/FAIL
      - Notes:
    
    Test 2 (Force Flag): PASS/FAIL
      - Installation: PASS/FAIL
      - Services Running: PASS/FAIL
      - Notes:
    
    Test 3 (Verify Installation): PASS/FAIL
      - Packages: PASS/FAIL
      - Services: PASS/FAIL
      - Certificates: PASS/FAIL
      - Firewall: PASS/FAIL
      - Notes:
    
    Test 4 (RDP Connection): PASS/FAIL
      - Connection Result: SUCCESS/FAILED
      - SELinux Denials: YES/NO
      - Notes:
    
    Test 5 (Comprehensive Test): PASS/FAIL
      - Notes:
  
  Issues Found:
    - [List any issues]
  
  Suggestions:
    - [List any suggestions]
  
  Overall: PASS/FAIL
```

---

## Troubleshooting

### Issue: "Failed to download metadata for repo"
```bash
# Clean DNF cache
sudo dnf clean all
sudo dnf makecache
```

### Issue: "Module not found" or import errors
```bash
# Install required Python modules
sudo dnf install -y python3-libvirt python3-lxml
```

### Issue: Services won't start
```bash
# Check logs
sudo journalctl -xeu gdm.service
sudo journalctl -xeu gnome-remote-desktop.service

# Check SELinux denials
sudo ausearch -m avc -ts recent
```

### Issue: RDP connection fails
```bash
# Verify services
systemctl status gnome-remote-desktop.service

# Check port
ss -tlnp | grep 3389

# Test locally first
xfreerdp /v:localhost:3389 /u:test-rdp /cert:ignore
```

---

## Success Criteria Summary

✅ **Minimum Requirements:**
1. Test 1 fails with clear security error (correct behavior)
2. Test 2 completes all 5 steps without fatal errors
3. Test 3 shows all components installed
4. Test 5 shows correct OS detection and routing

✅ **Bonus (if SELinux fix available):**
5. Test 4 RDP connection successful

---

## Reporting Results

Please report results via:
- GitHub Issue: https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues
- Include: Full test report, system info, logs if failed

---

**Thank you for testing!** 🙏
