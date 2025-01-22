# Installation Guide

## Prerequisites

Before installing the Qubinode KVM Host Setup Collection, ensure your system meets the following requirements:

- Ansible 2.9+ installed
- Python 3.6+ installed
- Root or sudo privileges on target hosts
- SSH access to target hosts

## Installation Methods

### 1. Using Ansible Galaxy

```bash
ansible-galaxy collection install qubinode.kvmhost_setup
```

### 2. From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/qubinode/qubinode_kvmhost_setup_collection.git
   cd qubinode_kvmhost_setup_collection
   ```

2. Install dependencies:
   ```bash
   ansible-galaxy install -r requirements.yml
   ```

3. Build the collection:
   ```bash
   make build
   ```

4. Install the collection:
   ```bash
   ansible-galaxy collection install qubinode-kvmhost_setup-*.tar.gz
   ```

## Configuration

After installation, configure your inventory file:

```yaml
all:
  hosts:
    kvm_host:
      ansible_host: 192.168.1.100
      ansible_user: root
```

## Verification

To verify the installation, run:

```bash
ansible-playbook -i inventory test.yml
```

## Troubleshooting Installation

If you encounter issues during installation:

1. Check Ansible version:
   ```bash
   ansible --version
   ```

2. Verify Python version:
   ```bash
   python3 --version
   ```

3. Check collection installation:
   ```bash
   ansible-galaxy collection list
