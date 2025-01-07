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
   pip install molecule molecule-docker
   ```
4. Docker installed and running
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
docker build -t kvmhost-test -f Dockerfile .
```

### Running Tests in Container
```bash
docker run --privileged \
  -v ${PWD}:/ansible \
  kvmhost-test \
  ansible-playbook tests/integration.yml
```

### Debugging in Container
```bash
docker run -it --privileged \
  -v ${PWD}:/ansible \
  kvmhost-test \
  /bin/bash
```

## Troubleshooting

### Common Issues
1. **Permission Denied**: Ensure Docker is running and you have proper permissions
2. **Network Issues**: Verify Docker network configuration
3. **Test Failures**: Check logs in `molecule/default/logs/`

### Debugging Tips
- Use `-vvv` flag for verbose output
- Check container logs with `docker logs <container_id>`
- Run individual test scenarios with `molecule converge`
