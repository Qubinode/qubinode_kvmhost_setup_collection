#!/bin/bash

# =============================================================================
# Generic Runner Setup Assistant - The "Universal Infrastructure Builder"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script provides generic GitHub Actions self-hosted runner setup
# with complete CI/CD pipeline dependencies for Ansible collection testing.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Universal Setup - Provides generic runner setup for multiple platforms
# 2. [PHASE 2]: Dependency Installation - Installs all required CI/CD dependencies
# 3. [PHASE 3]: Environment Configuration - Configures complete testing environment
# 4. [PHASE 4]: Runner Registration - Prepares runner for GitHub Actions registration
# 5. [PHASE 5]: Service Setup - Configures runner as system service
# 6. [PHASE 6]: Validation - Validates complete runner setup functionality
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Provides: Generic alternative to setup-github-runner-rocky.sh
# - Supports: Multiple Linux distributions with unified setup approach
# - Creates: Complete CI/CD environment for Ansible collection testing
# - Installs: All dependencies needed for collection testing pipeline
# - Configures: Runner environment for optimal collection testing performance
# - Complements: Platform-specific setup scripts with generic capabilities
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - UNIVERSAL: Works across multiple Linux distributions and platforms
# - COMPREHENSIVE: Installs complete CI/CD dependency stack
# - GENERIC: Provides platform-agnostic setup capabilities
# - COMPLETE: Creates fully functional runner environment
# - CONFIGURABLE: Supports customization through environment variables
# - ALTERNATIVE: Provides fallback when platform-specific scripts aren't suitable
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - Platform Support: Add support for new Linux distributions
# - Dependencies: Add new CI/CD dependencies or tools
# - Configuration: Enhance configuration options and customization
# - Integration: Add integration with new CI/CD platforms
# - Performance: Optimize setup process for faster deployment
# - Validation: Add new validation checks for setup completeness
#
# 🚨 IMPORTANT FOR LLMs: This is a generic setup script. For RHEL-based
# systems, prefer setup-github-runner-rocky.sh which includes platform-specific
# optimizations and configurations.

# GitHub Self-Hosted Runner Setup Script
# This script sets up a complete environment for GitHub Actions self-hosted runners
# with all dependencies needed for the Ansible collection CI/CD pipeline

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/github-runner-setup.log"
RUNNER_USER="${RUNNER_USER:-github-runner}"
RUNNER_HOME="/home/${RUNNER_USER}"
RUNNER_VERSION="${RUNNER_VERSION:-2.317.0}"  # Latest stable version
PYTHON_VERSION="3.11"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Detect OS and version
detect_os() {
    if [[ -f /etc/redhat-release ]]; then
        OS="rhel"
        VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -1)
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
        VERSION=$(cat /etc/debian_version | cut -d. -f1)
    else
        error "Unsupported operating system"
        exit 1
    fi
    info "Detected OS: ${OS} ${VERSION}"
}

# Install system dependencies
install_system_deps() {
    info "Installing system dependencies..."
    
    if [[ $OS == "rhel" ]]; then
        # Update system
        yum update -y
        
        # Install EPEL repository
        yum install -y epel-release
        
        # Install development tools and dependencies
        yum groupinstall -y "Development Tools"
        yum install -y \
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
            systemd-devel \
            container-tools \
            podman \
            buildah \
            skopeo
            
        # Install Python 3.11 and related packages
        yum install -y \
            python${PYTHON_VERSION} \
            python${PYTHON_VERSION}-devel \
            python${PYTHON_VERSION}-pip \
            python${PYTHON_VERSION}-setuptools \
            python${PYTHON_VERSION}-wheel
            
    elif [[ $OS == "debian" ]]; then
        # Update package list
        apt-get update
        
        # Install dependencies
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

# Create runner user
create_runner_user() {
    info "Creating runner user: ${RUNNER_USER}"
    
    if id "${RUNNER_USER}" &>/dev/null; then
        warn "User ${RUNNER_USER} already exists"
    else
        useradd -m -s /bin/bash "${RUNNER_USER}"
        usermod -aG wheel "${RUNNER_USER}" 2>/dev/null || usermod -aG sudo "${RUNNER_USER}" 2>/dev/null
        success "User ${RUNNER_USER} created"
    fi
    
    # Configure sudo without password for runner user
    echo "${RUNNER_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${RUNNER_USER}"
    chmod 440 "/etc/sudoers.d/${RUNNER_USER}"
}

# Setup Python environment
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

# Install Docker (alternative to Podman for some scenarios)
install_docker() {
    info "Installing Docker..."
    
    if command -v docker &> /dev/null; then
        warn "Docker already installed"
        return
    fi
    
    if [[ $OS == "rhel" ]]; then
        # Install Docker CE repository
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    elif [[ $OS == "debian" ]]; then
        # Install Docker CE
        apt-get install -y ca-certificates gnupg lsb-release
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    fi
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add runner user to docker group
    usermod -aG docker "${RUNNER_USER}"
    
    success "Docker installed and configured"
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

# Install Ansible and related tools
install_ansible_tools() {
    info "Installing Ansible and related tools..."
    
    # Install as runner user to avoid permission issues
    sudo -u "${RUNNER_USER}" bash << EOF
cd "${RUNNER_HOME}"

# Create virtual environment for Ansible tools
python${PYTHON_VERSION} -m venv ansible-venv
source ansible-venv/bin/activate

# Install latest stable versions
pip install --upgrade pip setuptools wheel

# Core Ansible tools
pip install \
    "ansible-core>=2.17.0,<2.19.0" \
    "ansible-lint>=6.0.0" \
    "molecule>=25.6.0" \
    "molecule-podman" \
    "yamllint>=1.28.0" \
    "jinja2>=3.0.0"

# Security tools
pip install \
    "bandit>=1.7.0" \
    "safety>=2.0.0"

# Development tools
pip install \
    "pre-commit>=2.15.0" \
    "black" \
    "isort" \
    "flake8"

# Test and validation tools
pip install \
    "pytest>=6.0.0" \
    "pytest-ansible" \
    "testinfra"

# Create activation script
cat > activate-ansible-env.sh << 'SCRIPT_EOF'
#!/bin/bash
# Activate Ansible environment for GitHub Actions
source "${RUNNER_HOME}/ansible-venv/bin/activate"
export ANSIBLE_PYTHON_INTERPRETER=python${PYTHON_VERSION}
export PY_COLORS=1
export ANSIBLE_FORCE_COLOR=1
echo "✅ Ansible environment activated"
ansible --version
ansible-lint --version
molecule --version
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

    success "Ansible tools installed in virtual environment"
}

# Configure systemd service for runner
create_runner_service() {
    info "Creating systemd service for GitHub runner..."
    
    cat > /etc/systemd/system/github-runner.service << EOF
[Unit]
Description=GitHub Actions Runner
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

# Create environment setup script
cat > .runner-env << 'ENV_EOF'
# GitHub Actions Runner Environment
export PATH="${RUNNER_HOME}/actions-runner:${RUNNER_HOME}/ansible-venv/bin:\$PATH"
export PYTHON_PATH="${RUNNER_HOME}/ansible-venv/bin/python${PYTHON_VERSION}"
export ANSIBLE_PYTHON_INTERPRETER="${RUNNER_HOME}/ansible-venv/bin/python${PYTHON_VERSION}"
export PY_COLORS=1
export ANSIBLE_FORCE_COLOR=1
export MOLECULE_DEBUG=false
export ANSIBLE_VERBOSITY=1

# Container runtime preference
export CONTAINER_RUNTIME=podman

# Runner identification
export RUNNER_NAME=\$(hostname)-runner
export RUNNER_LABELS="self-hosted,linux,$(uname -m),ansible,podman"
ENV_EOF

# Add to bash profile
echo "source ${RUNNER_HOME}/.runner-env" >> .bashrc
EOF

    success "Runner environment configured"
}

# Cleanup and optimization
optimize_runner() {
    info "Optimizing runner environment..."
    
    # Clean package caches
    if [[ $OS == "rhel" ]]; then
        yum clean all
    elif [[ $OS == "debian" ]]; then
        apt-get clean
        apt-get autoremove -y
    fi
    
    # Setup log rotation for runner logs
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

# Generate runner registration script
create_registration_script() {
    info "Creating runner registration script..."
    
    cat > "${RUNNER_HOME}/register-runner.sh" << 'EOF'
#!/bin/bash

# GitHub Runner Registration Script
# Usage: ./register-runner.sh <REPO_URL> <TOKEN>

set -euo pipefail

REPO_URL="${1:-}"
TOKEN="${2:-}"

if [[ -z "$REPO_URL" || -z "$TOKEN" ]]; then
    echo "Usage: $0 <repository_url> <registration_token>"
    echo "Example: $0 https://github.com/owner/repo ghs_xxxxxxxxxxxxxx"
    exit 1
fi

cd ~/actions-runner

# Source environment
source ~/.runner-env

echo "🔧 Configuring GitHub Actions runner..."
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
sudo systemctl status github-runner

echo "📋 Runner Status:"
echo "  Name: ${RUNNER_NAME}"
echo "  Labels: ${RUNNER_LABELS}"
echo "  Service: github-runner"
echo "  Logs: journalctl -u github-runner -f"
EOF

    chmod +x "${RUNNER_HOME}/register-runner.sh"
    chown "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_HOME}/register-runner.sh"
    
    success "Runner registration script created at ${RUNNER_HOME}/register-runner.sh"
}

# Generate uninstall script
create_uninstall_script() {
    info "Creating uninstall script..."
    
    cat > "${RUNNER_HOME}/uninstall-runner.sh" << EOF
#!/bin/bash

# GitHub Runner Uninstall Script
set -euo pipefail

echo "🗑️  Uninstalling GitHub Actions runner..."

# Stop and disable service
sudo systemctl stop github-runner 2>/dev/null || true
sudo systemctl disable github-runner 2>/dev/null || true

# Remove runner
cd ~/actions-runner
./config.sh remove --token "\${1:-}" 2>/dev/null || echo "⚠️  Manual token required for complete removal"

echo "✅ Runner uninstalled"
EOF

    chmod +x "${RUNNER_HOME}/uninstall-runner.sh"
    chown "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_HOME}/uninstall-runner.sh"
    
    success "Uninstall script created at ${RUNNER_HOME}/uninstall-runner.sh"
}

# Main execution
main() {
    info "Starting GitHub Actions runner setup..."
    info "Target user: ${RUNNER_USER}"
    info "Python version: ${PYTHON_VERSION}"
    info "Runner version: ${RUNNER_VERSION}"
    
    check_root
    detect_os
    install_system_deps
    create_runner_user
    setup_python
    install_docker
    install_github_runner
    install_ansible_tools
    create_runner_service
    create_runner_env
    optimize_runner
    create_registration_script
    create_uninstall_script
    
    success "GitHub Actions runner setup completed!"
    echo
    info "Next steps:"
    echo "  1. Switch to runner user: sudo su - ${RUNNER_USER}"
    echo "  2. Register runner: ./register-runner.sh <repo_url> <token>"
    echo "  3. Check status: sudo systemctl status github-runner"
    echo
    info "Useful commands:"
    echo "  View logs: journalctl -u github-runner -f"
    echo "  Restart: sudo systemctl restart github-runner"
    echo "  Uninstall: ./uninstall-runner.sh <token>"
    echo
    warn "Remember to:"
    echo "  - Generate a runner registration token from GitHub"
    echo "  - Configure firewall rules if needed"
    echo "  - Set up monitoring for the runner service"
}

# Handle script arguments
case "${1:-setup}" in
    "setup"|"install")
        main
        ;;
    "verify")
        info "Verifying runner installation..."
        sudo -u "${RUNNER_USER}" bash << 'EOF'
source ~/.runner-env
echo "🔍 Environment Check:"
echo "  Python: $(python3.11 --version)"
echo "  Ansible: $(ansible --version | head -1)"
echo "  Molecule: $(molecule --version)"
echo "  Podman: $(podman --version)"
echo "  Runner: $(ls -la ~/actions-runner/run.sh 2>/dev/null && echo "✅ Installed" || echo "❌ Missing")"
echo "  Service: $(systemctl is-active github-runner 2>/dev/null || echo "inactive")"
EOF
        ;;
    "status")
        systemctl status github-runner
        ;;
    "logs")
        journalctl -u github-runner -f
        ;;
    "help"|"-h"|"--help")
        echo "GitHub Actions Runner Setup Script"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  setup    - Install and configure runner (default)"
        echo "  verify   - Verify installation"
        echo "  status   - Show runner service status"
        echo "  logs     - Show runner logs"
        echo "  help     - Show this help"
        echo
        echo "Environment Variables:"
        echo "  RUNNER_USER     - Runner username (default: github-runner)"
        echo "  RUNNER_VERSION  - Runner version (default: 2.317.0)"
        echo "  PYTHON_VERSION  - Python version (default: 3.11)"
        ;;
    *)
        error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
