## CI/CD Pipeline Fixes

### 2023-10-05 - Pruning Phase Fix
**Issue:** Pipeline was exiting during pruning phase despite successful tests
**Solution:** Modified molecule test command to use `--no-destroy` flag
**Reasoning:**
- The molecule.yml configuration already includes cleanup and destroy steps
- Running `molecule destroy` after `molecule test` was redundant
- Using `--no-destroy` allows scenario's built-in cleanup process
**Impact:**
- Prevents pipeline from exiting during pruning phase
- Maintains proper test environment cleanup
- Reduces redundant operations

### 2023-10-05 - Dependency Management Fixes

**Collection Format Fix**
**Issue:** Pipeline failing due to invalid collection requirements format
**Solution:** Updated requirements.yml with proper FQCN format
**Reasoning:**
- Collections must follow `<namespace>.<collection>` format
- Explicit 'name' field required for each collection
- Roles section needed proper field ordering
**Impact:**
- Resolves collection installation errors
- Ensures proper dependency resolution
- Maintains Ansible best practices

**Collection Installation Fix**
**Issue:** Pipeline failing due to missing community.general.parted module
**Solution:** Added collection installation step in CI/CD workflow
**Reasoning:**
- Required collections were listed but not being installed
- Explicit collection installation ensures all dependencies are available
**Impact:**
- Resolves module resolution errors
- Ensures consistent test environment setup
- Maintains dependency management best practices

**Approved by:** Architect (A)
**Implemented by:** Developer 1 (D1)

### 2024-01-15 - Collection Version Constraints

**Issue:** Pipeline failing with API error when getting available versions of community.general collection
**Solution:** Added version constraints (>=6.0.0,<7.0.0) for community.general in requirements.yml
**Reasoning:**
- Prevents API version lookup errors
- Ensures compatibility with tested Ansible versions
- Provides stable collection dependencies
**Impact:**
- Resolves collection installation errors
- Maintains consistent dependency resolution
- Improves pipeline reliability

**Approved by:** Architect (A)
**Implemented by:** Developer 2 (D2)
