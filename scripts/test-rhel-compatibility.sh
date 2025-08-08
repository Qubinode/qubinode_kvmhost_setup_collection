#!/bin/bash
# RHEL Compatibility Testing Script
# Tests molecule scenarios for RHEL 8, 9, and 10 compatibility
# Part of ADR-0008: RHEL 9 and RHEL 10 Support Strategy
# Follows the same pattern as scripts/test-dependencies.sh

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
ANSIBLE_CORE_VERSION="${ANSIBLE_CORE_VERSION:-2.18}"

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
RHEL Compatibility Testing Script

USAGE:
    $0 [OPTIONS] [RHEL_VERSIONS]

RHEL_VERSIONS:
    Comma-separated list of RHEL versions to test (default: 8,9,10)
    Examples: 8,9,10 or 9 or 8,10

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -s, --syntax-only   Run syntax checks only (faster)
    -f, --full-test     Run full molecule tests (slower, requires containers)
    --no-install        Skip dependency installation
    --clean             Clean molecule cache before testing

EXAMPLES:
    $0                  # Test all RHEL versions (8,9,10) with syntax checks
    $0 9                # Test only RHEL 9
    $0 8,10 --full-test # Full test for RHEL 8 and 10
    $0 --syntax-only    # Quick syntax validation for all versions

ENVIRONMENT VARIABLES:
    PYTHON_VERSION      Python version to use (default: 3.11)
    ANSIBLE_CORE_VERSION Ansible core version (default: 2.18)
    MOLECULE_NO_LOG     Disable molecule logging (default: false)

EOF
}

# Parse command line arguments
RHEL_VERSIONS=""
VERBOSE=false
SYNTAX_ONLY=true
FULL_TEST=false
NO_INSTALL=false
CLEAN=false

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
        -s|--syntax-only)
            SYNTAX_ONLY=true
            FULL_TEST=false
            shift
            ;;
        -f|--full-test)
            FULL_TEST=true
            SYNTAX_ONLY=false
            shift
            ;;
        --no-install)
            NO_INSTALL=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            RHEL_VERSIONS="$1"
            shift
            ;;
    esac
done

# Set default RHEL versions if not provided
RHEL_VERSIONS=${RHEL_VERSIONS:-"8,9,10"}

# Change to project root
cd "$PROJECT_ROOT"

log_info "🧪 RHEL Compatibility Testing Script"
log_info "======================================"

# Validate environment
if [ ! -f "galaxy.yml" ]; then
    log_error "Must run from the root of the collection directory"
    log_error "Expected to find galaxy.yml in current directory"
    exit 1
fi

# Clean molecule cache if requested
if [ "$CLEAN" = true ]; then
    log_info "🧹 Cleaning molecule cache..."
    rm -rf ~/.cache/molecule/qubinode_kvmhost_setup_collection/ || true
    log_success "Molecule cache cleaned"
fi

# Install dependencies if needed
if [ "$NO_INSTALL" = false ]; then
    log_info "📦 Checking dependencies..."

    if ! command -v molecule &> /dev/null; then
        log_info "Installing molecule..."
        pip install molecule molecule-plugins[docker] pytest-testinfra
    fi

    if ! command -v ansible &> /dev/null; then
        log_info "Installing ansible-core..."
        pip install "ansible-core>=$ANSIBLE_CORE_VERSION,<$ANSIBLE_CORE_VERSION.99"
    fi
fi

# Handle SELinux gracefully in containerized environments
export ANSIBLE_SELINUX_SPECIAL_FS=""
export LIBSELINUX_DISABLE_SELINUX_CHECK="1"
export MOLECULE_NO_LOG="${MOLECULE_NO_LOG:-false}"

# Verify ansible-core version compatibility
ansible_version=$(ansible --version | head -1 | cut -d' ' -f3 | cut -d']' -f1)
log_info "📋 Using ansible-core version: $ansible_version"

if [[ "$ansible_version" == "2.17"* ]]; then
    log_warning "ansible-core 2.17 has SELinux binding issues with Python 3.11"
    log_warning "Consider upgrading to ansible-core 2.18+ for better compatibility"
fi

# Parse RHEL versions
IFS=',' read -ra VERSIONS <<< "$RHEL_VERSIONS"

log_info ""
log_info "🔍 Testing RHEL versions: $RHEL_VERSIONS"
log_info "Test mode: $([ "$FULL_TEST" = true ] && echo "Full molecule test" || echo "Syntax check only")"
log_info ""

# Test results tracking
PASSED_TESTS=()
FAILED_TESTS=()
TOTAL_TESTS=0

# Main testing loop
for version in "${VERSIONS[@]}"; do
    version=$(echo "$version" | xargs)  # trim whitespace
    scenario="rhel$version"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    log_info "🧪 Testing RHEL $version compatibility..."
    log_info "----------------------------------------"

    # Check if RHEL-specific molecule directory exists
    if [ ! -d "molecule/$scenario" ]; then
        log_error "No molecule/$scenario/ configuration found"
        log_info "Available molecule directories:"
        find molecule/ -type d -maxdepth 1 2>/dev/null | grep -v "^molecule/$" || log_warning "No molecule subdirectories found"
        FAILED_TESTS+=("RHEL $version (missing config)")
        continue
    fi

    log_success "Found molecule/$scenario/ configuration"

    # Verify required files exist
    required_files=("molecule.yml" "converge.yml" "verify.yml")
    missing_files=()

    for file in "${required_files[@]}"; do
        if [ ! -f "molecule/$scenario/$file" ]; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -gt 0 ]; then
        log_error "Missing required files in molecule/$scenario/: ${missing_files[*]}"
        FAILED_TESTS+=("RHEL $version (missing files)")
        continue
    fi

    # Run the appropriate test
    if [ "$FULL_TEST" = true ]; then
        log_info "🧪 Running full molecule test for scenario $scenario..."
        if molecule test -s "$scenario"; then
            log_success "RHEL $version full test passed"
            PASSED_TESTS+=("RHEL $version (full)")
        else
            log_error "RHEL $version full test failed"
            FAILED_TESTS+=("RHEL $version (full)")
        fi
    else
        log_info "🔍 Running syntax check for scenario $scenario..."
        if molecule syntax -s "$scenario"; then
            log_success "RHEL $version syntax check passed"
            PASSED_TESTS+=("RHEL $version (syntax)")
        else
            log_error "RHEL $version syntax check failed"
            FAILED_TESTS+=("RHEL $version (syntax)")
        fi
    fi

    log_info ""
done

# Print summary
log_info "🎉 RHEL Compatibility Testing Summary"
log_info "====================================="
log_info "Total tests: $TOTAL_TESTS"
log_info "Passed: ${#PASSED_TESTS[@]}"
log_info "Failed: ${#FAILED_TESTS[@]}"

if [ ${#PASSED_TESTS[@]} -gt 0 ]; then
    log_success "Passed tests:"
    for test in "${PASSED_TESTS[@]}"; do
        log_success "  ✅ $test"
    done
fi

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    log_error "Failed tests:"
    for test in "${FAILED_TESTS[@]}"; do
        log_error "  ❌ $test"
    done
fi

log_info ""
if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    log_success "🎉 All RHEL compatibility tests passed!"
    log_info ""
    log_info "💡 Usage tips:"
    log_info "   Full test: $0 --full-test"
    log_info "   Single version: $0 9 --full-test"
    log_info "   Clean cache: $0 --clean"
    exit 0
else
    log_error "❌ Some RHEL compatibility tests failed"
    log_info ""
    log_info "💡 Troubleshooting:"
    log_info "   Check molecule configurations: ls -la molecule/rhel*/"
    log_info "   Verify dependencies: pip install -r requirements-dev.txt"
    log_info "   Clean cache: $0 --clean"
    exit 1
fi
