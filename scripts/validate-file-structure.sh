#!/bin/bash
# File Structure Validation Tool
# Validates project file structure against established standards and ADRs
# Part of DevOps & Automation Tasks - ensures consistent project organization

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Validation result counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Function to log validation results
log_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

log_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

log_info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
}

log_header() {
    echo -e "\n${PURPLE}=== $1 ===${NC}"
}

# Function to validate directory structure
validate_directory() {
    local dir_path="$1"
    local description="$2"
    local required="${3:-true}"
    
    if [[ -d "$PROJECT_ROOT/$dir_path" ]]; then
        log_pass "$description exists at $dir_path"
        return 0
    else
        if [[ "$required" == "true" ]]; then
            log_fail "$description missing at $dir_path"
        else
            log_warning "$description not found at $dir_path (optional)"
        fi
        return 1
    fi
}

# Function to validate file exists
validate_file() {
    local file_path="$1"
    local description="$2"
    local required="${3:-true}"
    
    if [[ -f "$PROJECT_ROOT/$file_path" ]]; then
        log_pass "$description exists at $file_path"
        return 0
    else
        if [[ "$required" == "true" ]]; then
            log_fail "$description missing at $file_path"
        else
            log_warning "$description not found at $file_path (optional)"
        fi
        return 1
    fi
}

# Function to validate file has minimum content
validate_file_content() {
    local file_path="$1"
    local description="$2"
    local min_lines="${3:-10}"
    
    if [[ -f "$PROJECT_ROOT/$file_path" ]]; then
        local line_count=$(wc -l < "$PROJECT_ROOT/$file_path")
        if [[ $line_count -ge $min_lines ]]; then
            log_pass "$description has adequate content ($line_count lines)"
        else
            log_warning "$description appears incomplete ($line_count lines, expected >=$min_lines)"
        fi
    else
        log_fail "$description missing at $file_path"
    fi
}

# Function to validate role structure (ADR-0002)
validate_role_structure() {
    local role_name="$1"
    local role_dir="roles/$role_name"

    log_info "Validating role: $role_name"

    # Check main role directory
    validate_directory "$role_dir" "Role $role_name directory"

    # Check required role subdirectories
    validate_directory "$role_dir/tasks" "Role $role_name tasks directory"
    validate_directory "$role_dir/defaults" "Role $role_name defaults directory"
    validate_directory "$role_dir/meta" "Role $role_name meta directory"

    # Check optional role subdirectories (don't fail on missing optional dirs)
    validate_directory "$role_dir/handlers" "Role $role_name handlers directory" "false" || true
    validate_directory "$role_dir/templates" "Role $role_name templates directory" "false" || true
    validate_directory "$role_dir/files" "Role $role_name files directory" "false" || true
    validate_directory "$role_dir/vars" "Role $role_name vars directory" "false" || true

    # Check required role files
    validate_file "$role_dir/tasks/main.yml" "Role $role_name main tasks file"
    validate_file "$role_dir/defaults/main.yml" "Role $role_name defaults file"
    validate_file "$role_dir/meta/main.yml" "Role $role_name meta file"
    validate_file "$role_dir/README.md" "Role $role_name README" "false" || true

    # Check content quality
    validate_file_content "$role_dir/tasks/main.yml" "Role $role_name main tasks" 5
    validate_file_content "$role_dir/defaults/main.yml" "Role $role_name defaults" 3
}

# Function to validate Molecule structure (ADR-0005, ADR-0012, ADR-0013)
validate_molecule_structure() {
    local scenario="$1"
    local molecule_dir="molecule/$scenario"
    
    log_info "Validating Molecule scenario: $scenario"
    
    validate_directory "$molecule_dir" "Molecule scenario $scenario directory"
    validate_file "$molecule_dir/molecule.yml" "Molecule scenario $scenario config file"
    validate_file "$molecule_dir/converge.yml" "Molecule scenario $scenario converge playbook"
    validate_file "$molecule_dir/verify.yml" "Molecule scenario $scenario verify playbook" "false" || true
    
    # Check molecule.yml for ADR-0013 compliance (systemd configuration)
    if [[ -f "$PROJECT_ROOT/$molecule_dir/molecule.yml" ]]; then
        if grep -q "systemd: always" "$PROJECT_ROOT/$molecule_dir/molecule.yml"; then
            log_pass "Molecule scenario $scenario has systemd: always (ADR-0013 compliant)"
        else
            log_warning "Molecule scenario $scenario may not have systemd: always (check ADR-0013 compliance)"
        fi
        
        # Check for deprecated tmpfs usage
        if grep -q "tmpfs:" "$PROJECT_ROOT/$molecule_dir/molecule.yml"; then
            log_fail "Molecule scenario $scenario uses deprecated tmpfs (violates ADR-0013)"
        else
            log_pass "Molecule scenario $scenario does not use deprecated tmpfs"
        fi
    fi
}

# Function to validate documentation structure
validate_documentation_structure() {
    log_info "Validating documentation structure"
    
    # Core documentation
    validate_file "README.md" "Main project README"
    validate_file "CHANGELOG.rst" "Project changelog"
    validate_file "CONTRIBUTING.md" "Contributing guidelines"
    validate_file "LICENSE" "License file"
    
    # ADR documentation (ADR-0010)
    validate_directory "docs/adrs" "ADR documentation directory"
    validate_file "docs/adrs/README.md" "ADR index/README" "false" || true
    
    # Role documentation (ADR-0002)
    validate_file "docs/role_interface_standards.md" "Role interface standards"
    validate_file "docs/variable_naming_conventions.md" "Variable naming conventions"
    validate_file "docs/migration_guide.md" "Migration guide"
    
    # Testing documentation (ADR-0011)
    validate_file "docs/MANDATORY_LOCAL_TESTING.md" "Mandatory local testing guide"
    
    # Count ADR files
    if [[ -d "$PROJECT_ROOT/docs/adrs" ]]; then
        local adr_count=$(find "$PROJECT_ROOT/docs/adrs" -name "adr-*.md" | wc -l)
        if [[ $adr_count -gt 0 ]]; then
            log_pass "Found $adr_count ADR files in docs/adrs"
        else
            log_warning "No ADR files found in docs/adrs directory"
        fi
    fi
}

# Function to validate validation framework structure
validate_validation_framework() {
    log_info "Validating validation framework structure"
    
    validate_directory "validation" "Validation framework directory"
    validate_directory "validation/schemas" "Validation schemas directory" "false" || true
    validate_file "validation/configuration_drift_detection.yml" "Configuration drift detection"
    validate_file "validation/cross_role_validation.yml" "Cross-role validation"
    
    # Count validation files
    if [[ -d "$PROJECT_ROOT/validation" ]]; then
        local validation_count=$(find "$PROJECT_ROOT/validation" -name "*.yml" | wc -l)
        log_info "Found $validation_count validation YAML files"
    fi
}

# Function to validate CI/CD structure (ADR-0009)
validate_cicd_structure() {
    log_info "Validating CI/CD structure"
    
    validate_directory ".github" "GitHub configuration directory"
    validate_directory ".github/workflows" "GitHub Actions workflows directory"
    validate_file ".github/dependabot.yml" "Dependabot configuration"
    
    # Check for essential workflows
    validate_file ".github/workflows/ansible-lint.yml" "Ansible lint workflow"
    validate_file ".github/workflows/ansible-test.yml" "Ansible test workflow"
    validate_file ".github/workflows/dependency-testing.yml" "Dependency testing workflow"
    
    # Count workflow files
    if [[ -d "$PROJECT_ROOT/.github/workflows" ]]; then
        local workflow_count=$(find "$PROJECT_ROOT/.github/workflows" -name "*.yml" | wc -l)
        log_info "Found $workflow_count GitHub Actions workflow files"
    fi
}

# Function to validate scripts structure
validate_scripts_structure() {
    log_info "Validating scripts structure"
    
    validate_directory "scripts" "Scripts directory"
    
    # Check for essential scripts (ADR-0011)
    validate_file "scripts/test-local-molecule.sh" "Local testing script"
    validate_file "scripts/setup-local-testing.sh" "Environment setup script"
    validate_file "scripts/check-compliance.sh" "Compliance check script"
    
    # Check for validation scripts
    validate_file "scripts/validate-adr-files.sh" "ADR file validation script"
    validate_file "scripts/validate-molecule-systemd.sh" "Molecule systemd validation script"
    validate_file "scripts/enhanced-dependency-scanner.sh" "Enhanced dependency scanner"
    
    # Check script executability
    if [[ -d "$PROJECT_ROOT/scripts" ]]; then
        local executable_count=0
        local total_scripts=0
        for script in "$PROJECT_ROOT/scripts"/*.sh; do
            if [[ -f "$script" ]]; then
                ((total_scripts++))
                if [[ -x "$script" ]]; then
                    ((executable_count++))
                fi
            fi
        done
        
        if [[ $executable_count -eq $total_scripts ]] && [[ $total_scripts -gt 0 ]]; then
            log_pass "All $total_scripts shell scripts are executable"
        elif [[ $total_scripts -gt 0 ]]; then
            log_warning "$executable_count/$total_scripts shell scripts are executable"
        fi
    fi
}

# Function to validate inventory structure
validate_inventory_structure() {
    log_info "Validating inventory structure"
    
    validate_directory "inventories" "Inventories directory"
    validate_directory "inventories/templates" "Inventory templates directory"
    validate_directory "inventories/local" "Local inventory directory" "false" || true
    validate_directory "inventories/test" "Test inventory directory" "false" || true
}

# Function to validate test structure
validate_test_structure() {
    log_info "Validating test structure"
    
    validate_directory "tests" "Tests directory"
    validate_directory "tests/integration" "Integration tests directory" "false" || true
    validate_directory "tests/units" "Unit tests directory" "false" || true
    validate_directory "tests/idempotency" "Idempotency tests directory"
}

# Function to validate architectural rules
validate_architectural_rules() {
    log_info "Validating architectural rules structure"
    
    validate_directory "rules" "Rules directory"
    validate_file "rules/architectural-rules.json" "Architectural rules JSON"
    validate_file "rules/local-molecule-testing-rules.json" "Local testing rules"
    validate_file "rules/README.md" "Rules documentation"
}

# Main validation function
main() {
    echo -e "${BLUE}🔍 File Structure Validation Tool${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo "Validating project file structure against ADR standards..."
    echo "Project root: $PROJECT_ROOT"
    echo ""
    
    # Run all validations
    log_header "Core Project Structure"
    validate_file "galaxy.yml" "Ansible Galaxy collection metadata"
    validate_file "ansible.cfg" "Ansible configuration"
    
    log_header "Role Structure Validation (ADR-0002)"
    # Get list of roles and validate each
    if [[ -d "$PROJECT_ROOT/roles" ]]; then
        for role_dir in "$PROJECT_ROOT/roles"/*; do
            if [[ -d "$role_dir" ]]; then
                role_name=$(basename "$role_dir")
                # Skip role_config.yml if it exists
                if [[ "$role_name" != "role_config.yml" ]]; then
                    validate_role_structure "$role_name"
                fi
            fi
        done
    else
        log_fail "Roles directory missing"
    fi
    
    log_header "Molecule Structure Validation (ADR-0005, ADR-0012, ADR-0013)"
    if [[ -d "$PROJECT_ROOT/molecule" ]]; then
        for scenario_dir in "$PROJECT_ROOT/molecule"/*; do
            if [[ -d "$scenario_dir" ]]; then
                scenario_name=$(basename "$scenario_dir")
                validate_molecule_structure "$scenario_name"
            fi
        done
    else
        log_fail "Molecule directory missing"
    fi
    
    log_header "Documentation Structure (ADR-0010)"
    validate_documentation_structure
    
    log_header "Validation Framework Structure"
    validate_validation_framework
    
    log_header "CI/CD Structure (ADR-0009)"
    validate_cicd_structure
    
    log_header "Scripts Structure (ADR-0011)"
    validate_scripts_structure
    
    log_header "Inventory Structure"
    validate_inventory_structure
    
    log_header "Test Structure"
    validate_test_structure
    
    log_header "Architectural Rules Structure"
    validate_architectural_rules
    
    # Final summary
    echo ""
    log_header "Validation Summary"
    echo -e "${GREEN}✅ Passed: $PASSED_CHECKS${NC}"
    echo -e "${YELLOW}⚠️  Warnings: $WARNING_CHECKS${NC}"
    echo -e "${RED}❌ Failed: $FAILED_CHECKS${NC}"
    echo -e "${BLUE}📊 Total checks: $TOTAL_CHECKS${NC}"
    
    # Calculate success rate safely
    local success_rate=0
    if [[ $TOTAL_CHECKS -gt 0 ]]; then
        success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    fi
    echo -e "${BLUE}📈 Success rate: ${success_rate}%${NC}"
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All critical validations passed!${NC}"
        if [[ $WARNING_CHECKS -gt 0 ]]; then
            echo -e "${YELLOW}💡 Consider addressing warnings for improved project structure.${NC}"
        fi
        exit 0
    else
        echo -e "\n${RED}🚨 $FAILED_CHECKS critical validation(s) failed!${NC}"
        echo -e "${YELLOW}🛠️  Please address the failed checks before proceeding.${NC}"
        exit 1
    fi
}

# Help function
show_help() {
    echo "File Structure Validation Tool"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "This tool validates the project file structure against:"
    echo "  - ADR-0002: Role Architecture Standards"
    echo "  - ADR-0005: Molecule Testing Standards"
    echo "  - ADR-0009: CI/CD Pipeline Standards"
    echo "  - ADR-0010: Documentation Standards"
    echo "  - ADR-0011: Local Testing Standards"
    echo "  - ADR-0012: Container Testing Standards"
    echo "  - ADR-0013: Systemd Configuration Standards"
    echo ""
    echo "Exit codes:"
    echo "  0: All critical validations passed"
    echo "  1: One or more critical validations failed"
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
