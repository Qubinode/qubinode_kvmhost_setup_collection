#!/bin/bash
# Local Dependency Testing Script
# Part of ADR-0009: GitHub Actions Dependabot Strategy
# Allows developers to test dependencies locally before pushing

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
ANSIBLE_CORE_VERSION="${ANSIBLE_CORE_VERSION:-2.17}"
MOLECULE_VERSION="${MOLECULE_VERSION:-25.6.0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Local Dependency Testing Script

USAGE:
    $0 [OPTIONS] [TEST_TYPE]

TEST_TYPES:
    python      Test Python dependencies only
    ansible     Test Ansible dependencies only
    docker      Test container dependencies only
    security    Run security scans only
    full        Run all dependency tests (default)

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -c, --clean         Clean existing virtual environments before testing
    --python-version    Python version to test with (default: $PYTHON_VERSION)
    --ansible-version   Ansible Core version to test with (default: $ANSIBLE_CORE_VERSION)
    --molecule-version  Molecule version to test with (default: $MOLECULE_VERSION)

EXAMPLES:
    $0                  # Run all dependency tests
    $0 python           # Test only Python dependencies
    $0 --clean full     # Clean environments and run all tests
    $0 --python-version 3.12 python  # Test with Python 3.12

ENVIRONMENT VARIABLES:
    PYTHON_VERSION      Override default Python version
    ANSIBLE_CORE_VERSION Override default Ansible Core version
    MOLECULE_VERSION    Override default Molecule version
    VENV_DIR           Override virtual environment directory (default: venvs)

EOF
}

# Parse command line arguments
VERBOSE=false
CLEAN=false
TEST_TYPE="full"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        --python-version)
            PYTHON_VERSION="$2"
            shift 2
            ;;
        --ansible-version)
            ANSIBLE_CORE_VERSION="$2"
            shift 2
            ;;
        --molecule-version)
            MOLECULE_VERSION="$2"
            shift 2
            ;;
        python|ansible|docker|security|full)
            TEST_TYPE="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Set up environment
VENV_DIR="${VENV_DIR:-$PROJECT_ROOT/venvs}"
REPORTS_DIR="$PROJECT_ROOT/dependency-reports"

# Create directories
mkdir -p "$VENV_DIR" "$REPORTS_DIR"

cd "$PROJECT_ROOT"

log_info "Starting dependency testing with configuration:"
log_info "  Test Type: $TEST_TYPE"
log_info "  Python Version: $PYTHON_VERSION"
log_info "  Ansible Core Version: $ANSIBLE_CORE_VERSION"
log_info "  Molecule Version: $MOLECULE_VERSION"
log_info "  Virtual Env Dir: $VENV_DIR"
log_info "  Reports Dir: $REPORTS_DIR"

# Clean virtual environments if requested
if [[ "$CLEAN" == "true" ]]; then
    log_info "Cleaning existing virtual environments..."
    rm -rf "$VENV_DIR"/*
    mkdir -p "$VENV_DIR"
fi

# Check system dependencies
check_system_dependencies() {
    log_info "Checking system dependencies..."
    
    # Check Python
    if ! command -v "python$PYTHON_VERSION" &> /dev/null; then
        log_error "Python $PYTHON_VERSION not found. Please install it first."
        log_info "On RHEL/Rocky/AlmaLinux: sudo yum install -y python$PYTHON_VERSION python$PYTHON_VERSION-devel python$PYTHON_VERSION-pip"
        exit 1
    fi
    
    # Check Podman/Docker
    if ! command -v podman &> /dev/null && ! command -v docker &> /dev/null; then
        log_warning "Neither Podman nor Docker found. Container tests will be skipped."
    fi
    
    log_success "System dependencies check completed"
}

# Test Python dependencies
test_python_dependencies() {
    log_info "Testing Python dependencies..."
    
    local venv_path="$VENV_DIR/python-test"
    
    # Install system SELinux packages if available
    if command -v yum &> /dev/null; then
        log_info "Installing SELinux system packages..."
        sudo yum install -y libselinux-python3 python3-libselinux python3-selinux 2>/dev/null || {
            log_warning "Could not install SELinux packages - continuing anyway"
        }
    fi
    
    # Create virtual environment with system site packages for SELinux
    "python$PYTHON_VERSION" -m pip install --user virtualenv
    "python$PYTHON_VERSION" -m virtualenv --system-site-packages "$venv_path"
    
    # Activate virtual environment
    source "$venv_path/bin/activate"
    
    # Verify SELinux bindings
    log_info "Verifying SELinux bindings..."
    python -c "import selinux; print('SELinux bindings available')" 2>/dev/null || {
        log_warning "SELinux bindings not available - setting fallback configuration"
        export ANSIBLE_SELINUX_SPECIAL_FS=""
    }
    
    # Upgrade pip
    pip install --upgrade pip setuptools wheel
    
    # Test core dependencies
    log_info "Installing and testing core dependencies..."
    pip install "ansible-core==$ANSIBLE_CORE_VERSION.*"
    pip install "molecule[podman]==$MOLECULE_VERSION.*"
    pip install ansible-lint yamllint
    
    # Verify installations
    ansible --version
    ansible-config dump --only-changed || log_warning "ansible-config dump failed"
    molecule --version
    ansible-lint --version
    yamllint --version
    
    # Test Ansible collections
    log_info "Testing Ansible collections installation..."
    ansible-galaxy collection install community.general
    ansible-galaxy collection install containers.podman
    
    # Generate dependency report
    local report_file="$REPORTS_DIR/python-dependencies-$(date +%Y%m%d-%H%M%S).txt"
    pip freeze > "$report_file"
    
    deactivate
    
    log_success "Python dependency testing completed"
    log_info "Report saved to: $report_file"
}

# Test Ansible dependencies
test_ansible_dependencies() {
    log_info "Testing Ansible dependencies..."
    
    local venv_path="$VENV_DIR/ansible-test"
    
    # Install system SELinux packages if available
    if command -v yum &> /dev/null; then
        log_info "Installing SELinux system packages..."
        sudo yum install -y libselinux-python3 python3-libselinux python3-selinux 2>/dev/null || {
            log_warning "Could not install SELinux packages - continuing anyway"
        }
    fi
    
    # Create virtual environment with system site packages for SELinux
    "python$PYTHON_VERSION" -m virtualenv --system-site-packages "$venv_path"
    source "$venv_path/bin/activate"
    
    # Verify SELinux bindings
    log_info "Verifying SELinux bindings..."
    python -c "import selinux; print('SELinux bindings available')" 2>/dev/null || {
        log_warning "SELinux bindings not available - setting fallback configuration"
        export ANSIBLE_SELINUX_SPECIAL_FS=""
    }
    
    pip install --upgrade pip
    pip install "ansible-core==$ANSIBLE_CORE_VERSION.*"
    
    # Test galaxy.yml dependencies
    if [[ -f galaxy.yml ]]; then
        log_info "Installing dependencies from galaxy.yml..."
        ansible-galaxy collection install -r galaxy.yml --force
    fi
    
    # Test role syntax
    log_info "Testing role syntax..."
    for role in roles/*/; do
        if [[ -d "$role" ]]; then
            role_name=$(basename "$role")
            log_info "Testing role: $role_name"
            
            # Create a simple test playbook
            cat > test-role.yml << EOF
---
- hosts: localhost
  connection: local
  gather_facts: false
  roles:
    - role: $role_name
EOF
            
            if ansible-playbook --syntax-check test-role.yml; then
                log_success "Role $role_name syntax check passed"
            else
                log_warning "Role $role_name syntax check failed"
            fi
            
            rm -f test-role.yml
        fi
    done
    
    # Test collection build
    log_info "Testing collection build..."
    if ansible-galaxy collection build --force; then
        log_success "Collection build successful"
        ls -la *.tar.gz
    else
        log_error "Collection build failed"
    fi
    
    # Generate Ansible report
    local report_file="$REPORTS_DIR/ansible-dependencies-$(date +%Y%m%d-%H%M%S).txt"
    {
        echo "Ansible Version:"
        ansible --version
        echo ""
        echo "Installed Collections:"
        ansible-galaxy collection list
    } > "$report_file"
    
    deactivate
    
    log_success "Ansible dependency testing completed"
    log_info "Report saved to: $report_file"
}

# Test container dependencies
test_docker_dependencies() {
    log_info "Testing container dependencies..."
    
    # Check if container runtime is available
    local container_cmd=""
    if command -v podman &> /dev/null; then
        container_cmd="podman"
    elif command -v docker &> /dev/null; then
        container_cmd="docker"
    else
        log_error "Neither Podman nor Docker found. Skipping container tests."
        return 1
    fi
    
    log_info "Using container runtime: $container_cmd"
    
    # Test image availability
    local images=(
        "registry.redhat.io/ubi9-init:9.6-1751962289"
        "docker.io/rockylinux/rockylinux:9-ubi-init"
        "docker.io/almalinux/9-init:9.6-20250712"
    )
    
    local report_file="$REPORTS_DIR/container-dependencies-$(date +%Y%m%d-%H%M%S).txt"
    echo "Container Dependency Test Report" > "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    for image in "${images[@]}"; do
        log_info "Testing image: $image"
        
        if $container_cmd pull "$image"; then
            log_success "Successfully pulled: $image"
            echo "✅ $image" >> "$report_file"
        else
            log_warning "Failed to pull: $image"
            echo "❌ $image" >> "$report_file"
        fi
    done
    
    # Test Molecule with containers (if available)
    if [[ -d molecule/default ]]; then
        local venv_path="$VENV_DIR/molecule-test"
        "python$PYTHON_VERSION" -m virtualenv "$venv_path"
        source "$venv_path/bin/activate"
        
        pip install --upgrade pip
        pip install "molecule[podman]==$MOLECULE_VERSION.*"
        
        cd molecule/default
        
        log_info "Testing Molecule configuration..."
        if molecule check; then
            log_success "Molecule configuration check passed"
            echo "✅ Molecule configuration valid" >> "$report_file"
        else
            log_warning "Molecule configuration check failed"
            echo "❌ Molecule configuration invalid" >> "$report_file"
        fi
        
        deactivate
        cd "$PROJECT_ROOT"
    fi
    
    log_success "Container dependency testing completed"
    log_info "Report saved to: $report_file"
}

# Run security scans
test_security_dependencies() {
    log_info "Running security dependency scans..."
    
    local venv_path="$VENV_DIR/security-test"
    
    "python$PYTHON_VERSION" -m virtualenv "$venv_path"
    source "$venv_path/bin/activate"
    
    pip install --upgrade pip
    pip install safety bandit
    
    # Create temporary requirements file
    cat > temp-requirements.txt << EOF
ansible-core==$ANSIBLE_CORE_VERSION.*
molecule[podman]==$MOLECULE_VERSION.*
ansible-lint
yamllint
EOF
    
    local report_file="$REPORTS_DIR/security-dependencies-$(date +%Y%m%d-%H%M%S).txt"
    echo "Security Dependency Scan Report" > "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Run safety check
    log_info "Running dependency vulnerability scan..."
    if safety check -r temp-requirements.txt >> "$report_file" 2>&1; then
        log_success "No known vulnerabilities found"
        echo "✅ No known vulnerabilities" >> "$report_file"
    else
        log_warning "Vulnerabilities found in dependencies"
        echo "⚠️ Vulnerabilities detected" >> "$report_file"
    fi
    
    # Run bandit on Python files
    log_info "Running static code analysis..."
    if find . -name "*.py" -exec bandit {} \; >> "$report_file" 2>&1; then
        log_success "No security issues found in Python code"
        echo "✅ No Python security issues" >> "$report_file"
    else
        log_warning "Security issues found in Python code"
        echo "⚠️ Python security issues detected" >> "$report_file"
    fi
    
    rm -f temp-requirements.txt
    deactivate
    
    log_success "Security dependency testing completed"
    log_info "Report saved to: $report_file"
}

# Main execution
main() {
    log_info "🔍 Starting Local Dependency Testing"
    
    check_system_dependencies
    
    case "$TEST_TYPE" in
        python)
            test_python_dependencies
            ;;
        ansible)
            test_ansible_dependencies
            ;;
        docker)
            test_docker_dependencies
            ;;
        security)
            test_security_dependencies
            ;;
        full)
            test_python_dependencies
            test_ansible_dependencies
            test_docker_dependencies
            test_security_dependencies
            ;;
        *)
            log_error "Unknown test type: $TEST_TYPE"
            exit 1
            ;;
    esac
    
    log_success "✅ Dependency testing completed successfully!"
    log_info "📊 Reports available in: $REPORTS_DIR"
    
    # Summary
    echo ""
    echo "=== DEPENDENCY TESTING SUMMARY ==="
    echo "Test Type: $TEST_TYPE"
    echo "Python Version: $PYTHON_VERSION"
    echo "Ansible Core: $ANSIBLE_CORE_VERSION"
    echo "Molecule: $MOLECULE_VERSION"
    echo "Reports Directory: $REPORTS_DIR"
    echo ""
    
    if [[ "$TEST_TYPE" == "full" ]]; then
        echo "📋 Next Steps:"
        echo "1. Review generated reports in $REPORTS_DIR"
        echo "2. Address any security vulnerabilities found"
        echo "3. Test changes with: ./scripts/test-local-molecule.sh"
        echo "4. Commit and push when all tests pass"
    fi
}

# Execute main function
main "$@"
