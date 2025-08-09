#!/bin/bash

# =============================================================================
# Local Testing Environment Setup - The "Construction Manager"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script is the primary environment setup orchestrator that prepares a complete
# local development environment for Ansible collection testing with Molecule.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Environment Detection - Identifies OS, package manager, and existing tools
# 2. [PHASE 2]: Dependency Installation - Sets up Python 3.11, virtual environments, and core tools
# 3. [PHASE 3]: Molecule Configuration - Installs and configures Molecule with Podman integration
# 4. [PHASE 4]: Validation Setup - Creates activation scripts and runs compliance checks
# 5. [PHASE 5]: Integration Testing - Validates the complete testing pipeline
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Creates: Virtual environment at ~/.local/molecule-env for isolated testing
# - Generates: scripts/activate-molecule-env.sh for easy environment activation
# - Enables: Local execution of scripts/test-local-molecule.sh and other testing scripts
# - Validates: ADR-0011 compliance for mandatory local testing requirements
# - Integrates: With CI/CD pipeline by ensuring local environment matches GitHub Actions
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - ISOLATION: Uses virtual environments to prevent system-wide dependency conflicts
# - COMPATIBILITY: Targets Python 3.11 + Ansible-core 2.18+ for RHEL 9/SELinux compatibility
# - SECURITY: Prefers Podman over Docker for rootless container operations
# - COMPLIANCE: Enforces ADR-0011 mandatory local testing before CI/CD execution
# - REPRODUCIBILITY: Creates identical environments across different developer machines
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - Version Updates: Change PYTHON_VERSION, ANSIBLE_CORE_VERSION, or MOLECULE_VERSION constants
# - New Dependencies: Add pip install commands in install_python_deps() function
# - OS Support: Extend detect_os() function for new Linux distributions
# - Validation Rules: Update test_setup() function for new compliance requirements
# - Integration Points: Modify create_activation_script() for new environment variables
#
# 🚨 IMPORTANT FOR LLMs: This script creates the foundation for ALL local testing.
# Changes here affect every developer's environment and CI/CD pipeline compatibility.
# Always test changes with scripts/test-dependencies.sh before committing.

# Environment Setup Script for Local Molecule Testing
# Based on ADR-0011 and research findings

set -e

echo "🔧 Local Molecule Testing Environment Setup"
echo "=========================================="
echo "📋 This script sets up your local environment for mandatory testing compliance"
echo ""

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo "⚠️  Warning: Running as root. Consider using a virtual environment."
        echo "   Recommended: python3 -m venv ~/.local/molecule-env"
        echo "               source ~/.local/molecule-env/bin/activate"
        return 1
    fi
    return 0
}

# Function to detect OS and package manager
detect_os() {
    if [ -f /etc/redhat-release ]; then
        echo "🐧 Detected: Red Hat Enterprise Linux / Rocky / AlmaLinux"
        OS_TYPE="rhel"
        PKG_MANAGER="dnf"
    elif [ -f /etc/debian_version ]; then
        echo "🐧 Detected: Debian / Ubuntu"
        OS_TYPE="debian"
        PKG_MANAGER="apt"
    else
        echo "🐧 OS detection failed, assuming RHEL-compatible"
        OS_TYPE="rhel"
        PKG_MANAGER="dnf"
    fi
}

# Function to install system dependencies
install_system_deps() {
    echo ""
    echo "📦 Installing system dependencies..."
    
    if [[ "$OS_TYPE" == "rhel" ]]; then
        echo "   Installing Python 3.11, pip, and development tools..."
        if command -v dnf &> /dev/null; then
            sudo dnf install -y python3.11 python3.11-pip python3.11-devel gcc
        else
            sudo yum install -y python3.11 python3.11-pip python3.11-devel gcc
        fi
    elif [[ "$OS_TYPE" == "debian" ]]; then
        echo "   Installing Python 3.11, pip, and development tools..."
        sudo apt update
        sudo apt install -y python3.11 python3.11-pip python3.11-dev build-essential
    fi
    
    echo "✅ System dependencies installed"
}

# Function to setup Python virtual environment
setup_venv() {
    echo ""
    echo "🐍 Setting up Python virtual environment..."
    
    VENV_PATH="$HOME/.local/molecule-env"
    
    if [ -d "$VENV_PATH" ]; then
        echo "   Virtual environment already exists at $VENV_PATH"
    else
        echo "   Creating virtual environment at $VENV_PATH"
        python3.11 -m venv "$VENV_PATH" || python3 -m venv "$VENV_PATH"
    fi
    
    echo "   Activating virtual environment..."
    source "$VENV_PATH/bin/activate"
    
    echo "   Upgrading pip..."
    pip install --upgrade pip
    
    echo "✅ Virtual environment ready"
}

# Function to install Python dependencies
install_python_deps() {
    echo ""
    echo "📦 Installing Python dependencies..."
    echo "   Based on research recommendations: Molecule 25.6.0+, Ansible-core 2.18+ (fixes SELinux issues)"
    
    # Install dependencies based on research findings - use 2.18+ for Python 3.11 + SELinux compatibility
    pip install "ansible-core>=2.18.0,<2.19.0"
    pip install "molecule>=25.6.0"
    pip install "molecule-plugins[docker]"
    pip install "pytest-testinfra"
    
    # Additional useful tools
    pip install "yamllint"
    pip install "ansible-lint"
    
    echo "✅ Python dependencies installed"
}

# Function to verify installation
verify_installation() {
    echo ""
    echo "🔍 Verifying installation..."
    
    echo "   Python version: $(python --version)"
    echo "   Ansible version: $(ansible --version | head -1)"
    echo "   Molecule version: $(molecule --version | head -1)"
    
    echo "✅ Installation verified"
}

# Function to create activation script
create_activation_script() {
    echo ""
    echo "🔧 Creating activation script..."
    
    cat > "scripts/activate-molecule-env.sh" << 'EOF'
#!/bin/bash
# Activate Molecule testing environment
# Usage: source scripts/activate-molecule-env.sh

VENV_PATH="$HOME/.local/molecule-env"

if [ -d "$VENV_PATH" ]; then
    echo "🐍 Activating Molecule testing environment..."
    source "$VENV_PATH/bin/activate"
    echo "✅ Environment activated"
    echo "💡 Ready to run: ./scripts/test-local-molecule.sh"
else
    echo "❌ Virtual environment not found"
    echo "💡 Run: ./scripts/setup-local-testing.sh"
    return 1
fi
EOF
    
    chmod +x "scripts/activate-molecule-env.sh"
    echo "✅ Activation script created: scripts/activate-molecule-env.sh"
}

# Function to test the setup
test_setup() {
    echo ""
    echo "🧪 Testing the setup..."
    
    if ./scripts/check-compliance.sh; then
        echo ""
        echo "🎉 Setup completed successfully!"
        echo "✅ Environment is ready for local Molecule testing"
        echo ""
        echo "💡 Next steps:"
        echo "   1. Run: source scripts/activate-molecule-env.sh"
        echo "   2. Test: ./scripts/test-local-molecule.sh"
        echo "   3. Activate pre-commit: cp .git/hooks/pre-commit.example .git/hooks/pre-commit"
    else
        echo ""
        echo "❌ Setup verification failed"
        echo "💡 Check the errors above and run the script again"
        return 1
    fi
}

# Main execution
main() {
    echo "🔍 Checking current environment..."
    
    detect_os
    
    # Check if already in a virtual environment
    if [[ "$VIRTUAL_ENV" != "" ]]; then
        echo "✅ Already in virtual environment: $VIRTUAL_ENV"
        install_python_deps
        verify_installation
        create_activation_script
        test_setup
        return 0
    fi
    
    # Ask user if they want to install system dependencies
    read -p "🤔 Install system dependencies (Python 3.11, development tools)? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_system_deps
    else
        echo "ℹ️  Skipping system dependencies. Ensure Python 3.11+ is available."
    fi
    
    setup_venv
    install_python_deps
    verify_installation
    create_activation_script
    test_setup
    
    echo ""
    echo "🎯 Summary:"
    echo "   ✅ Environment setup complete"
    echo "   ✅ Molecule testing ready"
    echo "   ✅ ADR-0011 compliance achievable"
    echo ""
    echo "🚀 To activate environment: source scripts/activate-molecule-env.sh"
}

# Run main function
main "$@"
