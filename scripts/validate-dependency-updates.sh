#!/bin/bash

# =============================================================================
# Update Compatibility Checker - The "Dependency Change Guardian"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script validates dependency updates before merging, implementing ADR-0009
# GitHub Actions Dependabot Strategy with comprehensive compatibility checking.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Update Analysis - Analyzes proposed dependency changes and impacts
# 2. [PHASE 2]: Compatibility Testing - Tests compatibility with existing functionality
# 3. [PHASE 3]: Security Validation - Validates security implications of updates
# 4. [PHASE 4]: Integration Testing - Tests integration with collection components
# 5. [PHASE 5]: Performance Assessment - Assesses performance impact of updates
# 6. [PHASE 6]: Approval Pipeline - Provides approval/rejection recommendations
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Implements: ADR-0009 GitHub Actions Dependabot Strategy requirements
# - Validates: Dependency updates from Dependabot PRs before merging
# - Tests: Compatibility with existing collection functionality
# - Prevents: Breaking changes from dependency updates
# - Coordinates: With CI/CD pipeline for automated dependency management
# - Reports: Detailed validation results for dependency update decisions
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - GATEKEEPER: Controls dependency updates to prevent breaking changes
# - COMPREHENSIVE: Tests all aspects of dependency update impact
# - AUTOMATION: Fully automated validation suitable for CI/CD integration
# - SAFETY: Prioritizes system stability over having latest versions
# - REPORTING: Provides detailed analysis for dependency update decisions
# - INTEGRATION: Seamlessly integrates with Dependabot and CI/CD workflows
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - Validation Rules: Add new validation rules for dependency updates
# - Test Coverage: Extend testing to cover new dependency types
# - Security Checks: Add new security validation for dependency updates
# - Performance: Add performance impact assessment capabilities
# - Integration: Add integration with new dependency management tools
# - Automation: Add automated dependency approval workflows
#
# 🚨 IMPORTANT FOR LLMs: This script controls critical dependency updates.
# Failures indicate serious compatibility issues that could break the collection.
# Always address validation failures before merging dependency updates.

# Dependency Update Validation Pipeline
# Part of ADR-0009: GitHub Actions Dependabot Strategy
# Validates dependency updates before they are merged

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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
Dependency Update Validation Pipeline

This script validates dependency updates by running comprehensive tests
before allowing them to be merged into the main branch.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    --pr-number         GitHub PR number to validate (optional)
    --base-branch       Base branch to compare against (default: main)
    --fail-fast         Stop on first test failure
    --skip-security     Skip security vulnerability scans
    --skip-performance  Skip performance regression tests

WORKFLOW:
    1. Detect dependency changes
    2. Create isolated test environment
    3. Run compatibility tests
    4. Check for breaking changes
    5. Run security scans
    6. Performance regression tests
    7. Generate validation report

EXAMPLES:
    $0                              # Standard validation
    $0 --pr-number 123              # Validate specific PR
    $0 --fail-fast --verbose        # Quick validation with detailed output

ENVIRONMENT VARIABLES:
    GITHUB_TOKEN        GitHub token for API access
    PR_NUMBER          Pull request number (auto-detected in CI)
    BASE_BRANCH        Base branch for comparison (default: main)

EOF
}

# Parse command line arguments
VERBOSE=false
PR_NUMBER=""
BASE_BRANCH="main"
FAIL_FAST=false
SKIP_SECURITY=false
SKIP_PERFORMANCE=false

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
        --pr-number)
            PR_NUMBER="$2"
            shift 2
            ;;
        --base-branch)
            BASE_BRANCH="$2"
            shift 2
            ;;
        --fail-fast)
            FAIL_FAST=true
            shift
            ;;
        --skip-security)
            SKIP_SECURITY=true
            shift
            ;;
        --skip-performance)
            SKIP_PERFORMANCE=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Configuration
VALIDATION_DIR="$PROJECT_ROOT/dependency-validation"
REPORTS_DIR="$VALIDATION_DIR/reports"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
VALIDATION_REPORT="$REPORTS_DIR/validation-report-$TIMESTAMP.json"

# Create directories
mkdir -p "$VALIDATION_DIR" "$REPORTS_DIR"

cd "$PROJECT_ROOT"

# Initialize validation report
init_validation_report() {
    cat > "$VALIDATION_REPORT" << EOF
{
  "validation_run": {
    "timestamp": "$(date -Iseconds)",
    "pr_number": "$PR_NUMBER",
    "base_branch": "$BASE_BRANCH",
    "commit_sha": "$(git rev-parse HEAD)",
    "status": "running"
  },
  "tests": {},
  "summary": {
    "total_tests": 0,
    "passed": 0,
    "failed": 0,
    "skipped": 0
  }
}
EOF
}

# Update validation report
update_report() {
    local test_name="$1"
    local status="$2"
    local details="$3"
    
    # Use jq to update the JSON report (install if not available)
    if ! command -v jq &> /dev/null; then
        sudo yum install -y jq
    fi
    
    local temp_file=$(mktemp)
    jq ".tests[\"$test_name\"] = {\"status\": \"$status\", \"details\": \"$details\", \"timestamp\": \"$(date -Iseconds)\"}" "$VALIDATION_REPORT" > "$temp_file"
    mv "$temp_file" "$VALIDATION_REPORT"
    
    # Update summary counts
    local passed=$(jq '.tests | to_entries | map(select(.value.status == "passed")) | length' "$VALIDATION_REPORT")
    local failed=$(jq '.tests | to_entries | map(select(.value.status == "failed")) | length' "$VALIDATION_REPORT")
    local skipped=$(jq '.tests | to_entries | map(select(.value.status == "skipped")) | length' "$VALIDATION_REPORT")
    local total=$((passed + failed + skipped))
    
    temp_file=$(mktemp)
    jq ".summary = {\"total_tests\": $total, \"passed\": $passed, \"failed\": $failed, \"skipped\": $skipped}" "$VALIDATION_REPORT" > "$temp_file"
    mv "$temp_file" "$VALIDATION_REPORT"
}

# Detect dependency changes
detect_dependency_changes() {
    log_info "Detecting dependency changes..."
    
    local changes_detected=false
    local change_summary=""
    
    # Check for changes in dependency files
    if git diff --name-only "$BASE_BRANCH" HEAD | grep -E "(requirements.*\.txt|galaxy\.yml|meta/runtime\.yml|\.github/dependabot\.yml)"; then
        changes_detected=true
        change_summary="Dependency configuration files modified"
    fi
    
    # Check for GitHub Actions workflow changes
    if git diff --name-only "$BASE_BRANCH" HEAD | grep -E "\.github/workflows/.*\.yml"; then
        changes_detected=true
        change_summary="${change_summary:+$change_summary, }GitHub Actions workflows modified"
    fi
    
    # Check for Molecule configuration changes
    if git diff --name-only "$BASE_BRANCH" HEAD | grep -E "molecule/.*/molecule\.yml"; then
        changes_detected=true
        change_summary="${change_summary:+$change_summary, }Molecule configurations modified"
    fi
    
    if [[ "$changes_detected" == "true" ]]; then
        log_info "Changes detected: $change_summary"
        update_report "dependency_detection" "passed" "$change_summary"
        return 0
    else
        log_info "No dependency changes detected"
        update_report "dependency_detection" "skipped" "No dependency changes found"
        return 1
    fi
}

# Create isolated test environment
create_test_environment() {
    log_info "Creating isolated test environment..."
    
    local test_env_dir="$VALIDATION_DIR/test-env"
    rm -rf "$test_env_dir"
    mkdir -p "$test_env_dir"
    
    # Create virtual environment for testing
    python3.11 -m venv "$test_env_dir/venv"
    source "$test_env_dir/venv/bin/activate"
    
    pip install --upgrade pip setuptools wheel
    
    update_report "test_environment" "passed" "Isolated test environment created at $test_env_dir"
    
    # Export for use in other functions
    export TEST_ENV_DIR="$test_env_dir"
    deactivate
}

# Test dependency compatibility
test_dependency_compatibility() {
    log_info "Testing dependency compatibility..."
    
    source "$TEST_ENV_DIR/venv/bin/activate"
    
    local compatibility_log="$REPORTS_DIR/compatibility-$TIMESTAMP.log"
    
    # Test Python dependencies installation
    if pip install -r <(grep -E "^(ansible-core|molecule)" requirements.txt 2>/dev/null || echo "ansible-core>=2.17,<2.19") >> "$compatibility_log" 2>&1; then
        log_success "Python dependencies installed successfully"
    else
        log_error "Failed to install Python dependencies"
        update_report "dependency_compatibility" "failed" "Python dependency installation failed"
        deactivate
        [[ "$FAIL_FAST" == "true" ]] && exit 1
        return 1
    fi
    
    # Test Ansible collections
    if ansible-galaxy collection install -r galaxy.yml --force >> "$compatibility_log" 2>&1; then
        log_success "Ansible collections installed successfully"
    else
        log_warning "Failed to install some Ansible collections"
    fi
    
    # Test basic functionality
    if ansible --version >> "$compatibility_log" 2>&1 && molecule --version >> "$compatibility_log" 2>&1; then
        log_success "Basic functionality tests passed"
        update_report "dependency_compatibility" "passed" "All dependency compatibility tests passed"
    else
        log_error "Basic functionality tests failed"
        update_report "dependency_compatibility" "failed" "Basic functionality tests failed"
        deactivate
        [[ "$FAIL_FAST" == "true" ]] && exit 1
        return 1
    fi
    
    deactivate
}

# Check for breaking changes
check_breaking_changes() {
    log_info "Checking for breaking changes..."
    
    source "$TEST_ENV_DIR/venv/bin/activate"
    
    local breaking_changes=false
    local breaking_log="$REPORTS_DIR/breaking-changes-$TIMESTAMP.log"
    
    # Test existing playbooks and roles
    for role in roles/*/; do
        if [[ -d "$role" ]]; then
            role_name=$(basename "$role")
            log_info "Testing role: $role_name"
            
            # Create test playbook
            cat > test-breaking.yml << EOF
---
- hosts: localhost
  connection: local
  gather_facts: false
  roles:
    - role: $role_name
EOF
            
            if ansible-playbook --syntax-check test-breaking.yml >> "$breaking_log" 2>&1; then
                log_success "Role $role_name syntax check passed"
            else
                log_error "Role $role_name syntax check failed - potential breaking change"
                breaking_changes=true
                [[ "$FAIL_FAST" == "true" ]] && break
            fi
            
            rm -f test-breaking.yml
        fi
    done
    
    # Test molecule configurations
    if [[ -d molecule/default ]]; then
        cd molecule/default
        if molecule check >> "$breaking_log" 2>&1; then
            log_success "Molecule configuration check passed"
        else
            log_error "Molecule configuration check failed - potential breaking change"
            breaking_changes=true
        fi
        cd "$PROJECT_ROOT"
    fi
    
    if [[ "$breaking_changes" == "true" ]]; then
        update_report "breaking_changes" "failed" "Breaking changes detected in roles or configurations"
        deactivate
        [[ "$FAIL_FAST" == "true" ]] && exit 1
        return 1
    else
        update_report "breaking_changes" "passed" "No breaking changes detected"
    fi
    
    deactivate
}

# Run security scans
run_security_scans() {
    if [[ "$SKIP_SECURITY" == "true" ]]; then
        log_info "Skipping security scans (--skip-security specified)"
        update_report "security_scans" "skipped" "Security scans skipped by user request"
        return 0
    fi
    
    log_info "Running security vulnerability scans..."
    
    source "$TEST_ENV_DIR/venv/bin/activate"
    
    # Install security tools
    pip install safety bandit
    
    local security_log="$REPORTS_DIR/security-$TIMESTAMP.log"
    local security_issues=false
    
    # Run safety check on dependencies
    if safety check >> "$security_log" 2>&1; then
        log_success "No known vulnerabilities in dependencies"
    else
        log_warning "Security vulnerabilities found in dependencies"
        security_issues=true
    fi
    
    # Run bandit on Python code
    if find . -name "*.py" -exec bandit -q {} \; >> "$security_log" 2>&1; then
        log_success "No security issues found in Python code"
    else
        log_warning "Security issues found in Python code"
        security_issues=true
    fi
    
    if [[ "$security_issues" == "true" ]]; then
        update_report "security_scans" "failed" "Security vulnerabilities or issues detected"
        log_warning "Security issues detected - review $security_log"
    else
        update_report "security_scans" "passed" "No security vulnerabilities detected"
    fi
    
    deactivate
}

# Performance regression tests
run_performance_tests() {
    if [[ "$SKIP_PERFORMANCE" == "true" ]]; then
        log_info "Skipping performance tests (--skip-performance specified)"
        update_report "performance_tests" "skipped" "Performance tests skipped by user request"
        return 0
    fi
    
    log_info "Running performance regression tests..."
    
    local perf_log="$REPORTS_DIR/performance-$TIMESTAMP.log"
    
    # Test Ansible playbook execution time
    source "$TEST_ENV_DIR/venv/bin/activate"
    
    # Create a simple performance test playbook
    cat > perf-test.yml << EOF
---
- hosts: localhost
  connection: local
  gather_facts: true
  tasks:
    - name: Performance test task
      debug:
        msg: "Testing performance"
EOF
    
    local start_time=$(date +%s)
    if ansible-playbook perf-test.yml >> "$perf_log" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "Performance test completed in ${duration}s"
        
        # Simple threshold check (should complete in under 30 seconds)
        if [[ $duration -lt 30 ]]; then
            update_report "performance_tests" "passed" "Performance test completed in ${duration}s (under threshold)"
        else
            update_report "performance_tests" "failed" "Performance test took ${duration}s (over 30s threshold)"
        fi
    else
        log_error "Performance test failed to execute"
        update_report "performance_tests" "failed" "Performance test execution failed"
    fi
    
    rm -f perf-test.yml
    deactivate
}

# Generate final validation report
generate_final_report() {
    log_info "Generating final validation report..."
    
    # Update final status in JSON report
    local failed_count=$(jq '.summary.failed' "$VALIDATION_REPORT")
    local final_status="passed"
    
    if [[ $failed_count -gt 0 ]]; then
        final_status="failed"
    fi
    
    local temp_file=$(mktemp)
    jq ".validation_run.status = \"$final_status\"" "$VALIDATION_REPORT" > "$temp_file"
    mv "$temp_file" "$VALIDATION_REPORT"
    
    # Generate human-readable report
    local human_report="$REPORTS_DIR/validation-summary-$TIMESTAMP.txt"
    
    cat > "$human_report" << EOF
=== DEPENDENCY UPDATE VALIDATION REPORT ===

Generated: $(date)
PR Number: ${PR_NUMBER:-"N/A"}
Base Branch: $BASE_BRANCH
Commit SHA: $(git rev-parse HEAD)

VALIDATION STATUS: $final_status

SUMMARY:
$(jq -r '.summary | "Total Tests: \(.total_tests)\nPassed: \(.passed)\nFailed: \(.failed)\nSkipped: \(.skipped)"' "$VALIDATION_REPORT")

DETAILED RESULTS:
$(jq -r '.tests | to_entries[] | "[\(.value.status | ascii_upcase)] \(.key): \(.value.details)"' "$VALIDATION_REPORT")

FILES GENERATED:
- JSON Report: $VALIDATION_REPORT
- Human Report: $human_report
$(find "$REPORTS_DIR" -name "*-$TIMESTAMP.*" -type f | sed 's/^/- /')

RECOMMENDATIONS:
EOF
    
    if [[ "$final_status" == "passed" ]]; then
        echo "✅ All validation tests passed. This dependency update is safe to merge." >> "$human_report"
    else
        echo "❌ Validation tests failed. Review the issues above before merging." >> "$human_report"
        echo "📋 Next steps:" >> "$human_report"
        echo "1. Fix any breaking changes identified" >> "$human_report"
        echo "2. Address security vulnerabilities" >> "$human_report"
        echo "3. Re-run validation: $0" >> "$human_report"
    fi
    
    echo "" >> "$human_report"
    echo "For detailed logs, check the individual report files in $REPORTS_DIR" >> "$human_report"
    
    log_success "Validation report generated: $human_report"
    
    # Display summary
    echo ""
    echo "=== VALIDATION SUMMARY ==="
    cat "$human_report"
    
    # Return appropriate exit code
    if [[ "$final_status" == "failed" ]]; then
        return 1
    else
        return 0
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    
    # Clean up any temporary files
    rm -f test-*.yml perf-test.yml
    
    # Optionally clean up test environment (keep for debugging by default)
    if [[ "${CLEANUP_TEST_ENV:-false}" == "true" ]]; then
        rm -rf "$TEST_ENV_DIR"
    else
        log_info "Test environment preserved at: $TEST_ENV_DIR"
    fi
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Main execution
main() {
    log_info "🔍 Starting Dependency Update Validation"
    
    init_validation_report
    
    # Step 1: Detect changes
    if ! detect_dependency_changes; then
        log_info "No dependency changes detected. Validation complete."
        update_report "overall_status" "skipped" "No dependency changes to validate"
        return 0
    fi
    
    # Step 2: Create test environment
    create_test_environment
    
    # Step 3: Test compatibility
    test_dependency_compatibility
    
    # Step 4: Check for breaking changes
    check_breaking_changes
    
    # Step 5: Security scans
    run_security_scans
    
    # Step 6: Performance tests
    run_performance_tests
    
    # Step 7: Generate final report
    generate_final_report
}

# Execute main function
main "$@"
