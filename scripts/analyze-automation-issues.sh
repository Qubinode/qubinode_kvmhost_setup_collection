#!/bin/bash

# =============================================================================
# Automation Issue Analyzer - The "Detective"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script investigates and analyzes automation system issues, providing comprehensive
# diagnostics for both RHEL 10 compatibility and Ansible monitoring systems.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: System Discovery - Identifies available automation systems and logs
# 2. [PHASE 2]: RHEL 10 Analysis - Examines RHEL 10 compatibility issues and package conflicts
# 3. [PHASE 3]: Ansible Monitoring - Analyzes Ansible execution logs and performance metrics
# 4. [PHASE 4]: Issue Correlation - Cross-references issues between different systems
# 5. [PHASE 5]: Report Generation - Creates actionable issue reports with recommendations
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Analyzes: CI/CD pipeline failures and automation system issues
# - Monitors: RHEL 10 compatibility progress and blocking issues
# - Integrates: With GitHub Actions workflows and runner diagnostics
# - Reports: Issues to automation teams and project maintainers
# - Correlates: Issues across multiple automation systems for root cause analysis
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - INVESTIGATION: Uses systematic approach to identify root causes
# - CORRELATION: Links related issues across different systems
# - ACTIONABILITY: Provides specific recommendations for issue resolution
# - AUTOMATION: Designed for both manual troubleshooting and automated monitoring
# - COMPREHENSIVE: Covers multiple automation systems and issue types
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Systems: Add analysis functions for new automation systems
# - Issue Types: Extend issue detection for new problem categories
# - Reporting: Modify output format for new stakeholder requirements
# - Integration: Add hooks for new monitoring or alerting systems
# - Correlation Rules: Update issue correlation logic for new patterns
#
# 🚨 IMPORTANT FOR LLMs: This script is used for troubleshooting automation failures.
# It requires access to system logs and may need elevated permissions. Always review
# the generated reports for sensitive information before sharing.

# Automation Issue Analyzer
# This script analyzes and reports issues from both RHEL 10 and Ansible monitoring systems

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔍 Automation Systems Issue Analyzer${NC}"
echo -e "${CYAN}====================================${NC}"
echo "Date: $(date)"
echo "Project: $PROJECT_ROOT"
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

log_section() {
    echo -e "${PURPLE}📋 $1${NC}"
}

# Analyze RHEL 10 package issues
analyze_rhel10_issues() {
    log_section "RHEL 10 Package Availability Analysis"
    
    # Run RHEL 10 package check
    if [ -x "$SCRIPT_DIR/check-rhel10-packages.sh" ]; then
        log_info "Running RHEL 10 package availability check..."
        
        if "$SCRIPT_DIR/check-rhel10-packages.sh" "rhel10-analysis.json" > rhel10-output.log 2>&1; then
            log_success "RHEL 10 check completed successfully"
        else
            log_warning "RHEL 10 check completed with issues"
        fi
        
        # Parse and display results
        if [ -f "rhel10-analysis.json" ]; then
            echo ""
            echo -e "${BLUE}📊 RHEL 10 Package Status:${NC}"
            
            # Extract key information using basic tools
            AVAILABLE_COUNT=$(grep -o '"available_count": [0-9]*' rhel10-analysis.json | cut -d: -f2 | tr -d ' ' || echo "0")
            TOTAL_COUNT=$(grep -o '"unavailable_count": [0-9]*' rhel10-analysis.json | cut -d: -f2 | tr -d ' ' || echo "8")
            TOTAL_PACKAGES=$((AVAILABLE_COUNT + TOTAL_COUNT))
            
            echo -e "  Available: ${GREEN}$AVAILABLE_COUNT${NC}/$TOTAL_PACKAGES packages"
            echo -e "  Unavailable: ${RED}$TOTAL_COUNT${NC}/$TOTAL_PACKAGES packages"
            
            # Show specific issues
            echo ""
            echo -e "${RED}🚫 Specific Package Issues:${NC}"
            
            # Parse JSON for package-specific issues (basic parsing)
            grep -o '"[^"]*": {"available": false[^}]*}' rhel10-analysis.json | while IFS= read -r line; do
                PACKAGE=$(echo "$line" | cut -d'"' -f2)
                if echo "$line" | grep -q '"issue"'; then
                    ISSUE=$(echo "$line" | sed 's/.*"issue": "\([^"]*\)".*/\1/')
                    echo -e "  • ${YELLOW}$PACKAGE${NC}: $ISSUE"
                else
                    echo -e "  • ${YELLOW}$PACKAGE${NC}: Not available in UBI repositories"
                fi
            done
            
            echo ""
            echo -e "${CYAN}💡 Root Cause Analysis:${NC}"
            echo -e "  • ${BLUE}Container Limitation${NC}: UBI containers only include minimal package sets"
            echo -e "  • ${BLUE}Repository Access${NC}: Virtualization packages require full RHEL subscription"
            echo -e "  • ${BLUE}Package Distribution${NC}: Some packages only available on physical/VM systems"
            
        else
            log_error "RHEL 10 analysis file not found"
        fi
    else
        log_error "RHEL 10 check script not found or not executable"
    fi
}

# Analyze Ansible version issues
analyze_ansible_issues() {
    log_section "Ansible Version Compatibility Analysis"
    
    # Run Ansible version check
    if [ -x "$SCRIPT_DIR/check-ansible-versions.sh" ]; then
        log_info "Running Ansible version compatibility check..."
        
        if "$SCRIPT_DIR/check-ansible-versions.sh" "ansible-analysis.json" > ansible-output.log 2>&1; then
            log_success "Ansible check completed successfully"
        else
            log_warning "Ansible check completed with issues"
        fi
        
        # Parse and display results
        if [ -f "ansible-analysis.json" ]; then
            echo ""
            echo -e "${BLUE}📊 Ansible Version Status:${NC}"
            
            # Extract version information
            CURRENT_VERSION=$(grep -o '"current_version": "[^"]*"' ansible-analysis.json | cut -d'"' -f4 || echo "unknown")
            LATEST_VERSION=$(grep -o '"latest_version": "[^"]*"' ansible-analysis.json | cut -d'"' -f4 || echo "unknown")
            NEW_AVAILABLE=$(grep -o '"new_version_available": [^,]*' ansible-analysis.json | cut -d: -f2 | tr -d ' ,' || echo "false")
            
            echo -e "  Current Version: ${GREEN}$CURRENT_VERSION${NC}"
            echo -e "  Latest Version: ${CYAN}$LATEST_VERSION${NC}"
            echo -e "  Update Available: $([ "$NEW_AVAILABLE" = "true" ] && echo -e "${YELLOW}Yes${NC}" || echo -e "${GREEN}No${NC}")"
            
            # Analyze test results
            echo ""
            echo -e "${BLUE}🧪 Compatibility Test Results:${NC}"
            
            # Check current version test results
            if grep -q '"overall_success": true' ansible-analysis.json; then
                log_success "Current version ($CURRENT_VERSION) - All tests passed"
            else
                log_error "Current version ($CURRENT_VERSION) - Some tests failed"
                
                # Extract specific test failures
                echo -e "${RED}  Specific Issues:${NC}"
                if grep -q '"installation.*failed"' ansible-analysis.json; then
                    echo -e "    • Installation issues detected"
                fi
                if grep -q '"basic_functionality.*failed"' ansible-analysis.json; then
                    echo -e "    • Basic functionality problems"
                fi
                if grep -q '"ansible_lint.*failed"' ansible-analysis.json; then
                    echo -e "    • Ansible-lint compatibility issues"
                fi
            fi
            
            # Recommendations
            echo ""
            echo -e "${CYAN}💡 Recommendations:${NC}"
            if [ "$NEW_AVAILABLE" = "true" ]; then
                echo -e "  • ${BLUE}Action Required${NC}: New Ansible version available for testing"
                echo -e "  • ${BLUE}Next Step${NC}: Run automated workflow to test compatibility"
            else
                echo -e "  • ${GREEN}Status${NC}: Ansible version is current and compatible"
                echo -e "  • ${BLUE}Next Check${NC}: Automated monitoring continues weekly"
            fi
            
        else
            log_error "Ansible analysis file not found"
        fi
    else
        log_error "Ansible check script not found or not executable"
    fi
}

# Analyze GitHub Actions workflow issues
analyze_workflow_issues() {
    log_section "GitHub Actions Workflow Analysis"
    
    # Check if GitHub CLI is available
    if command -v gh &> /dev/null; then
        log_info "Analyzing recent workflow runs..."
        
        # Get recent workflow runs
        echo ""
        echo -e "${BLUE}📊 Recent Workflow Status:${NC}"
        
        # Check RHEL 10 monitoring workflow
        if gh run list --workflow=rhel10-auto-pr.yml --limit=3 --json status,conclusion,createdAt,displayTitle 2>/dev/null | grep -q "status"; then
            echo -e "${CYAN}RHEL 10 Package Monitoring:${NC}"
            gh run list --workflow=rhel10-auto-pr.yml --limit=3 2>/dev/null || echo "  No recent runs found"
        fi
        
        echo ""
        
        # Check Ansible version monitoring workflow
        if gh run list --workflow=ansible-version-auto-pr.yml --limit=3 --json status,conclusion,createdAt,displayTitle 2>/dev/null | grep -q "status"; then
            echo -e "${CYAN}Ansible Version Monitoring:${NC}"
            gh run list --workflow=ansible-version-auto-pr.yml --limit=3 2>/dev/null || echo "  No recent runs found"
        fi
        
        echo ""
        
        # Check main test workflow
        if gh run list --workflow=ansible-test.yml --limit=3 --json status,conclusion,createdAt,displayTitle 2>/dev/null | grep -q "status"; then
            echo -e "${CYAN}Main Test Pipeline:${NC}"
            gh run list --workflow=ansible-test.yml --limit=3 2>/dev/null || echo "  No recent runs found"
        fi
        
    else
        log_warning "GitHub CLI not available - cannot analyze workflow status"
        echo -e "  Install with: ${BLUE}brew install gh${NC} or ${BLUE}apt install gh${NC}"
    fi
}

# Generate comprehensive issue report
generate_issue_report() {
    log_section "Comprehensive Issue Report Generation"
    
    cat > "automation-issues-report.md" << EOF
# Automation Systems Issue Report

**Generated**: $(date)
**Project**: Qubinode KVM Host Setup Collection

## 🎯 Executive Summary

This report analyzes the current status and issues in our automated monitoring systems for RHEL 10 packages and Ansible versions.

## 📊 RHEL 10 Package Monitoring

### Current Status
- **Available Packages**: $(grep -o '"available_count": [0-9]*' rhel10-analysis.json 2>/dev/null | cut -d: -f2 | tr -d ' ' || echo "Unknown")/8
- **Status**: $([ -f rhel10-analysis.json ] && grep -q '"ready_for_pr": true' rhel10-analysis.json && echo "Ready for PR" || echo "Monitoring continues")

### Key Issues Identified
$(if [ -f rhel10-analysis.json ]; then
    echo "- UBI container limitations prevent access to virtualization packages"
    echo "- Full RHEL subscription required for production virtualization packages"
    echo "- Container testing validates role logic without full package stack"
else
    echo "- Unable to generate detailed analysis (check script execution)"
fi)

## 🚀 Ansible Version Monitoring

### Current Status
- **Current Version**: $(grep -o '"current_version": "[^"]*"' ansible-analysis.json 2>/dev/null | cut -d'"' -f4 || echo "Unknown")
- **Latest Version**: $(grep -o '"latest_version": "[^"]*"' ansible-analysis.json 2>/dev/null | cut -d'"' -f4 || echo "Unknown")
- **Update Available**: $(grep -o '"new_version_available": [^,]*' ansible-analysis.json 2>/dev/null | cut -d: -f2 | tr -d ' ,' || echo "Unknown")

### Compatibility Status
$(if [ -f ansible-analysis.json ] && grep -q '"overall_success": true' ansible-analysis.json; then
    echo "- ✅ All compatibility tests passing"
    echo "- ✅ Current version fully functional"
else
    echo "- ⚠️ Some compatibility issues detected"
    echo "- 🔍 Manual review recommended"
fi)

## 🔧 Recommended Actions

### Immediate Actions
1. **RHEL 10**: Continue monitoring - packages not yet available in UBI
2. **Ansible**: $([ -f ansible-analysis.json ] && grep -q '"update_recommended": true' ansible-analysis.json && echo "Review and test new version" || echo "No action needed - current version optimal")

### Long-term Monitoring
1. **Weekly Reviews**: Check automation system reports
2. **Issue Tracking**: Monitor for new package availability patterns
3. **Testing Validation**: Ensure automated tests remain comprehensive

## 📈 System Health

### Automation Status
- **RHEL 10 Monitoring**: $([ -x "$SCRIPT_DIR/check-rhel10-packages.sh" ] && echo "✅ Operational" || echo "❌ Issues detected")
- **Ansible Monitoring**: $([ -x "$SCRIPT_DIR/check-ansible-versions.sh" ] && echo "✅ Operational" || echo "❌ Issues detected")
- **GitHub Integration**: $(command -v gh &> /dev/null && echo "✅ Available" || echo "⚠️ Limited (no GitHub CLI)")

---

*This report is automatically generated by the automation issue analyzer.*
*For detailed logs, check: rhel10-output.log, ansible-output.log*
EOF

    log_success "Comprehensive issue report generated: automation-issues-report.md"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"
    
    # Run all analyses
    analyze_rhel10_issues
    echo ""
    analyze_ansible_issues
    echo ""
    analyze_workflow_issues
    echo ""
    generate_issue_report
    
    echo ""
    log_section "Analysis Complete"
    echo -e "${GREEN}✅ Issue analysis completed successfully${NC}"
    echo -e "${BLUE}📄 Reports generated:${NC}"
    echo -e "  • automation-issues-report.md - Comprehensive summary"
    echo -e "  • rhel10-analysis.json - RHEL 10 detailed data"
    echo -e "  • ansible-analysis.json - Ansible detailed data"
    echo -e "  • rhel10-output.log - RHEL 10 execution log"
    echo -e "  • ansible-output.log - Ansible execution log"
}

# Run main function
main "$@"
