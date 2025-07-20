#!/bin/bash
# Ansible Version Checker and Tester
# This script checks for new Ansible versions and tests compatibility

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VENV_NAME="ansible-test-venv"
OUTPUT_FILE="${1:-ansible-version-status.json}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Ansible Version Checker and Tester${NC}"
echo -e "${BLUE}====================================${NC}"
echo "Project: $PROJECT_ROOT"
echo "Date: $(date)"
echo "Output: $OUTPUT_FILE"
echo ""

# Function to log messages
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

# Get current Ansible version from requirements.txt
get_current_version() {
    if [ -f "$PROJECT_ROOT/requirements.txt" ]; then
        grep "ansible-core>=" "$PROJECT_ROOT/requirements.txt" | sed 's/.*>=\([0-9.]*\).*/\1/' | head -1
    else
        echo "2.17.0"  # fallback
    fi
}

# Get latest stable version from PyPI
get_latest_version() {
    python3 -c "
import requests
import json
from packaging import version
import sys

try:
    response = requests.get('https://pypi.org/pypi/ansible-core/json', timeout=10)
    data = response.json()
    releases = data['releases']
    
    # Filter out pre-releases and get stable versions
    stable_versions = []
    for ver in releases.keys():
        try:
            parsed = version.parse(ver)
            if not parsed.is_prerelease and len(str(parsed).split('.')) >= 2:
                stable_versions.append(parsed)
        except:
            continue
    
    if stable_versions:
        latest = max(stable_versions)
        print(str(latest))
    else:
        print('unknown')
except Exception as e:
    print('unknown')
    print(f'Error: {e}', file=sys.stderr)
"
}

# Test Ansible version compatibility
test_ansible_version() {
    local version="$1"
    local test_results=()
    local overall_success=true
    
    log_info "Testing Ansible version $version..."
    
    # Create test environment
    if [ -d "$VENV_NAME" ]; then
        rm -rf "$VENV_NAME"
    fi
    
    python3 -m venv "$VENV_NAME"
    source "$VENV_NAME/bin/activate"
    
    # Install specific Ansible version with detailed error capture
    pip install --upgrade pip setuptools wheel > /dev/null 2>&1
    INSTALL_OUTPUT=$(pip install "ansible-core==$version.*" 2>&1)
    if [ $? -eq 0 ]; then
        test_results+=("\"installation\": {\"status\": \"passed\", \"message\": \"Successfully installed ansible-core $version\"}")
        log_success "Installation: PASSED"
    else
        # Analyze installation failure
        if echo "$INSTALL_OUTPUT" | grep -q "No matching distribution found"; then
            INSTALL_ERROR="Version $version not found on PyPI"
        elif echo "$INSTALL_OUTPUT" | grep -q "Could not find a version"; then
            INSTALL_ERROR="No compatible version found for $version.*"
        elif echo "$INSTALL_OUTPUT" | grep -q "ERROR: pip's dependency resolver"; then
            INSTALL_ERROR="Dependency conflict detected"
        else
            INSTALL_ERROR="Unknown installation error"
        fi

        test_results+=("\"installation\": {\"status\": \"failed\", \"message\": \"Failed to install ansible-core $version\", \"error\": \"$INSTALL_ERROR\", \"details\": \"$(echo "$INSTALL_OUTPUT" | tail -3 | tr '\n' ' ' | sed 's/"/\\"/g')\"}")
        log_error "Installation: FAILED - $INSTALL_ERROR"
        overall_success=false
        deactivate
        return 1
    fi
    
    # Install other dependencies
    if pip install -r "$PROJECT_ROOT/requirements.txt" > /dev/null 2>&1; then
        test_results+=("\"dependencies\": {\"status\": \"passed\", \"message\": \"All dependencies installed successfully\"}")
        log_success "Dependencies: PASSED"
    else
        test_results+=("\"dependencies\": {\"status\": \"warning\", \"message\": \"Some dependency issues detected\"}")
        log_warning "Dependencies: WARNING"
    fi
    
    # Test basic Ansible functionality with detailed error capture
    ANSIBLE_OUTPUT=$(ansible --version 2>&1)
    if [ $? -eq 0 ]; then
        ANSIBLE_VERSION=$(echo "$ANSIBLE_OUTPUT" | head -1)
        test_results+=("\"basic_functionality\": {\"status\": \"passed\", \"message\": \"Ansible basic commands work\", \"version_info\": \"$ANSIBLE_VERSION\"}")
        log_success "Basic Functionality: PASSED ($ANSIBLE_VERSION)"
    else
        # Analyze functionality failure
        if echo "$ANSIBLE_OUTPUT" | grep -q "ModuleNotFoundError"; then
            FUNC_ERROR="Python module import error"
        elif echo "$ANSIBLE_OUTPUT" | grep -q "command not found"; then
            FUNC_ERROR="Ansible command not found in PATH"
        else
            FUNC_ERROR="Unknown functionality error"
        fi

        test_results+=("\"basic_functionality\": {\"status\": \"failed\", \"message\": \"Ansible basic commands failed\", \"error\": \"$FUNC_ERROR\", \"details\": \"$(echo "$ANSIBLE_OUTPUT" | tr '\n' ' ' | sed 's/"/\\"/g')\"}")
        log_error "Basic Functionality: FAILED - $FUNC_ERROR"
        overall_success=false
    fi
    
    # Test ansible-lint compatibility
    if command -v ansible-lint > /dev/null 2>&1; then
        if timeout 30 ansible-lint --version > /dev/null 2>&1; then
            test_results+=("\"ansible_lint\": {\"status\": \"passed\", \"message\": \"ansible-lint compatible\"}")
            log_success "Ansible Lint: PASSED"
        else
            test_results+=("\"ansible_lint\": {\"status\": \"warning\", \"message\": \"ansible-lint compatibility issues\"}")
            log_warning "Ansible Lint: WARNING"
        fi
    else
        test_results+=("\"ansible_lint\": {\"status\": \"skipped\", \"message\": \"ansible-lint not available\"}")
        log_info "Ansible Lint: SKIPPED"
    fi
    
    # Test collection installation
    if timeout 60 ansible-galaxy collection install -r "$PROJECT_ROOT/roles/kvmhost_setup/collection/requirements.yml" > /dev/null 2>&1; then
        test_results+=("\"collections\": {\"status\": \"passed\", \"message\": \"Collections installed successfully\"}")
        log_success "Collections: PASSED"
    else
        test_results+=("\"collections\": {\"status\": \"warning\", \"message\": \"Collection installation issues\"}")
        log_warning "Collections: WARNING"
    fi
    
    # Test syntax checking
    if [ -f "$PROJECT_ROOT/roles/kvmhost_setup/tests/test.yml" ]; then
        if ansible-playbook --syntax-check "$PROJECT_ROOT/roles/kvmhost_setup/tests/test.yml" > /dev/null 2>&1; then
            test_results+=("\"syntax_check\": {\"status\": \"passed\", \"message\": \"Syntax check passed\"}")
            log_success "Syntax Check: PASSED"
        else
            test_results+=("\"syntax_check\": {\"status\": \"failed\", \"message\": \"Syntax check failed\"}")
            log_error "Syntax Check: FAILED"
            overall_success=false
        fi
    else
        test_results+=("\"syntax_check\": {\"status\": \"skipped\", \"message\": \"No test playbook found\"}")
        log_info "Syntax Check: SKIPPED"
    fi
    
    deactivate
    
    # Create JSON output for this version
    local test_results_json=$(IFS=','; echo "${test_results[*]}")
    echo "{$test_results_json, \"overall_success\": $overall_success}"
    
    return $([ "$overall_success" = true ] && echo 0 || echo 1)
}

# Main execution
main() {
    cd "$PROJECT_ROOT"
    
    # Install required Python packages
    pip install --user packaging requests > /dev/null 2>&1 || true
    
    # Get version information
    CURRENT_VERSION=$(get_current_version)
    LATEST_VERSION=$(get_latest_version)
    
    log_info "Current version: $CURRENT_VERSION"
    log_info "Latest version: $LATEST_VERSION"
    
    # Compare versions (consider minor version updates significant)
    if python3 -c "
from packaging import version
import sys
try:
    current = version.parse('$CURRENT_VERSION')
    latest = version.parse('$LATEST_VERSION')
    # Consider update significant if minor version is different
    current_minor = (current.major, current.minor)
    latest_minor = (latest.major, latest.minor)
    sys.exit(0 if latest_minor > current_minor else 1)
except:
    sys.exit(1)
"; then
        NEW_VERSION_AVAILABLE=true
        log_success "New minor version available: $LATEST_VERSION"
    else
        NEW_VERSION_AVAILABLE=false
        log_info "No significant version update available (current: $CURRENT_VERSION, latest: $LATEST_VERSION)"
    fi
    
    # Test current version
    log_info "Testing current version $CURRENT_VERSION..."
    CURRENT_TEST_RESULTS=$(test_ansible_version "$CURRENT_VERSION" 2>/dev/null)
    CURRENT_SUCCESS=$?

    # Test latest version if different
    if [ "$NEW_VERSION_AVAILABLE" = true ]; then
        log_info "Testing latest version $LATEST_VERSION..."
        LATEST_TEST_RESULTS=$(test_ansible_version "$LATEST_VERSION" 2>/dev/null)
        LATEST_SUCCESS=$?
    else
        LATEST_TEST_RESULTS="{\"overall_success\": false, \"message\": \"No testing performed - no significant update available\"}"
        LATEST_SUCCESS=1
    fi
    
    # Generate JSON report
    cat > "$OUTPUT_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "current_version": "$CURRENT_VERSION",
  "latest_version": "$LATEST_VERSION",
  "new_version_available": $NEW_VERSION_AVAILABLE,
  "testing_results": {
    "current_version": $CURRENT_TEST_RESULTS,
    "latest_version": $LATEST_TEST_RESULTS
  },
  "recommendations": {
    "update_recommended": $([ "$NEW_VERSION_AVAILABLE" = true ] && [ "$LATEST_SUCCESS" -eq 0 ] && echo "true" || echo "false"),
    "testing_required": $([ "$NEW_VERSION_AVAILABLE" = true ] && [ "$LATEST_SUCCESS" -ne 0 ] && echo "true" || echo "false"),
    "no_action_needed": $([ "$NEW_VERSION_AVAILABLE" = false ] && echo "true" || echo "false")
  }
}
EOF
    
    # Summary
    echo ""
    echo -e "${PURPLE}📊 Summary:${NC}"
    echo -e "Current version: ${GREEN}$CURRENT_VERSION${NC} ($([ $CURRENT_SUCCESS -eq 0 ] && echo "✅ Working" || echo "❌ Issues"))"
    echo -e "Latest version: ${GREEN}$LATEST_VERSION${NC} ($([ $LATEST_SUCCESS -eq 0 ] && echo "✅ Compatible" || echo "❌ Issues"))"
    
    if [ "$NEW_VERSION_AVAILABLE" = true ] && [ $LATEST_SUCCESS -eq 0 ]; then
        echo -e "Status: ${GREEN}🎉 Ready for update!${NC}"
        exit 0
    elif [ "$NEW_VERSION_AVAILABLE" = true ]; then
        echo -e "Status: ${YELLOW}⚠️ Update available but needs review${NC}"
        exit 0
    else
        echo -e "Status: ${BLUE}✅ Up to date${NC}"
        exit 1
    fi
}

# Cleanup function
cleanup() {
    if [ -d "$VENV_NAME" ]; then
        rm -rf "$VENV_NAME"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Run main function
main "$@"
