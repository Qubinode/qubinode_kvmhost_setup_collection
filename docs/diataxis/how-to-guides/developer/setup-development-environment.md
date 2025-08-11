# How to Set Up Development Environment

This guide walks you through setting up a complete development environment for contributing to the Qubinode KVM Host Setup Collection.

## 🎯 Goal

Set up a development environment that includes:
- Source code repository with proper Git configuration
- Python virtual environment with all dependencies
- Ansible development tools and linting
- Molecule testing framework
- Container runtime for testing
- IDE configuration and extensions

## 📋 Prerequisites

- Git installed and configured
- Python 3.9 or newer
- Container runtime (Podman preferred, Docker acceptable)
- Text editor or IDE (VS Code recommended)
- Basic familiarity with command line operations

## 🚀 Step 1: Fork and Clone Repository

### Fork the Repository
1. Go to [GitHub repository](https://github.com/Qubinode/qubinode_kvmhost_setup_collection)
2. Click "Fork" to create your own copy
3. Clone your fork:

```bash
git clone https://github.com/YOUR_USERNAME/qubinode_kvmhost_setup_collection.git
cd qubinode_kvmhost_setup_collection
```

### Configure Git
```bash
# Set up upstream remote
git remote add upstream https://github.com/Qubinode/qubinode_kvmhost_setup_collection.git

# Configure Git for the project
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Verify configuration
git remote -v
```

## 🐍 Step 2: Set Up Python Environment

### Create Virtual Environment
```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip setuptools wheel
```

### Install Development Dependencies
```bash
# Install all development requirements
pip install -r requirements-dev.txt

# Install additional development tools
pip install \
    ansible-lint \
    yamllint \
    molecule[podman] \
    pytest \
    bandit \
    black \
    flake8
```

### Verify Python Setup
```bash
# Check Python version
python --version

# Check Ansible version
ansible --version

# Check Molecule version
molecule --version

# List installed packages
pip list | grep -E "(ansible|molecule|lint)"
```

## 🔧 Step 3: Configure Ansible Development

### Set Up Ansible Configuration
```bash
# Copy project ansible.cfg if not present
cp ansible.cfg.example ansible.cfg  # if exists

# Verify Ansible configuration
ansible-config dump --only-changed
```

### Install Ansible Collections
```bash
# Install required collections for development
ansible-galaxy collection install -r requirements.yml

# Verify collections
ansible-galaxy collection list
```

### Test Ansible Setup
```bash
# Test basic Ansible functionality
ansible localhost -m setup

# Test collection import
ansible-doc tosin2013.qubinode_kvmhost_setup_collection.kvmhost_setup
```

## 🐳 Step 4: Set Up Container Runtime

### Install and Configure Podman (Recommended)
```bash
# Install Podman (on RHEL/Rocky/AlmaLinux)
sudo dnf install -y podman podman-docker

# Configure Podman for rootless operation
echo 'unqualified-search-registries = ["docker.io", "registry.redhat.io", "quay.io"]' | sudo tee -a /etc/containers/registries.conf

# Test Podman
podman run --rm hello-world
```

### Alternative: Docker Setup
```bash
# Install Docker (if Podman not available)
sudo dnf install -y docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -a -G docker $USER

# Test Docker (logout/login required)
docker run --rm hello-world
```

## 🧪 Step 5: Set Up Molecule Testing

### Configure Molecule Environment
```bash
# Activate molecule environment script
source scripts/activate-molecule-env.sh

# Verify Molecule configuration
molecule --version
molecule list
```

### Test Molecule Setup
```bash
# Run a quick test
cd roles/kvmhost_base
molecule test --scenario-name default

# Check available scenarios
molecule list
```

### Configure Test Images
```bash
# Pull required test images
podman pull docker.io/rockylinux/rockylinux:9-ubi-init
podman pull registry.redhat.io/ubi9-init:latest

# Verify images
podman images | grep -E "(rocky|ubi)"
```

## 💻 Step 6: IDE Configuration

### VS Code Setup (Recommended)

Install recommended extensions:
```bash
# Install VS Code extensions via command line
code --install-extension ms-python.python
code --install-extension redhat.ansible
code --install-extension redhat.vscode-yaml
code --install-extension ms-vscode.vscode-json
code --install-extension streetsidesoftware.code-spell-checker
```

Create `.vscode/settings.json`:
```json
{
    "python.defaultInterpreterPath": "./venv/bin/python",
    "ansible.python.interpreterPath": "./venv/bin/python",
    "yaml.schemas": {
        "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook": "playbooks/*.yml",
        "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/tasks": "roles/*/tasks/*.yml"
    },
    "files.associations": {
        "*.yml": "ansible"
    }
}
```

### Alternative: Vim/Neovim Setup
```bash
# Install vim-ansible plugin
git clone https://github.com/pearofducks/ansible-vim ~/.vim/pack/plugins/start/ansible-vim

# Add to .vimrc
echo "autocmd BufRead,BufNewFile *.yml set filetype=ansible" >> ~/.vimrc
```

## ✅ Step 7: Verify Complete Setup

### Run Development Environment Test
```bash
# Create test script
cat > test-dev-env.sh << 'EOF'
#!/bin/bash
set -e

echo "🧪 Testing Development Environment..."

# Test Python environment
echo "✓ Python version: $(python --version)"
echo "✓ Pip packages: $(pip list | wc -l) installed"

# Test Ansible
echo "✓ Ansible version: $(ansible --version | head -1)"
echo "✓ Collections: $(ansible-galaxy collection list | wc -l) installed"

# Test linting tools
echo "✓ ansible-lint: $(ansible-lint --version)"
echo "✓ yamllint: $(yamllint --version)"

# Test Molecule
echo "✓ Molecule version: $(molecule --version)"

# Test container runtime
if command -v podman &> /dev/null; then
    echo "✓ Podman version: $(podman --version)"
elif command -v docker &> /dev/null; then
    echo "✓ Docker version: $(docker --version)"
fi

echo "🎉 Development environment is ready!"
EOF

chmod +x test-dev-env.sh
./test-dev-env.sh
```

### Run Quick Validation
```bash
# Test linting
ansible-lint roles/kvmhost_base/

# Test YAML syntax
yamllint roles/kvmhost_base/tasks/main.yml

# Test Molecule (quick check)
cd roles/kvmhost_base
molecule check
cd ../..
```

## 🎉 What You've Accomplished

Excellent! You now have:
- ✅ Complete source code repository with proper Git setup
- ✅ Python virtual environment with all dependencies
- ✅ Ansible development tools configured
- ✅ Molecule testing framework ready
- ✅ Container runtime for testing
- ✅ IDE configured with appropriate extensions
- ✅ Linting and quality tools installed

## 🔄 Daily Development Workflow

### Starting Development Session
```bash
# Navigate to project
cd qubinode_kvmhost_setup_collection

# Activate Python environment
source venv/bin/activate

# Activate Molecule environment
source scripts/activate-molecule-env.sh

# Update from upstream
git fetch upstream
git checkout main
git merge upstream/main
```

### Before Making Changes
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Run pre-commit checks
ansible-lint .
yamllint .
```

### Testing Your Changes
```bash
# Test specific role
cd roles/ROLE_NAME
molecule test

# Test collection-wide
scripts/test-local-molecule.sh
```

## 🆘 Troubleshooting

### Common Setup Issues

**Problem**: "Python module not found"
**Solution**: Ensure virtual environment is activated: `source venv/bin/activate`

**Problem**: "Molecule command not found"
**Solution**: Run the activation script: `source scripts/activate-molecule-env.sh`

**Problem**: "Container runtime not accessible"
**Solution**: 
- For Podman: Check user permissions and restart session
- For Docker: Add user to docker group and restart session

**Problem**: "Ansible collections not found"
**Solution**: Install requirements: `ansible-galaxy collection install -r requirements.yml`

### Environment Validation

```bash
# Check all tools are available
which python ansible ansible-lint yamllint molecule podman

# Verify paths
echo $PATH
echo $PYTHONPATH

# Check virtual environment
which pip
pip show ansible-core
```

## 🔗 Related Documentation

- **Next Steps**: [Run Molecule Tests](run-molecule-tests.md)
- **Contributing**: [Contributing Guidelines](contributing-guidelines.md)
- **Testing**: [Testing Framework](testing-framework.md)
- **Building**: [Build Collection from Source](build-from-source.md)

---

*This guide established your development environment. Next, learn how to run tests and contribute effectively to the project.*
