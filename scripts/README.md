# GitHub Actions Runner Setup Scripts

This directory contains scripts for setting up GitHub Actions self-hosted runners on RHEL-based systems.

## 📋 Available Scripts

### Primary Setup Scripts

| Script | Purpose | Target Systems |
|--------|---------|----------------|
| `setup-github-runner-rocky.sh` | **Recommended** - Full runner setup | Rocky Linux, AlmaLinux, RHEL, CentOS Stream |
| `setup-github-runner.sh` | Generic setup script | Various Linux distributions |
| `fix-epel-on-runner.sh` | EPEL repository cleanup | RHEL-based systems with EPEL issues |

### Utility Scripts

| Script | Purpose |
|--------|---------|
| `setup-selinux-for-ci.sh` | SELinux configuration for CI environments |

## 🎯 Recommended Setup Process

### 1. Choose Your Distribution

**🥇 Recommended: Rocky Linux 9.x**
- Free and open-source
- RHEL-compatible without subscription
- Reliable EPEL repository access
- Excellent community support

**🥈 Alternative: AlmaLinux 9.x**
- Same benefits as Rocky Linux
- Different community backing
- Identical setup process

**🥉 Enterprise: RHEL 9.x**
- Official Red Hat support
- Requires active subscription
- Additional repository configuration needed

### 2. Run the Setup Script

```bash
# For Rocky Linux, AlmaLinux, RHEL, or CentOS Stream
sudo ./scripts/setup-github-runner-rocky.sh

# The script will:
# ✅ Detect your distribution automatically
# ✅ Install required packages and dependencies
# ✅ Configure Python 3.11 environment
# ✅ Set up Podman for container testing
# ✅ Configure EPEL repository properly
# ✅ Install Ansible and Molecule
# ✅ Configure SELinux for CI operations
```

### 3. Register the Runner

```bash
# Download GitHub Actions runner
cd /home/github-runner
wget https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-x64-2.317.0.tar.gz
tar xzf actions-runner-linux-x64-2.317.0.tar.gz

# Configure runner (replace with your repository URL and token)
./config.sh --url https://github.com/your-org/your-repo --token YOUR_TOKEN

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
```

## 🔧 Distribution-Specific Considerations

### Rocky Linux 9.x ✅
```bash
# Standard setup - no special requirements
sudo ./scripts/setup-github-runner-rocky.sh
```

### AlmaLinux 9.x ✅
```bash
# Identical to Rocky Linux setup
sudo ./scripts/setup-github-runner-rocky.sh
```

### RHEL 9.x ⚠️
```bash
# Prerequisites: Active RHEL subscription
sudo subscription-manager register
sudo subscription-manager attach --auto

# Enable required repositories
sudo subscription-manager repos --enable rhel-9-for-x86_64-baseos-rpms
sudo subscription-manager repos --enable rhel-9-for-x86_64-appstream-rpms
sudo subscription-manager repos --enable codeready-builder-for-rhel-9-x86_64-rpms

# Then run setup script
sudo ./scripts/setup-github-runner-rocky.sh
```

### CentOS Stream 9 ⚠️
```bash
# Note: Rolling release - more frequent updates needed
sudo ./scripts/setup-github-runner-rocky.sh

# Consider more frequent maintenance
sudo dnf update -y  # Run weekly
```

## 🚨 Troubleshooting

### EPEL Repository Issues
```bash
# If you encounter EPEL GPG verification errors:
sudo ./scripts/fix-epel-on-runner.sh

# This script will:
# - Clean corrupted EPEL metadata
# - Reinstall EPEL repository cleanly
# - Configure GPG verification appropriately
# - Verify repository functionality
```

### Python SELinux Issues
```bash
# If SELinux Python bindings are missing:
sudo dnf reinstall python3-libselinux libselinux-python3
```

### Podman Permission Issues
```bash
# Configure rootless Podman for the runner user:
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 github-runner
```

## 📊 System Requirements

### Minimum Requirements
- **CPU**: 2 cores
- **RAM**: 4 GB
- **Storage**: 20 GB free space
- **OS**: RHEL-based distribution (version 8 or 9)

### Recommended Specifications
- **CPU**: 4+ cores
- **RAM**: 8+ GB
- **Storage**: 50+ GB free space
- **Network**: High-speed internet connection

## 🔒 Security Considerations

### SELinux
- Maintained in enforcing mode
- Minimal policy adjustments for CI operations
- Proper Python bindings configured

### EPEL Repository
- GPG verification disabled by default for CI reliability
- Can be enabled for production environments
- Keys imported for optional future use

### Container Security
- Podman used instead of Docker
- Rootless containers when possible
- Official UBI images for testing

## 📚 Documentation

For detailed information, see:
- **ADR-0013**: GitHub Actions Runner Setup (`docs/adr/ADR-0013-GITHUB-ACTIONS-RUNNER-SETUP.md`)
- **ADR-0012**: EPEL Repository Management (`docs/adr/ADR-0012-EPEL-REPOSITORY-MANAGEMENT.md`)

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review the ADR documentation
3. Check GitHub Actions runner logs: `journalctl -u actions.runner.*`
4. Verify system resources and network connectivity
