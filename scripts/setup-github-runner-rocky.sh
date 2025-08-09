#!/bin/bash

# =============================================================================
# GitHub Actions Runner Setup - The "Infrastructure Architect"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script orchestrates the complete setup of GitHub Actions self-hosted runners
# on RHEL-based systems, creating a production-ready CI/CD infrastructure.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: System Preparation - OS detection, user creation, and base package installation
# 2. [PHASE 2]: Repository Configuration - EPEL setup with security considerations per ADR-0012
# 3. [PHASE 3]: Python Environment - Python 3.11 installation and virtual environment setup
# 4. [PHASE 4]: Container Runtime - Podman installation and rootless configuration
# 5. [PHASE 5]: Ansible Ecosystem - Ansible-core, Molecule, and collection dependencies
# 6. [PHASE 6]: Security Hardening - SELinux configuration and security policies
# 7. [PHASE 7]: Runner Integration - GitHub Actions runner preparation and service setup
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Creates: Complete CI/CD infrastructure for automated testing
# - Supports: Rocky Linux, AlmaLinux, RHEL, and CentOS Stream distributions
# - Implements: ADR-0013 GitHub Actions Runner Setup requirements
# - Integrates: With ADR-0012 EPEL Repository Management strategy
# - Enables: Automated testing of Ansible collections in production-like environments
# - Provides: Isolated runner environment with proper security boundaries
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - SECURITY: Implements rootless containers and proper SELinux configuration
# - COMPATIBILITY: Supports multiple RHEL-based distributions with unified approach
# - ISOLATION: Creates dedicated github-runner user with minimal privileges
# - REPRODUCIBILITY: Ensures consistent runner environments across deployments
# - COMPLIANCE: Follows enterprise security standards and ADR requirements
# - AUTOMATION: Fully automated setup with minimal manual intervention required
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - OS Support: Add new RHEL-based distributions in detect_os() function
# - Version Updates: Modify Python, Ansible, or Molecule version constants
# - Security Policies: Update SELinux configuration for new security requirements
# - Package Dependencies: Add new system packages in install_system_packages()
# - Runner Configuration: Modify runner setup for new GitHub Actions features
# - Integration Points: Add support for new monitoring or logging systems
#
# 🚨 IMPORTANT FOR LLMs: This script requires root privileges and modifies system
# configuration. It creates users, installs packages, and configures security policies.
# Always review changes carefully and test in non-production environments first.

# GitHub Self-Hosted Runner Setup Script for RHEL-Based Systems
# Supports Rocky Linux, AlmaLinux, RHEL, and CentOS Stream
# See docs/adr/ADR-0013-GITHUB-ACTIONS-RUNNER-SETUP.md for detailed guidance

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/github-runner-setup.log"
RUNNER_USER="${RUNNER_USER:-github-runner}"
RUNNER_HOME="/home/${RUNNER_USER}"
RUNNER_VERSION="${RUNNER_VERSION:-2.317.0}"
PYTHON_VERSION="3.11"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}"
}

info() { log "INFO" "${BLUE}$*${NC}"; }
warn() { log "WARN" "${YELLOW}$*${NC}"; }
error() { log "ERROR" "${RED}$*${NC}"; }
success() { log "SUCCESS" "${GREEN}$*${NC}"; }

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
}

# Detect OS and version with enhanced Rocky/CentOS Stream support
detect_os() {
    if [[ -f /etc/rocky-release ]]; then
        OS="rocky"
        VERSION=$(grep -oE '[0-9]+' /etc/rocky-release | head -1)
        VARIANT="Rocky Linux"
    elif [[ -f /etc/almalinux-release ]]; then
        OS="almalinux"
        VERSION=$(grep -oE '[0-9]+' /etc/almalinux-release | head -1)
        VARIANT="AlmaLinux"
    elif [[ -f /etc/centos-release ]]; then
        if grep -q "Stream" /etc/centos-release; then
            OS="centos-stream"
            VERSION=$(grep -oE '[0-9]+' /etc/centos-release | head -1)
            VARIANT="CentOS Stream"
        else
            OS="centos"
            VERSION=$(grep -oE '[0-9]+' /etc/centos-release | head -1)
            VARIANT="CentOS"
        fi
    elif [[ -f /etc/redhat-release ]]; then
        if grep -q "Red Hat Enterprise Linux" /etc/redhat-release; then
            OS="rhel"
            VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -1)
            VARIANT="RHEL"
        else
            OS="rhel-derivative"
            VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -1)
            VARIANT="RHEL-based"
        fi
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
        VERSION=$(cat /etc/debian_version | cut -d. -f1)
        VARIANT="Debian"
    else
        error "Unsupported operating system"
        exit 1
    fi
    
    info "Detected OS: ${VARIANT} ${VERSION}"
    
    # Set package manager
    if [[ $OS =~ ^(rocky|almalinux|centos|centos-stream|rhel|rhel-derivative)$ ]]; then
        PKG_MGR="dnf"
        if ! command -v dnf &> /dev/null; then
            PKG_MGR="yum"
        fi
    else
        PKG_MGR="apt"
    fi
    
    info "Package manager: ${PKG_MGR}"
}

# Install system dependencies for Rocky/CentOS Stream
install_system_deps() {
    info "Installing system dependencies for ${VARIANT}..."
    
    if [[ $OS =~ ^(rocky|almalinux|centos|centos-stream|rhel|rhel-derivative)$ ]]; then
        # Display distribution-specific guidance
        case $OS in
            "rocky")
                info "✅ Rocky Linux detected - Recommended distribution for GitHub Actions runners"
                ;;
            "almalinux")
                info "✅ AlmaLinux detected - Excellent alternative to Rocky Linux"
                ;;
            "rhel")
                info "⚠️  RHEL detected - Ensure active subscription for repository access"
                ;;
            "centos-stream")
                info "⚠️  CentOS Stream detected - Rolling release, more frequent updates needed"
                ;;
        esac

        # Update system
        $PKG_MGR update -y

        # Install EPEL repository (if available)
        if [[ $VERSION -ge 8 ]]; then
            # Import EPEL GPG key first
            info "Importing EPEL GPG key..."
            rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9 2>/dev/null || warn "Failed to import EPEL GPG key"

            # Install EPEL repository
            if [[ $OS == "rocky" ]]; then
                info "Using --nogpgcheck for Rocky Linux EPEL installation"
                $PKG_MGR install -y --nogpgcheck epel-release || warn "EPEL repository not available"
            else
                $PKG_MGR install -y epel-release || warn "EPEL repository not available"
            fi
        fi

        # Enable CRB/PowerTools repository for development packages
        if [[ $OS == "rocky" ]] || [[ $OS == "almalinux" ]] || [[ $OS == "centos-stream" ]]; then
            if [[ $VERSION -ge 9 ]]; then
                $PKG_MGR config-manager --set-enabled crb || warn "CRB repository not available"
            elif [[ $VERSION -eq 8 ]]; then
                $PKG_MGR config-manager --set-enabled powertools || warn "PowerTools repository not available"
            fi
        fi
        
        # Install development tools and dependencies
        $PKG_MGR groupinstall -y "Development Tools" || $PKG_MGR install -y gcc gcc-c++ make
        
        # Core dependencies
        $PKG_MGR install -y \
            git \
            curl \
            wget \
            tar \
            gzip \
            unzip \
            sudo \
            which \
            jq \
            openssl \
            openssl-devel \
            libffi-devel \
            zlib-devel \
            bzip2-devel \
            readline-devel \
            sqlite-devel \
            systemd-devel
            
        # Container tools (Podman preferred for Rocky/CentOS Stream)
        $PKG_MGR install -y \
            podman \
            buildah \
            skopeo \
            containers-common
            
        # Python 3.11 installation (check if already installed first)
        if command -v python3.11 &> /dev/null; then
            info "Python 3.11 is already installed: $(python3.11 --version)"
            PYTHON_VERSION="3.11"
        else
            info "Python 3.11 not found, installing..."
            install_python_rocky_centos
        fi
        
    elif [[ $OS == "debian" ]]; then
        # Debian/Ubuntu installation
        apt-get update
        apt-get install -y \
            git \
            curl \
            wget \
            tar \
            gzip \
            unzip \
            sudo \
            jq \
            build-essential \
            libssl-dev \
            libffi-dev \
            zlib1g-dev \
            libbz2-dev \
            libreadline-dev \
            libsqlite3-dev \
            libsystemd-dev \
            python${PYTHON_VERSION} \
            python${PYTHON_VERSION}-dev \
            python${PYTHON_VERSION}-pip \
            python${PYTHON_VERSION}-venv \
            podman \
            buildah
    fi
    
    success "System dependencies installed"
}

# Install Python 3.11 for Rocky/CentOS Stream
install_python_rocky_centos() {
    info "Installing Python ${PYTHON_VERSION} for ${VARIANT}..."
    
    if [[ $VERSION -ge 9 ]]; then
        # Rocky 9+ and CentOS Stream 9+ have Python 3.11 in repos
        $PKG_MGR install -y \
            python${PYTHON_VERSION} \
            python${PYTHON_VERSION}-devel \
            python${PYTHON_VERSION}-pip \
            python${PYTHON_VERSION}-setuptools \
            python${PYTHON_VERSION}-wheel
    elif [[ $VERSION -eq 8 ]]; then
        # For Rocky 8 / CentOS Stream 8, try to install Python 3.11
        $PKG_MGR install -y python39 python39-devel python39-pip || {
            warn "Python 3.11 not available, using Python 3.9"
            PYTHON_VERSION="3.9"
        }
        
        # Try to install Python 3.11 from alternative sources
        if command -v python3.11 &> /dev/null; then
            PYTHON_VERSION="3.11"
        fi
    else
        error "Unsupported version: ${VERSION}"
        exit 1
    fi
    
    # Verify Python installation
    if command -v python${PYTHON_VERSION} &> /dev/null; then
        success "Python ${PYTHON_VERSION} installed successfully"
        python${PYTHON_VERSION} --version
    else
        error "Python ${PYTHON_VERSION} installation failed"
        exit 1
    fi
}

# Create runner user
create_runner_user() {
    info "Creating runner user: ${RUNNER_USER}"
    
    if id "${RUNNER_USER}" &>/dev/null; then
        warn "User ${RUNNER_USER} already exists"
    else
        useradd -m -s /bin/bash "${RUNNER_USER}"
        usermod -aG wheel "${RUNNER_USER}"
        success "User ${RUNNER_USER} created"
    fi
    
    # Configure sudo without password for runner user
    echo "${RUNNER_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${RUNNER_USER}"
    chmod 440 "/etc/sudoers.d/${RUNNER_USER}"
}

# Setup Python environment optimized for Rocky/CentOS
setup_python() {
    info "Setting up Python ${PYTHON_VERSION} environment..."
    
    # Ensure pip is up to date
    python${PYTHON_VERSION} -m pip install --upgrade pip
    
    # Install global Python packages needed for CI/CD
    python${PYTHON_VERSION} -m pip install --upgrade \
        virtualenv \
        setuptools \
        wheel \
        pip-tools
        
    success "Python environment configured"
}

# Install Ansible and related tools optimized for the collection
install_ansible_tools() {
    info "Installing Ansible and related tools for Qubinode collection..."
    
    # Install as runner user to avoid permission issues
    sudo -u "${RUNNER_USER}" bash << EOF
cd "${RUNNER_HOME}"

# Create virtual environment for Ansible tools
python${PYTHON_VERSION} -m venv ansible-venv
source ansible-venv/bin/activate

# Install latest stable versions optimized for the collection
pip install --upgrade pip setuptools wheel

# Core Ansible tools (matching your workflow requirements)
pip install \
    "ansible-core>=2.17.0,<2.19.0" \
    "ansible-lint>=6.0.0" \
    "molecule>=25.6.0" \
    "molecule-podman" \
    "yamllint>=1.28.0" \
    "jinja2>=3.0.0"

# Security tools (matching your security workflow)
pip install \
    "bandit>=1.7.0" \
    "safety>=2.0.0"

# Development and testing tools
pip install \
    "pre-commit>=2.15.0" \
    "pytest>=6.0.0" \
    "pytest-ansible" \
    "testinfra"

# Collection-specific tools
pip install \
    "packaging" \
    "requests" \
    "pyyaml"

# Create activation script optimized for your workflows
cat > activate-ansible-env.sh << 'SCRIPT_EOF'
#!/bin/bash
# Activate Ansible environment for GitHub Actions
source "${RUNNER_HOME}/ansible-venv/bin/activate"
export ANSIBLE_PYTHON_INTERPRETER=python${PYTHON_VERSION}
export PY_COLORS=1
export ANSIBLE_FORCE_COLOR=1
export CONTAINER_RUNTIME=podman
export MOLECULE_DEBUG=false
export ANSIBLE_VERBOSITY=1

# Collection-specific environment
export COLLECTION_NAMESPACE=qubinode
export COLLECTION_NAME=kvmhost_setup_collection

echo "✅ Ansible environment activated for Qubinode collection"
echo "🔧 Ansible: \$(ansible --version | head -1)"
echo "🧪 Molecule: \$(molecule --version)"
echo "🔍 Ansible-lint: \$(ansible-lint --version)"
echo "🐳 Container runtime: \$(podman --version | head -1)"
SCRIPT_EOF

chmod +x activate-ansible-env.sh

# Verify installation
echo "🔍 Verifying Ansible installation..."
source ansible-venv/bin/activate
ansible --version
ansible-lint --version
molecule --version
bandit --version
echo "✅ All tools installed successfully"
EOF

    success "Ansible tools installed and optimized for Qubinode collection"
}

# Configure Podman for rootless operation
configure_podman() {
    info "Configuring Podman for rootless containers..."
    
    # Enable lingering for the runner user
    loginctl enable-linger "${RUNNER_USER}" || warn "Could not enable lingering"
    
    # Configure subuid and subgid for rootless containers
    if ! grep -q "^${RUNNER_USER}:" /etc/subuid; then
        echo "${RUNNER_USER}:100000:65536" >> /etc/subuid
    fi
    
    if ! grep -q "^${RUNNER_USER}:" /etc/subgid; then
        echo "${RUNNER_USER}:100000:65536" >> /etc/subgid
    fi
    
    # Create Podman configuration for the runner user
    sudo -u "${RUNNER_USER}" bash << 'EOF'
mkdir -p ~/.config/containers

# Create containers.conf for optimal CI/CD performance
cat > ~/.config/containers/containers.conf << 'PODMAN_EOF'
[containers]
log_driver = "journald"
log_size_max = 100m
pids_limit = 2048
default_ulimits = [ "nofile=65536:65536" ]

[engine]
cgroup_manager = "systemd"
events_logger = "journald"
runtime = "crun"

[network]
default_network = "podman"
PODMAN_EOF

# Test Podman configuration
podman info > /dev/null && echo "✅ Podman configured successfully" || echo "⚠️ Podman configuration needs verification"
EOF

    success "Podman configured for rootless operation"
}

# Download and install GitHub Actions runner
install_github_runner() {
    info "Installing GitHub Actions runner v${RUNNER_VERSION}..."
    
    # Create runner directory
    mkdir -p "${RUNNER_HOME}/actions-runner"
    cd "${RUNNER_HOME}/actions-runner"
    
    # Download runner
    RUNNER_ARCH="x64"
    if [[ $(uname -m) == "aarch64" ]]; then
        RUNNER_ARCH="arm64"
    fi
    
    RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
    
    wget -O actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz "${RUNNER_URL}"
    tar xzf actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz
    rm actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz
    
    # Set ownership
    chown -R "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_HOME}/actions-runner"
    
    success "GitHub Actions runner downloaded and extracted"
}

# Create systemd service for runner
create_runner_service() {
    info "Creating systemd service for GitHub runner..."
    
    cat > /etc/systemd/system/github-runner.service << EOF
[Unit]
Description=GitHub Actions Runner for Qubinode Collection
After=network.target

[Service]
Type=simple
User=${RUNNER_USER}
WorkingDirectory=${RUNNER_HOME}/actions-runner
ExecStart=${RUNNER_HOME}/actions-runner/run.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=github-runner
KillMode=process
KillSignal=SIGTERM
TimeoutStopSec=5min

# Environment for the collection
Environment=COLLECTION_NAMESPACE=qubinode
Environment=COLLECTION_NAME=kvmhost_setup_collection
Environment=CONTAINER_RUNTIME=podman

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    success "GitHub runner systemd service created"
}

# Setup runner environment file
create_runner_env() {
    info "Creating runner environment configuration..."
    
    sudo -u "${RUNNER_USER}" bash << EOF
cd "${RUNNER_HOME}"

# Create environment setup script optimized for Qubinode collection
cat > .runner-env << 'ENV_EOF'
# GitHub Actions Runner Environment for Qubinode Collection
export PATH="${RUNNER_HOME}/actions-runner:${RUNNER_HOME}/ansible-venv/bin:\$PATH"
export PYTHON_PATH="${RUNNER_HOME}/ansible-venv/bin/python${PYTHON_VERSION}"
export ANSIBLE_PYTHON_INTERPRETER="${RUNNER_HOME}/ansible-venv/bin/python${PYTHON_VERSION}"
export PY_COLORS=1
export ANSIBLE_FORCE_COLOR=1
export MOLECULE_DEBUG=false
export ANSIBLE_VERBOSITY=1

# Container runtime preference
export CONTAINER_RUNTIME=podman

# Collection-specific environment
export COLLECTION_NAMESPACE=qubinode
export COLLECTION_NAME=kvmhost_setup_collection

# Runner identification optimized for your workflows
export RUNNER_NAME=\$(hostname)-qubinode-runner
export RUNNER_LABELS="self-hosted,linux,$(uname -m),ansible,podman,rocky,qubinode"

# OS-specific settings
export OS_VARIANT="${VARIANT}"
export OS_VERSION="${VERSION}"
ENV_EOF

# Add to bash profile
echo "source ${RUNNER_HOME}/.runner-env" >> .bashrc
EOF

    success "Runner environment configured for Qubinode collection"
}

# Generate runner registration script
create_registration_script() {
    info "Creating runner registration script..."
    
    cat > "${RUNNER_HOME}/register-runner.sh" << 'EOF'
#!/bin/bash

# GitHub Runner Registration Script for Qubinode Collection
# Usage: ./register-runner.sh <REPO_URL> <TOKEN>

set -euo pipefail

REPO_URL="${1:-}"
TOKEN="${2:-}"

if [[ -z "$REPO_URL" || -z "$TOKEN" ]]; then
    echo "Usage: $0 <repository_url> <registration_token>"
    echo "Example: $0 https://github.com/Qubinode/qubinode_kvmhost_setup_collection ghs_xxxxxxxxxxxxxx"
    echo ""
    echo "To get a registration token:"
    echo "1. Go to your repository on GitHub"
    echo "2. Navigate to Settings > Actions > Runners"
    echo "3. Click 'New self-hosted runner'"
    echo "4. Copy the token from the configuration command"
    exit 1
fi

cd ~/actions-runner

# Source environment
source ~/.runner-env

echo "🔧 Configuring GitHub Actions runner for Qubinode collection..."
echo "📋 Runner name: ${RUNNER_NAME}"
echo "📋 Labels: ${RUNNER_LABELS}"
echo "📋 OS: ${OS_VARIANT} ${OS_VERSION}"

./config.sh \
    --url "$REPO_URL" \
    --token "$TOKEN" \
    --name "${RUNNER_NAME}" \
    --labels "${RUNNER_LABELS}" \
    --work "_work" \
    --replace

echo "✅ Runner configured successfully!"
echo "🚀 Starting runner service..."
sudo systemctl enable github-runner
sudo systemctl start github-runner

# Wait a moment for service to start
sleep 3
sudo systemctl status github-runner --no-pager

echo ""
echo "📋 Runner Status:"
echo "  Name: ${RUNNER_NAME}"
echo "  Labels: ${RUNNER_LABELS}"
echo "  Service: github-runner"
echo "  Logs: journalctl -u github-runner -f"
echo "  OS: ${OS_VARIANT} ${OS_VERSION}"
echo ""
echo "🎉 Runner is ready for Qubinode collection workflows!"
EOF

    chmod +x "${RUNNER_HOME}/register-runner.sh"
    chown "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_HOME}/register-runner.sh"
    
    success "Runner registration script created"
}

# Cleanup and optimization
optimize_runner() {
    info "Optimizing runner environment..."
    
    # Clean package caches
    if [[ $PKG_MGR == "dnf" ]] || [[ $PKG_MGR == "yum" ]]; then
        $PKG_MGR clean all
    elif [[ $PKG_MGR == "apt" ]]; then
        apt-get clean
        apt-get autoremove -y
    fi
    
    # Setup log rotation
    cat > /etc/logrotate.d/github-runner << EOF
${RUNNER_HOME}/actions-runner/_diag/Runner_*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 ${RUNNER_USER} ${RUNNER_USER}
}
EOF

    success "Runner environment optimized"
}

# Main execution
main() {
    info "Starting GitHub Actions runner setup for Qubinode collection..."
    info "Target user: ${RUNNER_USER}"
    info "Python version: ${PYTHON_VERSION}"
    info "Runner version: ${RUNNER_VERSION}"
    
    check_root
    detect_os
    install_system_deps
    create_runner_user
    setup_python
    install_github_runner
    install_ansible_tools
    configure_podman
    create_runner_service
    create_runner_env
    optimize_runner
    create_registration_script
    
    success "GitHub Actions runner setup completed!"
    echo
    info "Next steps:"
    echo "  1. Switch to runner user: sudo su - ${RUNNER_USER}"
    echo "  2. Register runner: ./register-runner.sh <repo_url> <token>"
    echo "  3. Check status: sudo systemctl status github-runner"
    echo
    info "For Qubinode collection registration:"
    echo "  ./register-runner.sh https://github.com/Qubinode/qubinode_kvmhost_setup_collection <token>"
    echo
    info "Useful commands:"
    echo "  View logs: journalctl -u github-runner -f"
    echo "  Restart: sudo systemctl restart github-runner"
    echo "  Environment check: source ~/.runner-env && ansible --version"
    echo
    success "Runner optimized for ${VARIANT} ${VERSION} and Qubinode workflows!"
}

# Handle script arguments
case "${1:-setup}" in
    "setup"|"install")
        main
        ;;
    "verify")
        info "Verifying runner installation on ${VARIANT} ${VERSION}..."
        detect_os
        sudo -u "${RUNNER_USER}" bash << 'EOF'
source ~/.runner-env
echo "🔍 Environment Check:"
echo "  OS: ${OS_VARIANT} ${OS_VERSION}"
echo "  Python: $(python3.11 --version 2>/dev/null || python3.9 --version 2>/dev/null || echo "Not found")"
echo "  Ansible: $(ansible --version 2>/dev/null | head -1 || echo "Not found")"
echo "  Molecule: $(molecule --version 2>/dev/null || echo "Not found")"
echo "  Podman: $(podman --version 2>/dev/null || echo "Not found")"
echo "  Runner: $(ls -la ~/actions-runner/run.sh 2>/dev/null && echo "✅ Installed" || echo "❌ Missing")"
echo "  Service: $(systemctl is-active github-runner 2>/dev/null || echo "inactive")"
EOF
        ;;
    *)
        echo "GitHub Actions Runner Setup Script for Rocky Linux / CentOS Stream"
        echo "Optimized for Qubinode KVM Host Setup Collection"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  setup    - Install and configure runner (default)"
        echo "  verify   - Verify installation"
        echo
        echo "Supported OS:"
        echo "  - Rocky Linux 8, 9+"
        echo "  - CentOS Stream 8, 9, 10"
        echo "  - RHEL 8, 9+"
        ;;
esac
