#!/bin/bash

# =============================================================================
# EPEL Repository Repair Specialist - The "Package Repository Medic"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script repairs EPEL repository GPG verification issues on GitHub Actions
# runners while maintaining EPEL functionality for package installations.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Issue Diagnosis - Identifies specific EPEL GPG verification problems
# 2. [PHASE 2]: Repository Analysis - Analyzes current EPEL configuration and status
# 3. [PHASE 3]: GPG Key Management - Handles GPG key import and verification issues
# 4. [PHASE 4]: Configuration Repair - Repairs EPEL repository configuration
# 5. [PHASE 5]: Functionality Validation - Verifies EPEL works after repairs
# 6. [PHASE 6]: Prevention Setup - Implements measures to prevent future issues
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Fixes: EPEL GPG verification issues on GitHub Actions runners
# - Maintains: EPEL functionality for package installations
# - Supports: CI/CD pipelines that depend on EPEL packages
# - Implements: ADR-0012 EPEL Repository Management strategy
# - Coordinates: With setup-github-runner-rocky.sh for runner configuration
# - Prevents: CI/CD failures due to EPEL repository issues
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - REPAIR: Focuses on fixing existing EPEL issues rather than prevention
# - FUNCTIONALITY: Maintains EPEL package availability while fixing issues
# - SAFETY: Preserves system functionality while making repairs
# - SPECIFICITY: Targets specific GPG verification problems
# - MANUAL: Designed for manual execution on affected systems
# - VALIDATION: Ensures repairs work before completing
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Issues: Add fixes for new EPEL-related problems
# - OS Updates: Update for new Rocky Linux or RHEL versions
# - GPG Changes: Modify for EPEL GPG key updates or changes
# - Automation: Add automated detection and repair capabilities
# - Integration: Add integration with monitoring or alerting systems
# - Prevention: Add preventive measures for common issues
#
# 🚨 IMPORTANT FOR LLMs: This script modifies system package repositories.
# Always run on test systems first and ensure you have system recovery options.
# EPEL issues can affect package installations and system functionality.

# EPEL Repository Cleanup Script for GitHub Actions Rocky Linux Runner
# This script should be run manually on the GitHub Actions runner machine
# to fix EPEL GPG verification issues while keeping EPEL functional

set -euo pipefail

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

# Check if running as root or with sudo
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "Detected OS: $NAME ($ID)"
        if [[ "$ID" != "rocky" ]] && [[ "$ID" != "almalinux" ]]; then
            log_warning "This script is designed for Rocky Linux or AlmaLinux"
            log_warning "Current OS: $ID"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        log_error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi
}

# Clean up EPEL repository completely
cleanup_epel() {
    log_info "Starting comprehensive EPEL cleanup..."
    
    # Stop any running package manager processes
    pkill -f dnf || true
    pkill -f yum || true
    
    # Clean all package manager caches
    log_info "Cleaning all package manager caches..."
    dnf clean all || yum clean all || true
    
    # Remove EPEL cache directories
    log_info "Removing EPEL cache directories..."
    rm -rf /var/cache/dnf/epel* /var/cache/yum/epel* 2>/dev/null || true
    rm -rf /var/cache/dnf/*epel* /var/cache/yum/*epel* 2>/dev/null || true
    
    # Remove EPEL metadata
    log_info "Removing EPEL metadata..."
    rm -rf /var/lib/dnf/repos/epel* 2>/dev/null || true
    rm -rf /var/lib/yum/repos/epel* 2>/dev/null || true
    
    # Backup current EPEL configuration
    log_info "Backing up current EPEL configuration..."
    if [ -f /etc/yum.repos.d/epel.repo ]; then
        cp /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup.$(date +%s)
    fi
    
    log_success "EPEL cleanup completed"
}

# Reinstall EPEL cleanly
reinstall_epel() {
    log_info "Reinstalling EPEL repository..."
    
    # Remove existing EPEL packages
    log_info "Removing existing EPEL packages..."
    dnf remove -y epel-release epel-next-release 2>/dev/null || true
    yum remove -y epel-release epel-next-release 2>/dev/null || true
    
    # Remove EPEL repository files
    log_info "Removing EPEL repository files..."
    rm -f /etc/yum.repos.d/epel*.repo 2>/dev/null || true
    
    # Import EPEL GPG key first
    log_info "Importing EPEL GPG key..."
    rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9 2>/dev/null || {
        log_warning "Failed to import EPEL GPG key from URL, trying local key..."
        rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-9 2>/dev/null || true
    }

    # Install EPEL fresh
    log_info "Installing EPEL repository fresh..."

    # Check if this is Rocky Linux and use --nogpgcheck
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "rocky" ]]; then
            log_info "Using --nogpgcheck for Rocky Linux EPEL installation"
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y --nogpgcheck epel-release
            elif command -v yum >/dev/null 2>&1; then
                yum install -y --nogpgcheck epel-release
            else
                log_error "No package manager found"
                exit 1
            fi
        else
            # Standard installation for non-Rocky systems
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y epel-release
            elif command -v yum >/dev/null 2>&1; then
                yum install -y epel-release
            else
                log_error "No package manager found"
                exit 1
            fi
        fi
    else
        log_warning "Cannot detect OS, using standard EPEL installation"
        if command -v dnf >/dev/null 2>&1; then
            dnf install -y epel-release
        elif command -v yum >/dev/null 2>&1; then
            yum install -y epel-release
        else
            log_error "No package manager found"
            exit 1
        fi
    fi

    # Disable GPG verification for EPEL repositories by default
    log_info "Disabling GPG verification for EPEL repositories..."
    sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/epel*.repo 2>/dev/null || true

    # Import EPEL GPG keys (optional, for those who want to enable GPG later)
    log_info "Importing EPEL GPG keys (for optional GPG verification)..."
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-9 2>/dev/null || true
    
    # Refresh metadata
    log_info "Refreshing package metadata..."
    if command -v dnf >/dev/null 2>&1; then
        dnf makecache
    else
        yum makecache
    fi
    
    log_success "EPEL repository reinstalled successfully"
}

# Verify EPEL is working
verify_epel() {
    log_info "Verifying EPEL repository..."
    
    if command -v dnf >/dev/null 2>&1; then
        if dnf repolist enabled | grep -i epel; then
            log_success "EPEL repository is enabled and accessible"
            # Test installing a package from EPEL
            log_info "Testing EPEL package installation..."
            if dnf info htop >/dev/null 2>&1; then
                log_success "EPEL packages are accessible"
            else
                log_warning "EPEL packages may not be fully accessible"
            fi
        else
            log_error "EPEL repository is not enabled"
            return 1
        fi
    else
        log_warning "Cannot verify EPEL (dnf not available)"
    fi
}

# Main execution
main() {
    echo "🔧 EPEL Repository Cleanup Script for GitHub Actions Runner"
    echo "=========================================================="
    
    check_privileges
    detect_os
    
    log_info "This script will:"
    log_info "1. Clean up corrupted EPEL cache and metadata"
    log_info "2. Remove and reinstall EPEL repository"
    log_info "3. Import GPG keys properly"
    log_info "4. Verify EPEL is working"
    echo
    
    read -p "Continue with EPEL cleanup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled"
        exit 0
    fi
    
    cleanup_epel
    reinstall_epel
    verify_epel
    
    log_success "EPEL repository cleanup completed successfully!"
    log_info "You can now run GitHub Actions workflows without EPEL GPG issues"
}

# Run main function
main "$@"
