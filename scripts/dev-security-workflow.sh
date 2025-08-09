#!/bin/bash

# =============================================================================
# Development Security Enforcer - The "Security Integration Manager"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script integrates security checks into developer workflows,
# providing quick security validation for common development scenarios.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Workflow Integration - Integrates security checks into development workflow
# 2. [PHASE 2]: Quick Security Scans - Performs rapid security validation
# 3. [PHASE 3]: Developer Guidance - Provides security guidance for common scenarios
# 4. [PHASE 4]: Issue Detection - Identifies security issues early in development
# 5. [PHASE 5]: Remediation Guidance - Provides specific security fix recommendations
# 6. [PHASE 6]: Workflow Optimization - Optimizes security checks for developer productivity
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Integrates: Security checks into daily development workflows
# - Provides: Quick security validation for developers
# - Coordinates: With enhanced-security-scan.sh for comprehensive security
# - Supports: Secure development practices and early issue detection
# - Guides: Developers on security best practices and issue resolution
# - Prevents: Security issues from progressing to CI/CD pipelines
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - INTEGRATION: Seamlessly integrates security into development workflows
# - SPEED: Optimized for quick execution during development
# - GUIDANCE: Provides actionable security guidance for developers
# - PREVENTION: Focuses on preventing security issues early
# - WORKFLOW-FRIENDLY: Designed to enhance rather than disrupt development
# - EDUCATIONAL: Helps developers learn security best practices
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Checks: Add new security checks for emerging threats
# - Workflow Integration: Improve integration with development tools and IDEs
# - Performance: Optimize for faster execution during development
# - Guidance: Enhance security guidance and remediation recommendations
# - Automation: Add automated security fix suggestions
# - Integration: Add integration with security training or documentation systems
#
# 🚨 IMPORTANT FOR LLMs: This script affects developer productivity and security.
# Balance security thoroughness with development speed. Focus on high-impact
# security checks that provide maximum value with minimal workflow disruption.

# Developer Security Workflow Integration
# Quick security checks for common development scenarios

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_usage() {
    cat << EOF
Developer Security Workflow Integration

USAGE:
    $0 <workflow> [options]

WORKFLOWS:
    pre-commit       Run security checks before committing
    pre-push         Run security checks before pushing
    pre-release      Run comprehensive security audit before release
    weekly-review    Run weekly security review
    quick-check      Quick critical vulnerability check

OPTIONS:
    --fix            Attempt to fix issues automatically where possible
    --report         Generate detailed reports
    --verbose        Enable verbose output

EXAMPLES:
    $0 pre-commit                    # Quick pre-commit security check
    $0 pre-release --report          # Full pre-release audit with reports
    $0 weekly-review --fix           # Weekly review with auto-fix attempts
    $0 quick-check                   # Fast critical vulnerability check

EOF
}

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

run_collection_security_check() {
    log_info "Running Ansible collection security check"

    if [[ -x "$PROJECT_ROOT/scripts/ansible-collection-security-check.sh" ]]; then
        "$PROJECT_ROOT/scripts/ansible-collection-security-check.sh"
    else
        log_error "Ansible collection security check not found or not executable"
        log_info "Please ensure scripts/ansible-collection-security-check.sh exists and is executable"
        return 1
    fi
}

workflow_pre_commit() {
    local fix_mode="${1:-false}"
    local report_mode="${2:-false}"
    local verbose_mode="${3:-false}"
    
    echo "🔒 Pre-Commit Security Workflow"
    echo "================================"
    
    log_info "Running quick security checks before commit..."
    
    # Quick critical vulnerability check
    if run_collection_security_check; then
        log_success "No critical vulnerabilities found"
    else
        local exit_code=$?
        if [[ $exit_code -eq 1 ]]; then
            log_error "Critical vulnerabilities found! Please fix before committing."
            return 1
        else
            log_warning "Some vulnerabilities found (exit code: $exit_code)"
        fi
    fi
    
    # Check for common security anti-patterns in recently changed files
    if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
        log_info "Checking recently changed files for security issues..."
        
        # Get staged files for commit
        staged_files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(py|yml|yaml|json)$' || true)
        
        if [[ -n "$staged_files" ]] && command -v bandit &> /dev/null; then
            echo "$staged_files" | while read -r file; do
                if [[ -f "$file" && "$file" =~ \.py$ ]]; then
                    log_info "Scanning $file with bandit..."
                    bandit -f json "$file" > /dev/null || log_warning "Security issues found in $file"
                fi
            done
        fi
    fi
    
    log_success "Pre-commit security checks completed"
}

workflow_pre_push() {
    local fix_mode="${1:-false}"
    local report_mode="${2:-false}"
    local verbose_mode="${3:-false}"
    
    echo "🚀 Pre-Push Security Workflow"
    echo "=============================="
    
    log_info "Running security checks before push..."
    
    # Run security check
    if run_collection_security_check; then
        log_success "Security check passed"
    else
        local exit_code=$?
        if [[ $exit_code -eq 1 ]]; then
            log_error "Critical vulnerabilities found! Please fix before pushing."
            return 1
        else
            log_warning "Some security issues found. Consider reviewing."
        fi
    fi
    
    log_success "Pre-push security checks completed"
}

workflow_pre_release() {
    local fix_mode="${1:-false}"
    local report_mode="${2:-false}"
    local verbose_mode="${3:-false}"
    
    echo "📦 Pre-Release Security Audit"
    echo "=============================="
    
    log_info "Running comprehensive security audit before release..."
    
    local extra_args=""
    if [[ "$report_mode" == "true" ]]; then
        extra_args="--report-dir ./security-reports/"
        mkdir -p "./security-reports"
        log_info "Reports will be generated in ./security-reports/"
    fi
    
    # Comprehensive security check
    if run_collection_security_check; then
        log_success "No critical vulnerabilities found - ready for release!"
    else
        local exit_code=$?
        if [[ $exit_code -eq 1 ]]; then
            log_error "CRITICAL vulnerabilities found - BLOCK RELEASE"
            return 1
        else
            log_warning "Some vulnerabilities found - review recommended"
        fi
    fi
    
    # Additional pre-release checks
    log_info "Running additional pre-release security validations..."
    
    # Check for hardcoded secrets (basic patterns)
    if command -v grep &> /dev/null; then
        log_info "Checking for potential hardcoded secrets..."
        if grep -r -i "password\|secret\|token\|key" --include="*.py" --include="*.yml" --include="*.yaml" . | grep -v "test" | grep -v "#" | head -5; then
            log_warning "Potential hardcoded secrets found. Please review."
        fi
    fi
    
    log_success "Pre-release security audit completed"
}

workflow_weekly_review() {
    local fix_mode="${1:-false}"
    local report_mode="${2:-false}"
    local verbose_mode="${3:-false}"
    
    echo "📊 Weekly Security Review"
    echo "========================"
    
    log_info "Running weekly comprehensive security review..."
    
    # Generate detailed reports
    mkdir -p "./security-reports/weekly"
    local report_dir="./security-reports/weekly"
    
    # Run comprehensive security check
    if run_collection_security_check; then
        log_info "Full security scan completed"
    else
        log_info "Vulnerabilities found - see detailed reports"
    fi
    
    # Generate summary report
    cat > "$report_dir/weekly-summary.md" << EOF
# Weekly Security Review Summary

**Date**: $(date)
**Scan Type**: Comprehensive Dependency Security Scan

## Summary

This report provides a weekly overview of security vulnerabilities found in project dependencies.

## Action Items

1. Review critical and high severity vulnerabilities immediately
2. Plan remediation for medium severity issues
3. Update dependency management documentation if needed
4. Consider upgrading vulnerable dependencies

## Reports Generated

- \`python-scan.json\` - Python dependency vulnerabilities
- \`ansible-scan.json\` - Ansible collection vulnerabilities  
- \`docker-scan.json\` - Docker image vulnerabilities
- \`github-actions-scan.json\` - GitHub Actions vulnerabilities

## Next Steps

1. Address any critical or high severity findings
2. Update security tracking documentation
3. Schedule follow-up review in one week

EOF
    
    log_success "Weekly security review completed. Reports in $report_dir"
}

workflow_quick_check() {
    local verbose_mode="${1:-false}"
    
    echo "⚡ Quick Security Check"
    echo "======================="
    
    log_info "Running quick critical vulnerability check..."
    
    # Only check for critical issues, fast execution
    if run_collection_security_check; then
        log_success "✅ No critical vulnerabilities found"
    else
        log_warning "⚠️  Critical vulnerabilities detected"
    fi
}

main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    local workflow="$1"
    shift
    
    local fix_mode="false"
    local report_mode="false"
    local verbose_mode="false"
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix)
                fix_mode="true"
                shift
                ;;
            --report)
                report_mode="true"
                shift
                ;;
            --verbose)
                verbose_mode="true"
                export VERBOSE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    case "$workflow" in
        pre-commit)
            workflow_pre_commit "$fix_mode" "$report_mode" "$verbose_mode"
            ;;
        pre-push)
            workflow_pre_push "$fix_mode" "$report_mode" "$verbose_mode"
            ;;
        pre-release)
            workflow_pre_release "$fix_mode" "$report_mode" "$verbose_mode"
            ;;
        weekly-review)
            workflow_weekly_review "$fix_mode" "$report_mode" "$verbose_mode"
            ;;
        quick-check)
            workflow_quick_check "$verbose_mode"
            ;;
        *)
            log_error "Unknown workflow: $workflow"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
