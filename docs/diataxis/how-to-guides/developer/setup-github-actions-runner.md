# Set Up GitHub Actions Self-Hosted Runner (CentOS Stream 10)

This guide walks you through setting up a CentOS Stream 10 self-hosted runner for the Qubinode KVM Host Setup Collection CI/CD pipeline.

## Prerequisites

- Fresh CentOS Stream 10 installation
- Root or sudo access
- Network connectivity to GitHub
- Minimum 4 CPU cores, 8GB RAM, 50GB storage (recommended)

## Overview

The CI/CD pipeline requires a self-hosted runner with:

| Component | Requirement |
|-----------|-------------|
| **OS** | CentOS Stream 10 |
| **Python** | Python 3.12 (default) |
| **Container Runtime** | Podman 5.x (with cgroup v2 support) |
| **Virtualization** | KVM/libvirt for integration tests |

## Step 1: Install Required Packages

### Core Container Packages

```bash
sudo dnf install -y \
  podman \
  podman-docker \
  buildah \
  skopeo
```

### Git and GitHub CLI

```bash
# Install via dnf (NOT third-party repo)
sudo dnf install -y \
  git \
  gh
```

> **Note**: Installing `gh` via dnf avoids the GPG verification issues encountered with third-party repositories on Rocky Linux 9.

### Python Development

```bash
sudo dnf install -y \
  python3-pip \
  python3-devel \
  python3-libselinux
```

### Virtualization Testing

```bash
sudo dnf install -y \
  qemu-kvm \
  libvirt \
  virt-install
```

### Build Tools

```bash
sudo dnf install -y \
  gcc \
  make
```

### All-in-One Installation

```bash
sudo dnf install -y \
  podman podman-docker buildah skopeo \
  git gh \
  python3-pip python3-devel python3-libselinux \
  qemu-kvm libvirt virt-install \
  gcc make
```

## Step 2: Configure Podman

### Enable Rootless Podman

```bash
# Enable lingering for the runner user
sudo loginctl enable-linger $(whoami)

# Verify cgroup v2 delegation is enabled
cat /sys/fs/cgroup/cgroup.controllers
# Expected output: cpuset cpu io memory hugetlb pids rdma misc
```

### Configure Storage

Ensure adequate storage for container images:

```bash
# Check available space
df -h /var/lib/containers

# If needed, configure additional storage
# Edit /etc/containers/storage.conf
```

### Enable Podman Socket (Docker Compatibility)

```bash
# For the runner user
systemctl --user enable --now podman.socket

# Verify socket is active
systemctl --user status podman.socket
```

## Step 3: Configure SELinux

SELinux should remain in enforcing mode for accurate testing:

```bash
# Verify SELinux is enforcing
getenforce

# If not enforcing, enable it
sudo setenforce 1
sudo sed -i 's/SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
```

## Step 4: Configure Libvirt

### Start and Enable Services

For CentOS Stream 10, libvirt uses modular daemons (see ADR-0016):

```bash
# Enable socket-activated services
sudo systemctl enable --now virtqemud.socket
sudo systemctl enable --now virtnetworkd.socket
sudo systemctl enable --now virtstoraged.socket

# Verify services
sudo systemctl status virtqemud.socket
```

### Add Runner User to libvirt Group

```bash
sudo usermod -aG libvirt $(whoami)

# Log out and back in, or use newgrp
newgrp libvirt
```

## Step 5: Create Service Account

Create a dedicated service account for the runner:

```bash
# Create runner user
sudo useradd -m -s /bin/bash github-runner

# Add to required groups
sudo usermod -aG libvirt github-runner
sudo usermod -aG wheel github-runner  # For sudo access

# Configure sudo for CI operations
echo "github-runner ALL=(ALL) NOPASSWD: /usr/bin/dnf, /usr/bin/podman" | \
  sudo tee /etc/sudoers.d/github-runner
sudo chmod 440 /etc/sudoers.d/github-runner

# Enable lingering for rootless podman
sudo loginctl enable-linger github-runner
```

## Step 6: Install GitHub Actions Runner

### Download Runner

```bash
# Switch to runner user
sudo -u github-runner -i

# Create runner directory
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download latest runner (check GitHub for current version)
RUNNER_VERSION="2.321.0"
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L \
  https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Extract
tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
```

### Configure Runner

Get the registration token from GitHub:

1. Go to **Repository Settings** > **Actions** > **Runners**
2. Click **New self-hosted runner**
3. Copy the registration token

```bash
# Configure the runner
./config.sh --url https://github.com/Qubinode/qubinode_kvmhost_setup_collection \
  --token <YOUR_REGISTRATION_TOKEN> \
  --name "centos-stream-10-runner" \
  --labels "self-hosted,Linux,X64,centos-stream-10" \
  --work "_work"
```

### Install as Service

```bash
# Exit back to root/admin user
exit

# Install runner service
cd /home/github-runner/actions-runner
sudo ./svc.sh install github-runner

# Start the service
sudo ./svc.sh start

# Enable on boot
sudo systemctl enable actions.runner.Qubinode-qubinode_kvmhost_setup_collection.centos-stream-10-runner.service
```

## Step 7: Verify Installation

### Check Runner Status

```bash
# Verify service is running
sudo ./svc.sh status

# Check systemd service
sudo systemctl status actions.runner.*.service
```

### Verify on GitHub

1. Go to **Repository Settings** > **Actions** > **Runners**
2. Confirm the new runner shows as **Idle** (green)

## Step 8: Test CI Pipeline

Trigger a test workflow run:

```bash
gh workflow run ansible-test.yml --repo Qubinode/qubinode_kvmhost_setup_collection
```

### Expected Results

| Job | Expected |
|-----|----------|
| lint | Pass |
| test (2.18, 3.11) | Pass |
| test (2.19, 3.11) | Pass |
| centos-stream10-test | Pass |
| security | Pass |

## Troubleshooting

### Podman Permission Issues

```bash
# Verify subuid/subgid ranges
grep github-runner /etc/subuid /etc/subgid

# If missing, add ranges
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 github-runner
```

### SELinux Denials

```bash
# Check for denials
sudo ausearch -m avc -ts recent

# Generate policy module if needed
sudo audit2allow -a -M my-runner-policy
sudo semodule -i my-runner-policy.pp
```

### Container Storage Issues

```bash
# Reset podman storage
podman system reset

# Verify storage driver
podman info | grep -A5 "graphDriverName"
```

### Runner Connectivity Issues

```bash
# Test GitHub connectivity
curl -I https://github.com
curl -I https://api.github.com

# Check runner logs
journalctl -u actions.runner.*.service -f
```

## Maintenance

### Regular Updates

```bash
# Weekly system updates
sudo dnf update -y

# Monthly container cleanup
podman system prune -af

# Quarterly runner updates
# Check https://github.com/actions/runner/releases
```

### Monitoring

Monitor these paths for disk usage:

- `/var/lib/containers` - Container images and layers
- `/home/github-runner/_work` - Workflow workspaces
- `/tmp` - Temporary build files

## Related Documentation

- [ADR-0016: Modular Libvirt Daemons for RHEL 10](../../../adrs/adr-0016-modular-libvirt-daemons-rhel10.md)
- [ADR-0017: ansible-core Version Support Policy](../../../adrs/adr-0017-ansible-core-version-support-policy.md)
- [ADR-0018: CI/CD Third-Party Repository GPG Strategy](../../../adrs/adr-0018-ci-third-party-repo-gpg-strategy.md)
- [GitHub Issue #127: CentOS Stream 10 Runner Requirements](https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues/127)

## References

- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [CentOS Stream 10 Documentation](https://docs.centos.org/)
- [Podman Documentation](https://docs.podman.io/)
- [Libvirt Modular Daemons](https://libvirt.org/daemons.html)
