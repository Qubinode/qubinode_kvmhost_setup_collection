### CI/CD Pipeline Fix - 2024-06-20

**Issue:**  
The Ansible test pipeline was failing due to invalid version specifiers 'devel' and 'milestone' in the GitHub Actions workflow.

**Solution:**  
Removed invalid version specifiers from the matrix strategy in .github/workflows/ansible-test.yml. Now only testing against stable Ansible versions:
- stable-2.12
- stable-2.13  
- stable-2.14

**Impact:**  
- Ensures pipeline runs successfully with valid version requirements
- Maintains testing coverage for supported stable versions
- Prevents future pipeline failures from invalid version specifiers
