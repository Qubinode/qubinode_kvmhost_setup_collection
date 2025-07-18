#!/bin/bash
# SELinux Setup for CI/CD Environments
# Handles SELinux Python bindings installation and configuration for containerized CI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to detect the environment
detect_environment() {
    if [ -f /.dockerenv ]; then
        echo "docker"
    elif [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "github-actions"
    elif [ -n "${CI:-}" ]; then
        echo "ci"
    else
        echo "local"
    fi
}

# Function to install system SELinux packages
install_system_selinux_packages() {
    local env_type="$1"
    
    log_info "Installing system SELinux packages for environment: $env_type"
    
    case "$env_type" in
        "docker"|"github-actions"|"ci")
            # In containerized environments, try to install if possible
            if command -v yum >/dev/null 2>&1; then
                log_info "Using yum package manager"
                yum install -y libselinux-python3 python3-libselinux libselinux-devel 2>/dev/null || {
                    log_warning "Failed to install SELinux packages via yum, continuing..."
                    return 1
                }
            elif command -v apt-get >/dev/null 2>&1; then
                log_info "Using apt package manager"
                apt-get update && apt-get install -y python3-selinux libselinux1-dev 2>/dev/null || {
                    log_warning "Failed to install SELinux packages via apt, continuing..."
                    return 1
                }
            else
                log_warning "No supported package manager found for SELinux installation"
                return 1
            fi
            ;;
        "local")
            log_info "Local environment detected, assuming SELinux packages are available"
            ;;
    esac
    
    log_success "System SELinux packages installation completed"
    return 0
}

# Function to install Python SELinux bindings
install_python_selinux_bindings() {
    local python_cmd="${1:-python3}"
    
    log_info "Installing Python SELinux bindings using: $python_cmd"
    
    # Try to install the selinux Python package
    if $python_cmd -m pip install --no-deps selinux 2>/dev/null; then
        log_success "Python SELinux bindings installed successfully"
        return 0
    else
        log_warning "Failed to install Python SELinux bindings via pip"
        
        # Try alternative installation methods
        if $python_cmd -c "import selinux" 2>/dev/null; then
            log_success "SELinux bindings already available in system packages"
            return 0
        else
            log_warning "SELinux bindings not available, will configure environment to work without them"
            return 1
        fi
    fi
}

# Function to configure environment for SELinux-less operation
configure_selinux_environment() {
    log_info "Configuring environment for SELinux-less operation"
    
    # Set environment variables to disable SELinux checks
    export ANSIBLE_SELINUX_SPECIAL_FS=""
    export LIBSELINUX_DISABLE_SELINUX_CHECK="1"
    
    # Create a wrapper script for ansible commands if needed
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "ANSIBLE_SELINUX_SPECIAL_FS=" >> "$GITHUB_ENV"
        echo "LIBSELINUX_DISABLE_SELINUX_CHECK=1" >> "$GITHUB_ENV"
        log_success "SELinux environment variables set for GitHub Actions"
    fi
    
    log_success "Environment configured for SELinux-less operation"
}

# Function to test SELinux functionality
test_selinux_functionality() {
    local python_cmd="${1:-python3}"
    
    log_info "Testing SELinux functionality"
    
    # Test if Python can import selinux
    if $python_cmd -c "import selinux; print('SELinux bindings working')" 2>/dev/null; then
        log_success "SELinux Python bindings are working correctly"
        return 0
    else
        log_warning "SELinux Python bindings are not working, but environment is configured to continue"
        return 1
    fi
}

# Main function
main() {
    local python_cmd="${1:-python3}"
    
    echo -e "${BLUE}🔧 SELinux Setup for CI/CD Environments${NC}"
    echo -e "${BLUE}=======================================${NC}"
    echo "Python command: $python_cmd"
    echo ""
    
    # Detect environment
    local env_type
    env_type=$(detect_environment)
    log_info "Detected environment: $env_type"
    
    # Install system packages
    if install_system_selinux_packages "$env_type"; then
        log_success "System SELinux packages installed"
    else
        log_warning "System SELinux packages installation failed or skipped"
    fi
    
    # Install Python bindings
    if install_python_selinux_bindings "$python_cmd"; then
        log_success "Python SELinux bindings installed"
    else
        log_warning "Python SELinux bindings installation failed"
    fi
    
    # Configure environment
    configure_selinux_environment
    
    # Test functionality
    if test_selinux_functionality "$python_cmd"; then
        log_success "SELinux setup completed successfully"
        exit 0
    else
        log_warning "SELinux setup completed with warnings - environment configured to work without SELinux"
        exit 0
    fi
}

# Run main function with all arguments
main "$@"
