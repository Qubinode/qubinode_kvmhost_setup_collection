# GitHub Self-Hosted Runner Setup

This directory contains scripts and configurations for setting up and managing GitHub Actions self-hosted runners optimized for Ansible collection CI/CD.

## Quick Start

### 1. Initial Setup

Run the setup script as root to install and configure a GitHub runner:

```bash
sudo ./setup-github-runner.sh
```

This will:
- Install system dependencies (Python 3.11, containers, development tools)
- Create a dedicated runner user
- Install Ansible and related tools in a virtual environment
- Configure systemd service for the runner
- Generate registration and management scripts

### 2. Register Runner

Switch to the runner user and register with your repository:

```bash
sudo su - github-runner
./register-runner.sh https://github.com/owner/repo <registration_token>
```

### 3. Manage Runners

Use the management script to control multiple runners:

```bash
# List all runners
./manage-github-runners.sh list

# Check status
./manage-github-runners.sh status

# Start/stop/restart
./manage-github-runners.sh start runner-name
./manage-github-runners.sh stop runner-name
./manage-github-runners.sh restart runner-name

# Health check
./manage-github-runners.sh health
```

## Files Overview

### Core Scripts

- **`setup-github-runner.sh`** - Main installation script
  - Installs system dependencies
  - Configures Python 3.11 environment
  - Sets up Ansible tools and container runtime
  - Creates systemd service

- **`manage-github-runners.sh`** - Multi-runner management
  - Register/remove runners
  - Start/stop services
  - Health monitoring
  - Configuration management

### Configuration

- **`runner-config.yml`** - YAML configuration file
  - Runner templates (standard, molecule, security)
  - Environment variables
  - Monitoring and maintenance settings
  - Repository-specific configurations

## Features

### 🚀 Optimized for Ansible Collections
- Python 3.11 for RHEL 9 compatibility
- Ansible-core 2.17+ with latest tools
- Molecule testing with Podman support
- Pre-configured virtual environments

### 🔧 Container Support
- Podman (preferred) and Docker
- Container cleanup automation
- Multi-architecture support

### 📊 Monitoring & Health Checks
- Systemd service management
- Automatic health verification
- Log rotation and retention
- Resource usage monitoring

### 🛡️ Security Features
- Dedicated runner user with limited privileges
- Security scanning tools (bandit, safety)
- Repository access controls
- Automatic dependency vulnerability checks

### 📈 Scalability
- Multi-runner support
- Template-based configurations
- Automatic registration/deregistration
- Load balancing capabilities

## Runner Types

### Standard Runner
```bash
# General CI/CD pipeline
Labels: self-hosted,linux,ansible,standard
Use cases: lint, basic tests, builds
```

### Molecule Runner
```bash
# Container-based testing
Labels: self-hosted,linux,ansible,molecule,podman
Use cases: role testing, integration tests
```

### Security Runner
```bash
# Security scanning and compliance
Labels: self-hosted,linux,ansible,security
Use cases: vulnerability scans, compliance checks
```

## Environment Variables

The runner environment includes:

```bash
PYTHON_VERSION=3.11
ANSIBLE_PYTHON_INTERPRETER=/home/github-runner/ansible-venv/bin/python3.11
PY_COLORS=1
ANSIBLE_FORCE_COLOR=1
CONTAINER_RUNTIME=podman
MOLECULE_DEBUG=false
ANSIBLE_VERBOSITY=1
```

## Troubleshooting

### Check Runner Status
```bash
# Service status
sudo systemctl status github-runner

# Service logs
journalctl -u github-runner -f

# Runner verification
./setup-github-runner.sh verify
```

### Common Issues

1. **Runner registration fails**
   - Check token validity
   - Verify repository permissions
   - Ensure network connectivity

2. **Ansible tests timeout**
   - Check virtual environment activation
   - Verify Python interpreter settings
   - Monitor container runtime status

3. **Permission issues**
   - Ensure runner user has proper sudo access
   - Check file ownership in runner directory
   - Verify systemd service permissions

### Health Check
```bash
# Comprehensive health check
./manage-github-runners.sh health

# Manual verification
sudo su - github-runner
source ~/.runner-env
ansible --version
molecule --version
podman --version
```

## Maintenance

### Regular Tasks
- Monitor disk space (`df -h`)
- Check service status (`systemctl status github-runner`)
- Review logs (`journalctl -u github-runner`)
- Update configurations as needed

### Updates
```bash
# Update runner configurations
./manage-github-runners.sh update

# Verify installation
./setup-github-runner.sh verify
```

### Cleanup
```bash
# Container cleanup (automated in post-job hooks)
podman system prune -f
docker system prune -f

# Log cleanup (automated via logrotate)
sudo logrotate /etc/logrotate.d/github-runner
```

## Integration with CI/CD

The runners are optimized for the `ansible-test.yml` workflow with:

- ✅ Python 3.11 support for RHEL 9 compatibility
- ✅ Ansible-core 2.17+ with latest features
- ✅ Molecule testing with Podman containers
- ✅ Security scanning with bandit and safety
- ✅ Automatic dependency management
- ✅ Enhanced error handling and timeouts

## Getting Help

### Commands Reference
```bash
# Setup help
./setup-github-runner.sh help

# Management help
./manage-github-runners.sh help

# Verify installation
./setup-github-runner.sh verify
```

### Log Locations
- Runner logs: `journalctl -u github-runner`
- Setup logs: `/var/log/github-runner-setup.log`
- Ansible environment: `/home/github-runner/ansible-venv/`

### Support
For issues specific to this setup, check:
1. Service status and logs
2. Runner environment variables
3. Network connectivity to GitHub
4. Repository permissions and tokens
