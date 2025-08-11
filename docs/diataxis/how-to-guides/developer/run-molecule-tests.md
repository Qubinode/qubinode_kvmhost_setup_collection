# How to Run Molecule Tests

This guide shows you how to run Molecule tests locally to validate your changes before submitting pull requests.

## 🎯 Goal

Learn to effectively use Molecule for:
- Running individual role tests
- Testing across multiple scenarios
- Debugging test failures
- Creating custom test scenarios
- Validating changes before CI/CD

## 📋 Prerequisites

- Completed [Set Up Development Environment](setup-development-environment.md)
- Container runtime (Podman/Docker) configured
- Molecule and dependencies installed
- Basic understanding of Ansible roles

## 🧪 Understanding Molecule Testing

### Test Scenarios Available

The collection includes several Molecule scenarios:

```bash
# List all available scenarios
molecule list

# Common scenarios:
# - default: Basic functionality testing
# - idempotency: Idempotency validation
# - modular: Modular role testing
# - rhel8/rhel9/rhel10: Platform-specific testing
```

### Test Sequence

Molecule follows this test sequence:
1. **dependency**: Install role dependencies
2. **create**: Create test containers
3. **prepare**: Prepare test environment
4. **converge**: Run the role
5. **idempotence**: Test idempotency
6. **verify**: Run verification tests
7. **cleanup**: Clean up test environment
8. **destroy**: Remove test containers

## 🚀 Step 1: Prepare Testing Environment

### Activate Testing Environment
```bash
# Navigate to project root
cd qubinode_kvmhost_setup_collection

# Activate Python environment
source venv/bin/activate

# Activate Molecule environment
source scripts/activate-molecule-env.sh

# Verify setup
molecule --version
```

### Check Container Images
```bash
# Pull required test images
podman pull docker.io/rockylinux/rockylinux:9-ubi-init
podman pull registry.redhat.io/ubi9-init:latest

# List available images
podman images | grep -E "(rocky|ubi)"
```

## 🔧 Step 2: Run Basic Role Tests

### Test Individual Role
```bash
# Navigate to specific role
cd roles/kvmhost_base

# Run complete test suite
molecule test

# Run specific test phases
molecule create    # Create test containers
molecule converge  # Run the role
molecule verify    # Run verification tests
molecule destroy   # Clean up
```

### Test with Different Scenarios
```bash
# Test with specific scenario
molecule test --scenario-name rhel9

# List scenarios for current role
molecule list

# Test all scenarios
for scenario in $(molecule list --format plain | awk '{print $2}' | tail -n +2); do
    echo "Testing scenario: $scenario"
    molecule test --scenario-name $scenario
done
```

## 🔍 Step 3: Debug Test Failures

### Interactive Debugging
```bash
# Create containers without destroying on failure
molecule create
molecule converge

# Connect to test container for debugging
molecule login

# Inside container, check what went wrong:
systemctl status SERVICE_NAME
journalctl -u SERVICE_NAME
cat /var/log/messages
```

### Verbose Testing
```bash
# Run with verbose output
molecule test --debug

# Run with Ansible verbose mode
ANSIBLE_VERBOSITY=3 molecule test

# Run specific test with maximum verbosity
ANSIBLE_VERBOSITY=4 molecule converge --scenario-name default
```

### Check Test Logs
```bash
# View Molecule logs
cat ~/.cache/molecule/ROLE_NAME/default/ansible.log

# Check container logs
podman logs CONTAINER_NAME

# View systemd logs in container
molecule login
journalctl --no-pager
```

## 🧩 Step 4: Test Multiple Roles

### Test Collection-Wide
```bash
# Return to project root
cd qubinode_kvmhost_setup_collection

# Run collection-wide tests
scripts/test-local-molecule.sh

# Test specific roles only
scripts/test-local-molecule.sh kvmhost_base kvmhost_networking
```

### Parallel Testing
```bash
# Test multiple roles in parallel (use with caution)
for role in kvmhost_base kvmhost_networking kvmhost_storage; do
    (cd roles/$role && molecule test --scenario-name default) &
done
wait
```

## ⚙️ Step 5: Custom Test Scenarios

### Create Custom Scenario
```bash
# Navigate to role directory
cd roles/kvmhost_base

# Create new scenario
molecule init scenario custom-test

# Edit scenario configuration
vim molecule/custom-test/molecule.yml
```

### Example Custom Scenario Configuration
```yaml
dependency:
  name: galaxy
  options:
    requirements-file: requirements.yml

driver:
  name: podman

platforms:
  - name: custom-test-instance
    image: docker.io/rockylinux/rockylinux:9-ubi-init
    dockerfile: ../default/Dockerfile.rhel
    pre_build_image: false
    systemd: always
    command: "/usr/sbin/init"
    capabilities:
      - SYS_ADMIN
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    environment:
      CUSTOM_TEST_VAR: "test_value"

provisioner:
  name: ansible
  env:
    ANSIBLE_FORCE_COLOR: "true"
    ANSIBLE_VERBOSITY: "2"
  config_options:
    defaults:
      callback_whitelist: profile_tasks, timer
  inventory:
    host_vars:
      custom-test-instance:
        custom_variable: "custom_value"

verifier:
  name: testinfra
```

## 📊 Step 6: Performance and Coverage Testing

### Performance Testing
```bash
# Run with timing information
ANSIBLE_CALLBACK_WHITELIST=profile_tasks molecule test

# Monitor resource usage during tests
htop  # In another terminal while tests run

# Check container resource usage
podman stats
```

### Test Coverage Analysis
```bash
# Run tests with coverage
pytest --cov=roles/ tests/

# Generate coverage report
pytest --cov=roles/ --cov-report=html tests/

# View coverage report
open htmlcov/index.html  # or xdg-open on Linux
```

## 🔄 Step 7: Continuous Testing Workflow

### Pre-Commit Testing
```bash
# Create pre-commit test script
cat > scripts/pre-commit-test.sh << 'EOF'
#!/bin/bash
set -e

echo "🧪 Running pre-commit tests..."

# Lint checks
echo "📝 Running ansible-lint..."
ansible-lint .

echo "📝 Running yamllint..."
yamllint .

# Quick Molecule test on changed roles
echo "🧪 Running Molecule tests on changed roles..."
CHANGED_ROLES=$(git diff --name-only HEAD~1 | grep "^roles/" | cut -d'/' -f2 | sort -u)

for role in $CHANGED_ROLES; do
    if [ -d "roles/$role/molecule" ]; then
        echo "Testing role: $role"
        cd "roles/$role"
        molecule test --scenario-name default
        cd ../..
    fi
done

echo "✅ Pre-commit tests completed!"
EOF

chmod +x scripts/pre-commit-test.sh
```

### Automated Testing Setup
```bash
# Set up Git hooks for automatic testing
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
echo "🚀 Running pre-push validation..."
source venv/bin/activate
source scripts/activate-molecule-env.sh
scripts/pre-commit-test.sh
EOF

chmod +x .git/hooks/pre-push
```

## 📋 Testing Best Practices

### Test Organization
- **Unit Tests**: Test individual tasks and functions
- **Integration Tests**: Test role interactions
- **System Tests**: Test complete collection functionality
- **Performance Tests**: Validate performance requirements

### Test Data Management
```bash
# Use consistent test data
mkdir -p tests/fixtures
cat > tests/fixtures/test-vars.yml << 'EOF'
test_kvm_host_ipaddr: "192.168.1.100"
test_admin_user: "testuser"
test_bridge_name: "testbr0"
EOF
```

### Test Environment Isolation
```bash
# Use unique container names
export MOLECULE_EPHEMERAL_DIRECTORY=/tmp/molecule-$(date +%s)

# Clean up between tests
molecule destroy
podman system prune -f
```

## 🚨 Troubleshooting Test Issues

### Common Test Failures

**Problem**: "Container creation failed"
**Solution**:
```bash
# Check container runtime
podman info
systemctl --user status podman.socket

# Clean up stale containers
podman system prune -a -f
```

**Problem**: "Ansible connection failed"
**Solution**:
```bash
# Check container is running
podman ps

# Test manual connection
podman exec -it CONTAINER_NAME /bin/bash

# Check Ansible inventory
molecule list --format yaml
```

**Problem**: "Role dependencies not found"
**Solution**:
```bash
# Install dependencies
ansible-galaxy collection install -r requirements.yml

# Check role path
echo $ANSIBLE_ROLES_PATH
```

### Debug Container Issues
```bash
# Start container manually for debugging
molecule create
molecule login

# Check container logs
podman logs CONTAINER_NAME

# Inspect container configuration
podman inspect CONTAINER_NAME
```

## 📈 Advanced Testing Techniques

### Matrix Testing
```bash
# Test across multiple platforms
for platform in rhel8 rhel9 rhel10; do
    molecule test --scenario-name $platform
done
```

### Parallel Testing with Resource Limits
```bash
# Limit parallel tests to avoid resource exhaustion
export MOLECULE_PARALLEL=2
molecule test --parallel
```

### Custom Verification Tests
Create custom testinfra tests in `molecule/default/tests/`:

```python
def test_service_running(host):
    service = host.service("libvirtd")
    assert service.is_running
    assert service.is_enabled

def test_bridge_exists(host):
    cmd = host.run("ip link show qubibr0")
    assert cmd.rc == 0
```

## 🔗 Related Documentation

- **Previous**: [Set Up Development Environment](setup-development-environment.md)
- **Next**: [Contributing Guidelines](contributing-guidelines.md)
- **Reference**: [Testing Configuration](../../reference/testing/test-scenarios.md)
- **Explanation**: [Testing Framework Selection](../../explanations/testing-framework-selection.md)

---

*This guide covered comprehensive Molecule testing. For contributing your tested changes, see the contributing guidelines. For understanding the testing architecture, check the explanations section.*
