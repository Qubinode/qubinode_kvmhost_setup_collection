#!/bin/bash

# Dependency Update Validation Script
# Validates dependency updates and compatibility

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORT_DIR="$PROJECT_ROOT/dependency-validation-reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

main() {
    log_info "Starting dependency validation..."
    
    # Create report directory
    mkdir -p "$REPORT_DIR"
    
    # Check Python dependencies
    check_python_dependencies
    
    # Check Ansible dependencies
    check_ansible_dependencies
    
    # Check container dependencies
    check_container_dependencies
    
    # Generate report
    generate_dependency_report
    
    log_success "Dependency validation completed"
}

check_python_dependencies() {
    log_info "Checking Python dependencies..."
    
    # Check if Python 3.11 is available
    if command -v python3.11 &> /dev/null; then
        PYTHON_VERSION=$(python3.11 --version)
        log_success "Python 3.11 found: $PYTHON_VERSION"
    elif command -v python3.9 &> /dev/null; then
        PYTHON_VERSION=$(python3.9 --version)
        log_warning "Python 3.9 found (recommend 3.11): $PYTHON_VERSION"
    else
        log_error "No compatible Python version found"
        return 1
    fi
    
    # Check pip
    if command -v pip3 &> /dev/null; then
        log_success "pip3 is available"
    else
        log_error "pip3 not found"
        return 1
    fi
}

check_ansible_dependencies() {
    log_info "Checking Ansible dependencies..."
    
    # Check for requirements file
    if [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
        log_success "requirements.txt found"
        
        # Check if ansible-core is specified
        if grep -q "ansible-core" "$PROJECT_ROOT/requirements.txt"; then
            ANSIBLE_VERSION=$(grep "ansible-core" "$PROJECT_ROOT/requirements.txt")
            log_success "Ansible core requirement: $ANSIBLE_VERSION"
        else
            log_warning "ansible-core not specified in requirements.txt"
        fi
    else
        log_warning "requirements.txt not found"
    fi
    
    # Check if ansible is installed
    if command -v ansible &> /dev/null; then
        INSTALLED_ANSIBLE=$(ansible --version | head -1)
        log_success "Ansible installed: $INSTALLED_ANSIBLE"
    else
        log_info "Ansible not currently installed (OK for CI environment)"
    fi
}

check_container_dependencies() {
    log_info "Checking container dependencies..."
    
    # Check Podman
    if command -v podman &> /dev/null; then
        PODMAN_VERSION=$(podman --version)
        log_success "Podman found: $PODMAN_VERSION"
    else
        log_warning "Podman not found"
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        log_success "Docker found: $DOCKER_VERSION"
    else
        log_info "Docker not found (Podman preferred)"
    fi
}

generate_dependency_report() {
    log_info "Generating dependency report..."
    
    REPORT_FILE="$REPORT_DIR/dependency-validation-$TIMESTAMP.json"
    
    cat > "$REPORT_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "validation_results": {
    "python": {
      "version": "${PYTHON_VERSION:-unknown}",
      "status": "$(command -v python3.11 &> /dev/null && echo "ok" || echo "warning")"
    },
    "ansible": {
      "installed": $(command -v ansible &> /dev/null && echo "true" || echo "false"),
      "requirements_file": $([ -f "$PROJECT_ROOT/requirements.txt" ] && echo "true" || echo "false")
    },
    "containers": {
      "podman": $(command -v podman &> /dev/null && echo "true" || echo "false"),
      "docker": $(command -v docker &> /dev/null && echo "true" || echo "false")
    }
  },
  "status": "completed"
}
EOF
    
    log_success "Report generated: $REPORT_FILE"
}

# Show help
show_help() {
    cat << EOF
Dependency Update Validation Script

Usage: $0 [options]

Options:
  -h, --help    Show this help message

This script validates:
- Python 3.11+ availability
- Ansible dependencies
- Container runtime availability
- Requirements file validity

Generates validation reports in dependency-validation-reports/
EOF
}

# Parse arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
