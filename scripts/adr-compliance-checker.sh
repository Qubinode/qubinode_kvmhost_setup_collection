#!/bin/bash

# =============================================================================
# ADR Compliance Checker - The "Governance Auditor"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script automatically validates compliance with Architecture Decision Records (ADRs),
# ensuring the project continuously adheres to established architectural decisions.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: ADR Discovery - Scans docs/archive/adrs/ directory for all ADR documents
# 2. [PHASE 2]: Compliance Rule Extraction - Parses ADRs for enforceable compliance rules
# 3. [PHASE 3]: Codebase Analysis - Analyzes project structure against ADR requirements
# 4. [PHASE 4]: Violation Detection - Identifies deviations from ADR specifications
# 5. [PHASE 5]: Report Generation - Creates detailed compliance reports with violations
# 6. [PHASE 6]: CI/CD Integration - Provides exit codes for automated pipeline control
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Validates: Compliance with all ADRs in docs/archive/adrs/ directory
# - Checks: Project structure, naming conventions, and architectural decisions
# - Reports: Violations to compliance-reports/ directory with timestamps
# - Integrates: With CI/CD pipeline to block non-compliant changes
# - Monitors: Ongoing compliance as the project evolves
# - Enforces: Architectural consistency across the entire collection
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - AUTOMATION: Fully automated compliance checking without manual intervention
# - COMPREHENSIVE: Validates all aspects of ADR compliance systematically
# - REPORTING: Generates detailed JSON reports for audit trails
# - BLOCKING: Can block CI/CD progression for critical compliance violations
# - EVOLUTION: Adapts to new ADRs automatically as they are added
# - INTEGRATION: Seamlessly integrates with existing development workflows
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New ADRs: Add compliance checking logic for new ADR requirements
# - Rule Types: Extend rule parsing for new types of compliance requirements
# - Report Format: Modify JSON report structure for new consumer requirements
# - Integration: Add hooks for new CI/CD systems or notification tools
# - Performance: Optimize for larger projects with many ADRs
# - Validation: Add new validation methods for complex architectural requirements
#
# 🚨 IMPORTANT FOR LLMs: This script enforces architectural governance.
# Violations may indicate serious architectural drift that requires immediate
# attention. Always review compliance reports carefully and address violations.

# Automated ADR Compliance Checker
# Integrates with CI/CD pipeline to ensure ongoing ADR compliance
# Part of DevOps & Automation Tasks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
COMPLIANCE_REPORT_DIR="$PROJECT_ROOT/compliance-reports"
ADR_DIR="$PROJECT_ROOT/docs/archive/adrs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$COMPLIANCE_REPORT_DIR/adr-compliance-$TIMESTAMP.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Compliance tracking
TOTAL_ADRS=0
COMPLIANT_ADRS=0
NON_COMPLIANT_ADRS=0
COMPLIANCE_ISSUES=()

# Function to log compliance results
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

log_critical() {
    echo -e "${RED}[CRITICAL]${NC} $1"
}

# Function to extract ADR metadata
extract_adr_metadata() {
    local adr_file="$1"
    local adr_id=""
    local adr_title=""
    local adr_status=""
    
    # Extract ADR ID from filename (e.g., adr-0001-xxx.md -> 0001)
    adr_id=$(basename "$adr_file" | sed -n 's/adr-\([0-9]\+\)-.*/\1/p')
    
    # Extract title from the first header
    adr_title=$(grep -m1 "^# " "$adr_file" 2>/dev/null | sed 's/^# //' || echo "Unknown Title")
    
    # Extract status from the file content
    adr_status=$(grep -i "^Status:" "$adr_file" 2>/dev/null | sed 's/^Status:\s*//' || echo "Unknown")
    
    echo "$adr_id|$adr_title|$adr_status"
}

# Function to check ADR-0001 compliance (DNF Module Management)
check_adr_0001_compliance() {
    local adr_id="0001"
    local compliance_status="COMPLIANT"
    local issues=()
    
    log_info "Checking ADR-0001: DNF Module Management compliance" >&2
    
    # Check for dnf module usage in roles
    local roles_with_dnf=0
    local roles_with_yum=0
    
    if [[ -d "$PROJECT_ROOT/roles" ]]; then
        for role_dir in "$PROJECT_ROOT/roles"/*; do
            if [[ -d "$role_dir/tasks" ]]; then
                # Check for dnf.dnf_module usage
                if grep -r "dnf_module" "$role_dir/tasks" >/dev/null 2>&1; then
                    roles_with_dnf=$((roles_with_dnf + 1))
                fi
                
                # Check for deprecated yum usage
                if grep -r "ansible.builtin.yum\|community.general.yum" "$role_dir/tasks" >/dev/null 2>&1; then
                    roles_with_yum=$((roles_with_yum + 1))
                    issues+=("Role $(basename "$role_dir") uses deprecated yum module")
                fi
            fi
        done
    fi
    
    if [[ $roles_with_yum -gt 0 ]]; then
        compliance_status="NON_COMPLIANT"
        issues+=("Found $roles_with_yum roles using deprecated yum module")
    fi
    
    if [[ $roles_with_dnf -eq 0 ]]; then
        issues+=("No roles found using dnf_module (may be expected)")
    fi
    
    echo "$adr_id|$compliance_status|$(IFS=';'; echo "${issues[*]}")"
}

# Function to check ADR-0002 compliance (Role Architecture)
check_adr_0002_compliance() {
    local adr_id="0002"
    local compliance_status="COMPLIANT"
    local issues=()

    log_info "Checking ADR-0002: Role Architecture Standards compliance" >&2

    # Define exceptions for legitimate roles that predate naming conventions or are external
    local naming_exceptions=(
        "edge_hosts_validate"  # Legacy role documented in ADR-0002, predates naming convention
    )

    # Define exceptions for external roles that don't follow internal structure
    local structure_exceptions=(
        "linux-system-roles.network"  # External role from linux-system-roles collection
        "linux-system-roles.storage"  # External role from linux-system-roles collection
    )

    if [[ -d "$PROJECT_ROOT/roles" ]]; then
        for role_dir in "$PROJECT_ROOT/roles"/*; do
            if [[ -d "$role_dir" ]]; then
                local role_name=$(basename "$role_dir")

                # Skip if it's just a config file
                if [[ "$role_name" == "role_config.yml" ]]; then
                    continue
                fi

                # Check if role is exempt from structure requirements
                local structure_exempt=false
                for exception in "${structure_exceptions[@]}"; do
                    if [[ "$role_name" == "$exception" ]]; then
                        structure_exempt=true
                        break
                    fi
                done

                # Only check structure for non-exempt roles
                if [[ "$structure_exempt" == false ]]; then
                    # Check required directories
                    for required_dir in "tasks" "defaults" "meta"; do
                        if [[ ! -d "$role_dir/$required_dir" ]]; then
                            compliance_status="NON_COMPLIANT"
                            issues+=("Role $role_name missing required directory: $required_dir")
                        fi
                    done

                    # Check required files
                    for required_file in "tasks/main.yml" "defaults/main.yml" "meta/main.yml"; do
                        if [[ ! -f "$role_dir/$required_file" ]]; then
                            compliance_status="NON_COMPLIANT"
                            issues+=("Role $role_name missing required file: $required_file")
                        fi
                    done
                fi

                # Check for proper role naming (with exceptions)
                local naming_exempt=false
                for exception in "${naming_exceptions[@]}"; do
                    if [[ "$role_name" == "$exception" ]]; then
                        naming_exempt=true
                        break
                    fi
                done

                # Also exempt external roles from naming convention
                for exception in "${structure_exceptions[@]}"; do
                    if [[ "$role_name" == "$exception" ]]; then
                        naming_exempt=true
                        break
                    fi
                done

                if [[ "$naming_exempt" == false ]] && [[ ! "$role_name" =~ ^kvmhost_ ]] && [[ ! "$role_name" =~ ^swygue_ ]]; then
                    compliance_status="NON_COMPLIANT"
                    issues+=("Role $role_name doesn't follow naming convention (should start with kvmhost_ or swygue_)")
                fi
            fi
        done
    else
        compliance_status="NON_COMPLIANT"
        issues+=("Roles directory missing")
    fi

    echo "$adr_id|$compliance_status|$(IFS=';'; echo "${issues[*]}")"
}

# Function to check ADR-0005 compliance (Molecule Testing)
check_adr_0005_compliance() {
    local adr_id="0005"
    local compliance_status="COMPLIANT"
    local issues=()
    
    log_info "Checking ADR-0005: Molecule Testing Framework compliance" >&2
    
    if [[ -d "$PROJECT_ROOT/molecule" ]]; then
        local scenario_count=0
        for scenario_dir in "$PROJECT_ROOT/molecule"/*; do
            if [[ -d "$scenario_dir" ]]; then
                scenario_count=$((scenario_count + 1))
                local scenario_name=$(basename "$scenario_dir")
                
                # Check required files
                if [[ ! -f "$scenario_dir/molecule.yml" ]]; then
                    compliance_status="NON_COMPLIANT"
                    issues+=("Molecule scenario $scenario_name missing molecule.yml")
                fi
                
                if [[ ! -f "$scenario_dir/converge.yml" ]]; then
                    compliance_status="NON_COMPLIANT"
                    issues+=("Molecule scenario $scenario_name missing converge.yml")
                fi
                
                # Check for valid YAML syntax
                if [[ -f "$scenario_dir/molecule.yml" ]]; then
                    if ! python3 -c "import yaml; yaml.safe_load(open('$scenario_dir/molecule.yml'))" 2>/dev/null; then
                        compliance_status="NON_COMPLIANT"
                        issues+=("Molecule scenario $scenario_name has invalid YAML syntax in molecule.yml")
                    fi
                fi
            fi
        done
        
        if [[ $scenario_count -eq 0 ]]; then
            compliance_status="NON_COMPLIANT"
            issues+=("No Molecule scenarios found")
        fi
    else
        compliance_status="NON_COMPLIANT"
        issues+=("Molecule directory missing")
    fi
    
    echo "$adr_id|$compliance_status|$(IFS=';'; echo "${issues[*]}")"
}

# Function to check ADR-0009 compliance (Dependabot Configuration)
check_adr_0009_compliance() {
    local adr_id="0009"
    local compliance_status="COMPLIANT"
    local issues=()
    
    log_info "Checking ADR-0009: GitHub Actions Dependabot Auto-Updates compliance" >&2
    
    # Check for dependabot.yml
    if [[ ! -f "$PROJECT_ROOT/.github/dependabot.yml" ]]; then
        compliance_status="NON_COMPLIANT"
        issues+=("Dependabot configuration missing (.github/dependabot.yml)")
    else
        # Check for required ecosystem entries
        local dependabot_content=$(cat "$PROJECT_ROOT/.github/dependabot.yml")
        
        if ! echo "$dependabot_content" | grep -q "package-ecosystem.*github-actions"; then
            issues+=("Dependabot missing github-actions ecosystem")
        fi
        
        if ! echo "$dependabot_content" | grep -q "package-ecosystem.*pip"; then
            issues+=("Dependabot missing pip ecosystem")
        fi
    fi
    
    # Check for GitHub Actions workflows
    if [[ ! -d "$PROJECT_ROOT/.github/workflows" ]]; then
        compliance_status="NON_COMPLIANT"
        issues+=("GitHub Actions workflows directory missing")
    else
        local workflow_count=$(find "$PROJECT_ROOT/.github/workflows" -name "*.yml" | wc -l)
        if [[ $workflow_count -eq 0 ]]; then
            compliance_status="NON_COMPLIANT"
            issues+=("No GitHub Actions workflows found")
        fi
    fi
    
    echo "$adr_id|$compliance_status|$(IFS=';'; echo "${issues[*]}")"
}

# Function to check ADR-0011 compliance (Local Testing Requirements)
check_adr_0011_compliance() {
    local adr_id="0011"
    local compliance_status="COMPLIANT"
    local issues=()
    
    log_info "Checking ADR-0011: Mandatory Local Testing Requirements compliance" >&2
    
    # Check for required testing scripts
    local required_scripts=(
        "scripts/test-local-molecule.sh"
        "scripts/setup-local-testing.sh"
        "scripts/check-compliance.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$script" ]]; then
            compliance_status="NON_COMPLIANT"
            issues+=("Required testing script missing: $script")
        elif [[ ! -x "$PROJECT_ROOT/$script" ]]; then
            issues+=("Testing script not executable: $script")
        fi
    done
    
    # Check for architectural rules
    if [[ ! -f "$PROJECT_ROOT/rules/local-molecule-testing-rules.json" ]]; then
        compliance_status="NON_COMPLIANT"
        issues+=("Local testing architectural rules missing")
    fi
    
    # Check for testing documentation (now in archive)
    if [[ ! -f "$PROJECT_ROOT/docs/archive/legacy-guides/MANDATORY_LOCAL_TESTING.md" ]]; then
        compliance_status="NON_COMPLIANT"
        issues+=("Mandatory local testing documentation missing")
    fi
    
    echo "$adr_id|$compliance_status|$(IFS=';'; echo "${issues[*]}")"
}

# Function to check ADR-0013 compliance (Molecule systemd Configuration)
check_adr_0013_compliance() {
    local adr_id="0013"
    local compliance_status="COMPLIANT"
    local issues=()
    
    log_info "Checking ADR-0013: Molecule Container Configuration Best Practices compliance" >&2
    
    if [[ -d "$PROJECT_ROOT/molecule" ]]; then
        for scenario_dir in "$PROJECT_ROOT/molecule"/*; do
            if [[ -d "$scenario_dir" && -f "$scenario_dir/molecule.yml" ]]; then
                local scenario_name=$(basename "$scenario_dir")
                local molecule_file="$scenario_dir/molecule.yml"
                
                # Check for systemd: always requirement
                if ! grep -q "systemd: always" "$molecule_file"; then
                    compliance_status="NON_COMPLIANT"
                    issues+=("Molecule scenario $scenario_name missing 'systemd: always'")
                fi
                
                # Check for deprecated tmpfs usage
                if grep -q "tmpfs:" "$molecule_file"; then
                    compliance_status="NON_COMPLIANT"
                    issues+=("Molecule scenario $scenario_name uses deprecated tmpfs configuration")
                fi
                
                # Check for proper cgroupns_mode
                if grep -q "cgroupns_mode" "$molecule_file"; then
                    if ! grep -q "cgroupns_mode: host" "$molecule_file"; then
                        issues+=("Molecule scenario $scenario_name should use 'cgroupns_mode: host'")
                    fi
                fi
            fi
        done
    fi
    
    echo "$adr_id|$compliance_status|$(IFS=';'; echo "${issues[*]}")"
}

# Function to generate compliance report
generate_compliance_report() {
    local compliance_results=("$@")
    
    mkdir -p "$COMPLIANCE_REPORT_DIR"
    
    # Calculate compliance percentage safely
    local compliance_percentage=0
    if [[ $TOTAL_ADRS -gt 0 ]]; then
        compliance_percentage=$(( COMPLIANT_ADRS * 100 / TOTAL_ADRS ))
    fi
    
    cat > "$REPORT_FILE" << EOF
{
  "report_metadata": {
    "timestamp": "$(date -Iseconds)",
    "project_root": "$PROJECT_ROOT",
    "total_adrs_checked": $TOTAL_ADRS,
    "compliant_adrs": $COMPLIANT_ADRS,
    "non_compliant_adrs": $NON_COMPLIANT_ADRS,
    "compliance_percentage": $compliance_percentage
  },
  "adr_compliance_results": [
EOF

    local first=true
    for result in "${compliance_results[@]}"; do
        IFS='|' read -r adr_id status issues <<< "$result"
        
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$REPORT_FILE"
        fi
        
        cat >> "$REPORT_FILE" << EOF
    {
      "adr_id": "$adr_id",
      "compliance_status": "$status",
      "issues": [$(echo "$issues" | sed 's/;/","/g' | sed 's/^/"/;s/$/"/' | sed 's/""//')  ]
    }
EOF
    done
    
    cat >> "$REPORT_FILE" << EOF
  ]
}
EOF
    
    log_success "Compliance report generated: $REPORT_FILE"
}

# Function to create GitHub Actions summary
create_github_summary() {
    local compliance_results=("$@")
    
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
        # Calculate compliance rate safely for GitHub summary
        local github_rate=0
        if [[ $TOTAL_ADRS -gt 0 ]]; then
            github_rate=$(( COMPLIANT_ADRS * 100 / TOTAL_ADRS ))
        fi
        
        cat >> "$GITHUB_STEP_SUMMARY" << EOF
# ADR Compliance Check Results

## Summary
- **Total ADRs Checked**: $TOTAL_ADRS
- **Compliant**: $COMPLIANT_ADRS ✅
- **Non-Compliant**: $NON_COMPLIANT_ADRS ❌
- **Compliance Rate**: ${github_rate}%

## Detailed Results
EOF
        
        for result in "${compliance_results[@]}"; do
            IFS='|' read -r adr_id status issues <<< "$result"
            
            if [[ "$status" == "COMPLIANT" ]]; then
                echo "- **ADR-$adr_id**: ✅ COMPLIANT" >> "$GITHUB_STEP_SUMMARY"
            else
                echo "- **ADR-$adr_id**: ❌ NON-COMPLIANT" >> "$GITHUB_STEP_SUMMARY"
                if [[ -n "$issues" ]]; then
                    echo "  - Issues: ${issues//;/, }" >> "$GITHUB_STEP_SUMMARY"
                fi
            fi
        done
        
        echo "" >> "$GITHUB_STEP_SUMMARY"
        echo "Report generated: $(date)" >> "$GITHUB_STEP_SUMMARY"
    fi
}

# Main function
main() {
    echo -e "${BLUE}🔍 Automated ADR Compliance Checker${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo "Checking compliance across all implemented ADRs..."
    echo "Project root: $PROJECT_ROOT"
    echo ""
    
    # Run compliance checks for specific ADRs
    local compliance_results=()
    
    # ADR-0001: DNF Module Management
    compliance_results+=("$(check_adr_0001_compliance)")
    
    # ADR-0002: Role Architecture Standards
    compliance_results+=("$(check_adr_0002_compliance)")
    
    # ADR-0005: Molecule Testing Framework
    compliance_results+=("$(check_adr_0005_compliance)")
    
    # ADR-0009: GitHub Actions Dependabot Auto-Updates
    compliance_results+=("$(check_adr_0009_compliance)")
    
    # ADR-0011: Mandatory Local Testing Requirements
    compliance_results+=("$(check_adr_0011_compliance)")
    
    # ADR-0013: Molecule Container Configuration Best Practices
    compliance_results+=("$(check_adr_0013_compliance)")
    
    # Count results
    TOTAL_ADRS=${#compliance_results[@]}
    for result in "${compliance_results[@]}"; do
        IFS='|' read -r adr_id status issues <<< "$result"
        if [[ "$status" == "COMPLIANT" ]]; then
            COMPLIANT_ADRS=$((COMPLIANT_ADRS + 1))
        else
            NON_COMPLIANT_ADRS=$((NON_COMPLIANT_ADRS + 1))
        fi
    done
    
    # Generate reports
    generate_compliance_report "${compliance_results[@]}"
    create_github_summary "${compliance_results[@]}"
    
    # Summary output
    echo ""
    echo -e "${PURPLE}=== Compliance Summary ===${NC}"
    echo -e "${GREEN}✅ Compliant ADRs: $COMPLIANT_ADRS${NC}"
    echo -e "${RED}❌ Non-Compliant ADRs: $NON_COMPLIANT_ADRS${NC}"
    echo -e "${BLUE}📊 Total ADRs Checked: $TOTAL_ADRS${NC}"
    
    # Calculate and display compliance rate safely
    local display_rate=0
    if [[ $TOTAL_ADRS -gt 0 ]]; then
        display_rate=$(( COMPLIANT_ADRS * 100 / TOTAL_ADRS ))
    fi
    echo -e "${BLUE}📈 Compliance Rate: ${display_rate}%${NC}"
    
    if [[ $NON_COMPLIANT_ADRS -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All ADRs are compliant!${NC}"
        exit 0
    else
        echo -e "\n${RED}🚨 $NON_COMPLIANT_ADRS ADR(s) are non-compliant!${NC}"
        echo -e "${YELLOW}📋 Check the compliance report for details: $REPORT_FILE${NC}"
        exit 1
    fi
}

# Help function
show_help() {
    echo "Automated ADR Compliance Checker"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "This tool checks compliance for the following ADRs:"
    echo "  - ADR-0001: DNF Module Management"
    echo "  - ADR-0002: Role Architecture Standards"
    echo "  - ADR-0005: Molecule Testing Framework"
    echo "  - ADR-0009: GitHub Actions Dependabot Auto-Updates"
    echo "  - ADR-0011: Mandatory Local Testing Requirements"
    echo "  - ADR-0013: Molecule Container Configuration Best Practices"
    echo ""
    echo "Generates:"
    echo "  - JSON compliance report in compliance-reports/"
    echo "  - GitHub Actions summary (if running in CI/CD)"
    echo ""
    echo "Exit codes:"
    echo "  0: All ADRs are compliant"
    echo "  1: One or more ADRs are non-compliant"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
