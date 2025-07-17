#!/bin/bash

# Enhanced Security Scan Script
# Performs comprehensive security analysis of the collection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORT_DIR="$PROJECT_ROOT/security-reports"
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
    log_info "Starting enhanced security scan..."
    
    # Create report directory
    mkdir -p "$REPORT_DIR"
    
    # Initialize counters
    ISSUES_FOUND=0
    WARNINGS_FOUND=0
    
    # Run security checks
    check_ansible_security
    check_file_permissions
    check_secrets_exposure
    check_dependency_vulnerabilities
    
    # Generate summary
    generate_security_summary
    
    log_info "Security scan completed"
    
    # Exit with appropriate code
    if [[ $ISSUES_FOUND -gt 0 ]]; then
        log_error "Security issues found: $ISSUES_FOUND"
        exit 1
    else
        log_success "No security issues found"
        exit 0
    fi
}

check_ansible_security() {
    log_info "Checking Ansible security best practices..."
    
    # Check for hardcoded credentials
    log_info "Scanning for hardcoded credentials..."
    if grep -r -i "password\|secret\|key" --include="*.yml" --include="*.yaml" roles/ 2>/dev/null | grep -v "# " | grep -v "{{" | head -5; then
        log_warning "Potential hardcoded credentials found (check if they're examples)"
        ((WARNINGS_FOUND++))
    else
        log_success "No obvious hardcoded credentials found"
    fi
    
    # Check for become usage
    log_info "Checking become/sudo usage..."
    BECOME_COUNT=$(grep -r "become:" roles/ --include="*.yml" 2>/dev/null | wc -l)
    log_info "Found $BECOME_COUNT tasks using become (privilege escalation)"
    
    # Check for shell/command tasks
    log_info "Checking for shell/command tasks..."
    SHELL_COUNT=$(grep -r "shell:\|command:" roles/ --include="*.yml" 2>/dev/null | wc -l)
    if [[ $SHELL_COUNT -gt 10 ]]; then
        log_warning "High number of shell/command tasks found: $SHELL_COUNT (consider using modules)"
        ((WARNINGS_FOUND++))
    else
        log_success "Reasonable number of shell/command tasks: $SHELL_COUNT"
    fi
}

check_file_permissions() {
    log_info "Checking file permissions..."
    
    # Check for world-writable files
    WORLD_WRITABLE=$(find "$PROJECT_ROOT" -type f -perm -002 2>/dev/null | grep -v ".git" | wc -l)
    if [[ $WORLD_WRITABLE -gt 0 ]]; then
        log_warning "Found $WORLD_WRITABLE world-writable files"
        ((WARNINGS_FOUND++))
    else
        log_success "No world-writable files found"
    fi
    
    # Check for executable scripts
    EXECUTABLE_COUNT=$(find "$PROJECT_ROOT/scripts" -type f -executable 2>/dev/null | wc -l)
    log_info "Found $EXECUTABLE_COUNT executable scripts"
}

check_secrets_exposure() {
    log_info "Checking for exposed secrets..."
    
    # Common secret patterns
    SECRET_PATTERNS=(
        "api[_-]?key"
        "secret[_-]?key"
        "access[_-]?token"
        "auth[_-]?token"
        "password"
        "passwd"
        "private[_-]?key"
    )
    
    SECRETS_FOUND=0
    for pattern in "${SECRET_PATTERNS[@]}"; do
        if grep -r -i "$pattern" --include="*.yml" --include="*.yaml" --include="*.json" . 2>/dev/null | grep -v "# " | grep -v "example" | grep -v "template" | head -1 > /dev/null; then
            ((SECRETS_FOUND++))
        fi
    done
    
    if [[ $SECRETS_FOUND -gt 0 ]]; then
        log_warning "Potential secrets found: $SECRETS_FOUND patterns matched"
        ((WARNINGS_FOUND++))
    else
        log_success "No obvious secrets found"
    fi
}

check_dependency_vulnerabilities() {
    log_info "Checking for dependency vulnerabilities..."
    
    # Check if requirements.txt exists
    if [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
        log_success "requirements.txt found"
        
        # Basic vulnerability check (would use safety in production)
        if command -v safety &> /dev/null; then
            log_info "Running safety check..."
            if safety check -r "$PROJECT_ROOT/requirements.txt" --json > "$REPORT_DIR/safety-report-$TIMESTAMP.json" 2>/dev/null; then
                log_success "Safety check passed"
            else
                log_warning "Safety check found potential vulnerabilities"
                ((WARNINGS_FOUND++))
            fi
        else
            log_info "Safety tool not available (install with: pip install safety)"
        fi
    else
        log_warning "requirements.txt not found"
        ((WARNINGS_FOUND++))
    fi
}

generate_security_summary() {
    log_info "Generating security summary..."
    
    SUMMARY_FILE="$REPORT_DIR/security-summary-$TIMESTAMP.json"
    
    cat > "$SUMMARY_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "scan_results": {
    "issues_found": $ISSUES_FOUND,
    "warnings_found": $WARNINGS_FOUND,
    "status": "$([ $ISSUES_FOUND -eq 0 ] && echo "passed" || echo "failed")"
  },
  "checks_performed": [
    "ansible_security_practices",
    "file_permissions",
    "secrets_exposure",
    "dependency_vulnerabilities"
  ],
  "recommendations": [
    "Use Ansible Vault for sensitive data",
    "Follow principle of least privilege",
    "Regular dependency updates",
    "Code review for security"
  ]
}
EOF
    
    # Create a simple text summary for the workflow
    cat > "$REPORT_DIR/security-scan-summary.txt" << EOF
Security Scan Summary
====================
Timestamp: $TIMESTAMP
Issues Found: $ISSUES_FOUND
Warnings Found: $WARNINGS_FOUND
Status: $([ $ISSUES_FOUND -eq 0 ] && echo "PASSED" || echo "FAILED")

Recommendations:
- Use Ansible Vault for sensitive data
- Follow principle of least privilege
- Regular dependency updates
- Code review for security practices
EOF
    
    log_success "Security summary generated: $SUMMARY_FILE"
}

# Show help
show_help() {
    cat << EOF
Enhanced Security Scan Script

Usage: $0 [options]

Options:
  -h, --help    Show this help message

This script performs:
- Ansible security best practices check
- File permissions analysis
- Secrets exposure detection
- Dependency vulnerability assessment

Generates security reports in security-reports/
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
