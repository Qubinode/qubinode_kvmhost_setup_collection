#!/bin/bash
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

run_enhanced_scanner() {
    local severity="$1"
    local format="$2"
    local extra_args="${3:-}"
    
    log_info "Running enhanced dependency scanner (severity: $severity, format: $format)"
    
    if [[ -x "$PROJECT_ROOT/scripts/enhanced-dependency-scanner.sh" ]]; then
        "$PROJECT_ROOT/scripts/enhanced-dependency-scanner.sh" \
            --severity "$severity" \
            --format "$format" \
            $extra_args
    else
        log_error "Enhanced dependency scanner not found or not executable"
        log_info "Please ensure scripts/enhanced-dependency-scanner.sh exists and is executable"
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
    if run_enhanced_scanner "critical" "table" ""; then
        log_success "No critical vulnerabilities found"
    else
        local exit_code=$?
        if [[ $exit_code -eq 5 ]]; then
            log_error "Critical vulnerabilities found! Please fix before committing."
            return 1
        elif [[ $exit_code -eq 4 ]]; then
            log_warning "High severity vulnerabilities found. Consider fixing before commit."
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
    
    # Run medium+ severity scan
    if run_enhanced_scanner "medium" "table" ""; then
        log_success "No medium+ severity vulnerabilities found"
    else
        local exit_code=$?
        if [[ $exit_code -ge 4 ]]; then
            log_error "High or critical vulnerabilities found! Please fix before pushing."
            return 1
        elif [[ $exit_code -eq 3 ]]; then
            log_warning "Medium severity vulnerabilities found. Consider fixing."
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
    
    # Comprehensive scan with all dependency types
    if run_enhanced_scanner "low" "json" "$extra_args"; then
        log_success "No vulnerabilities found - ready for release!"
    else
        local exit_code=$?
        case $exit_code in
            5) log_error "CRITICAL vulnerabilities found - BLOCK RELEASE"; return 1 ;;
            4) log_error "HIGH vulnerabilities found - BLOCK RELEASE"; return 1 ;;
            3) log_warning "MEDIUM vulnerabilities found - review required" ;;
            2) log_info "LOW vulnerabilities found - acceptable for release" ;;
        esac
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
    
    # Run comprehensive scan with detailed reporting
    if run_enhanced_scanner "low" "json" "--report-dir $report_dir"; then
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
    if run_enhanced_scanner "critical" "table" "--python"; then
        log_success "✅ No critical Python vulnerabilities found"
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
