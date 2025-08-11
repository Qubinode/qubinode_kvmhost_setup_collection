# Fix for Stuck Molecule Containers in CI/CD Pipeline

## Problem Summary
The CI/CD pipeline was experiencing issues where molecule containers would start but remain running for extended periods (30+ minutes) after test failures, specifically:

1. **Containers running but not accessible**: Podman containers were created and running, but Ansible couldn't connect to them
2. **No cleanup on failure/timeout**: When tests failed or timed out, containers remained running indefinitely
3. **Inventory mismatch**: Molecule was trying to use external inventory instead of container hosts

## Root Causes Identified

### 1. Missing Connection Configuration
**Issue**: Container platforms didn't specify `ansible_connection: podman`
**Impact**: Ansible couldn't connect to containers even though they were running
**Fix**: Added `ansible_connection: podman` to all platform definitions

### 2. Inventory Configuration Problem
**Issue**: `inventory.links.hosts` pointed to `../../inventories/test/hosts` which only contained localhost
**Impact**: Tests ran on localhost instead of containers
**Fix**: Removed external inventory configuration to let molecule generate its own

### 3. Missing Timeout and Cleanup Handling
**Issue**: No cleanup mechanism when tests failed or timed out
**Impact**: Containers would run indefinitely consuming resources
**Fix**: Added comprehensive cleanup mechanisms

### 4. Host Pattern Issues
**Issue**: Playbooks used `hosts: all` which included localhost
**Impact**: Confusion between container hosts and localhost
**Fix**: Changed to `hosts: all:!localhost` to exclude localhost

## Changes Made

### 1. Molecule Configuration (`molecule/default/molecule.yml`)
```yaml
# Added to each platform:
ansible_connection: podman

# Removed problematic inventory links:
# inventory:
#   links:
#     hosts: ../../inventories/test/hosts

# Enhanced driver configuration:
driver:
  name: podman
  options:
    ansible_connection_options:
      ansible_podman_executable: /usr/bin/podman
```

### 2. Enhanced Prepare Playbook (`prepare.yml`)
```yaml
# Added connection wait for containers:
- name: Wait for container to be ready
  wait_for_connection:
    timeout: 60
    delay: 5
  when: ansible_connection == 'podman'

# Changed host pattern:
hosts: all:!localhost
```

### 3. GitHub Actions Workflow (`ansible-test.yml`)
```yaml
# Added cleanup trap:
trap 'echo "🚨 Test interrupted - cleaning up..."; molecule destroy || true; podman container prune -f || true' EXIT TERM INT

# Enhanced cleanup job:
emergency-cleanup:
  if: always() && (needs.test.result == 'failure' || needs.test.result == 'cancelled')
  runs-on: self-hosted
  steps:
    - name: Emergency container cleanup
      run: ./scripts/emergency-cleanup-containers.sh
```

### 4. Emergency Cleanup Scripts

#### `scripts/emergency-cleanup-containers.sh`
- Force stops and removes all molecule containers
- Cleans up networks and images
- Provides detailed logging

#### `scripts/check-stuck-containers.sh`
- Diagnoses stuck container situations
- Provides manual cleanup commands
- Shows container status and age

## Expected Outcomes

### 1. Faster Test Failure Detection
- Connection issues will be detected within 60 seconds
- Clear error messages when containers can't be reached

### 2. Automatic Cleanup
- Containers will be cleaned up on test completion, failure, or timeout
- No more indefinitely running containers

### 3. Better Resource Management
- Reduced resource consumption on CI runners
- Automatic image and network pruning

### 4. Improved Debugging
- Enhanced logging shows connection status
- Clear distinction between container and localhost execution

## Verification Steps

1. **Test the fix locally**:
   ```bash
   cd /path/to/project
   molecule test
   ```

2. **Check container cleanup**:
   ```bash
   ./scripts/check-stuck-containers.sh
   ```

3. **Emergency cleanup if needed**:
   ```bash
   ./scripts/emergency-cleanup-containers.sh
   ```

## Monitoring

After deployment, monitor for:
- Reduced test execution times
- No containers running longer than expected
- Successful container connectivity
- Proper cleanup in GitHub Actions logs

## Prevention

The changes implement multiple layers of protection:
1. **Proactive**: Proper connection configuration prevents the issue
2. **Reactive**: Timeout and trap handlers catch failures
3. **Emergency**: Cleanup scripts handle worst-case scenarios
4. **Monitoring**: Status scripts help diagnose issues

These changes should resolve the stuck container issue while maintaining test reliability and improving resource management.
