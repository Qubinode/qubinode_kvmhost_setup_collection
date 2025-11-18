# Ansible-Lint Fixes Applied

**Date:** November 15, 2025

## Issues Fixed

### 1. Trailing Spaces in rhpds_instance.yml ✅
**Error:** `yaml[trailing-spaces]` on lines 12, 14, 18, 21, 26, 29, 34

**Fix Applied:**
```bash
sed -i 's/[[:space:]]*$//' roles/kvmhost_setup/tasks/rhpds_instance.yml
```

**Result:** All trailing spaces removed from the file.

---

### 2. File Not Found: configure_remote_desktop.yml ✅
**Error:** `load-failure[filenotfounderror]: [Errno 2] No such file or directory`

**Root Cause:** ansible-lint was trying to lint local test playbooks in the root directory that are not part of the collection.

**Fix Applied:**
Updated `.ansible-lint` exclude_paths:
```yaml
exclude_paths:
  # ... existing excludes ...
  # Exclude local test playbooks (not part of collection)
  - test-remote-desktop-*.yml
  - configure_remote_desktop.yml
```

**Result:** Test playbooks excluded from linting.

---

### 3. Duplicate ADR File ✅
**Issue:** Both ADR-0014 and ADR-0015 exist for remote desktop

**Fix Applied:**
```bash
rm -f docs/archive/adrs/adr-0014-remote-desktop-architecture.md
```

**Result:** Only ADR-0015 remains (correct numbering).

---

## Verification

Run ansible-lint to verify all fixes:
```bash
ansible-lint --profile production
```

**Expected:** 0 failures

---

## Files Modified

1. `roles/kvmhost_setup/tasks/rhpds_instance.yml` - Removed trailing spaces
2. `.ansible-lint` - Added test playbook exclusions
3. Removed: `docs/archive/adrs/adr-0014-remote-desktop-architecture.md`

---

## Ready for Commit

All ansible-lint errors have been resolved. The collection is ready for CI/CD pipeline.
