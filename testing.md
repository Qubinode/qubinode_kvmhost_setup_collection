# Testing Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Molecule Testing](#molecule-testing)
3. [Integration Testing](#integration-testing)
4. [CI/CD Pipeline Testing](#cicd-pipeline-testing)
5. [Container-based Testing](#container-based-testing)

## Prerequisites

Before running tests, ensure you have:

1. Python 3.9+ installed
2. Ansible 2.13+ installed
3. Molecule installed:
   ```bash
   pip install molecule molecule-podman
   ```
4. Podman installed and running
5. Test user account created:
   ```bash
   sudo useradd -m -s /bin/bash test-user
   ```

## Molecule Testing

### Running Tests
```bash
cd roles/kvmhost_setup
molecule test
```

### Test Scenarios
1. Basic KVM host setup
2. Network bridge configuration
3. Storage pool management
4. User access control
5. Cockpit integration

### Viewing Results
Test results are displayed in the terminal. Detailed logs are available in:
- `molecule/default/logs/`
- `molecule/default/reports/`

## local testing
```bash
 ansible-playbook -i inventories/test/hosts test.yml
 ```
 

## Integration Testing

### Running Integration Tests
```bash
ansible-playbook tests/integration.yml -i inventories/test/hosts
```

### Test Coverage
- Role dependencies
- Variable validation
- System configuration
- Service status verification

## CI/CD Pipeline Testing

### Triggering Tests
1. Push to main branch
2. Create pull request
3. Manual workflow dispatch

### Test Matrix
- Python versions: 3.9, 3.10
- Ansible versions: 2.13, 2.14, 2.15

## Container-based Testing

### Building Test Container
```bash
podman build -t kvmhost-test -f Dockerfile .
```

### Running Tests in Container
```bash
podman run --privileged \
  -v ${PWD}:/ansible \
  kvmhost-test \
  ansible-playbook tests/integration.yml
```

### Debugging in Container
```bash
podman run -it --privileged \
  -v ${PWD}:/ansible \
  kvmhost-test \
  /bin/bash
```

## Troubleshooting

### Common Issues
1. **Permission Denied**: Ensure Podman is running and you have proper permissions
2. **Network Issues**: Verify Podman network configuration
3. **Test Failures**: Check logs in `molecule/default/logs/`

### Debugging Tips
- Use `-vvv` flag for verbose output
- Check container logs with `podman logs <container_id>`
- Run individual test scenarios with `molecule converge`

## Known Issues

### Package Conflicts

1. **curl Package on Rocky Linux 9**
   - Issue: Package conflict between curl-minimal and curl
   - Error: `package curl-minimal conflicts with curl provided by curl`
   - Workaround: Skip curl installation on Rocky Linux 9 systems

2. **Package Dependencies**
   - unzip package required for synth-shell extraction
   - libvirt packages must be installed before user creation (for libvirt group)
   - Order of operations is critical:
     1. Install base packages (including libvirt)
     2. Create user and add to libvirt group
     3. Install remaining packages
     4. Configure services

### Container Testing Requirements

1. **libvirt Group**
   - Issue: libvirt group must exist before user creation
   - Solution: Install libvirt packages before creating test user
   - Fixed: Package installation order adjusted in converge.yml

2. **Privileged Container Requirements**
   - Container must run with `--privileged` flag
   - Required capabilities: `SYS_ADMIN`
   - Required volumes: `/sys/fs/cgroup:/sys/fs/cgroup:ro`
   - Required tmpfs mounts: `/run`, `/tmp`

### System Requirements

1. **Storage Setup**
   - Minimum disk space: 10GB for testing
   - LVM support required
   - XFS filesystem support needed

2. **Network Requirements**
   - Bridge networking capability
   - NetworkManager running
   - Firewall rules for libvirt
