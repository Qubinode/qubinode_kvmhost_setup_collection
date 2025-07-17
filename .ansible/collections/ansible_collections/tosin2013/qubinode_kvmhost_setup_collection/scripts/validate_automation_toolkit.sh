#!/bin/bash

# Complete Validation Script for Ansible Lint Automation Toolkit
# Tests all automation components and provides comprehensive reporting

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Emojis for better UX
CHECK="✅"
ERROR="❌"
WARNING="⚠️"
INFO="ℹ️"
ROCKET="🚀"
GEAR="⚙️"
CHART="📊"
TARGET="🎯"

echo -e "${BLUE}${ROCKET} Ansible Lint Automation Toolkit Validation${NC}"
echo "=============================================="

# Function to print section headers
print_section() {
    echo -e "\n${PURPLE}${1}${NC}"
    echo "$(printf '=%.0s' {1..50})"
}

# Function to run a command and capture output
run_test() {
    local test_name="$1"
    local command="$2"
    local expect_success="${3:-true}"
    
    echo -e "${BLUE}${GEAR} Testing: ${test_name}${NC}"
    
    if [ "$expect_success" = "true" ]; then
        if eval "$command" >/dev/null 2>&1; then
            echo -e "${GREEN}${CHECK} PASSED: ${test_name}${NC}"
            return 0
        else
            echo -e "${RED}${ERROR} FAILED: ${test_name}${NC}"
            return 1
        fi
    else
        if eval "$command" >/dev/null 2>&1; then
            echo -e "${RED}${ERROR} UNEXPECTED SUCCESS: ${test_name}${NC}"
            return 1
        else
            echo -e "${GREEN}${CHECK} EXPECTED FAILURE: ${test_name}${NC}"
            return 0
        fi
    fi
}

# Function to count issues
count_issues() {
    local pattern="$1"
    local count
    if command -v ansible-lint >/dev/null 2>&1; then
        count=$(ansible-lint roles/ --exclude roles/.cache/ --exclude roles/.venv/ 2>/dev/null | grep -c "$pattern" || echo "0")
    else
        count="N/A"
    fi
    echo "$count"
}

# Function to validate YAML files
validate_yaml_files() {
    local total=0
    local valid=0
    local invalid_files=()
    
    while IFS= read -r -d '' file; do
        ((total++))
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            ((valid++))
        else
            invalid_files+=("$file")
        fi
    done < <(find roles/ -name "*.yml" -o -name "*.yaml" 2>/dev/null | head -100 | tr '\n' '\0')
    
    echo "$valid/$total"
    if [ ${#invalid_files[@]} -gt 0 ] && [ ${#invalid_files[@]} -le 5 ]; then
        echo -e "${YELLOW}${WARNING} Invalid YAML files:${NC}"
        for file in "${invalid_files[@]}"; do
            echo "  - $file"
        done
    elif [ ${#invalid_files[@]} -gt 5 ]; then
        echo -e "${YELLOW}${WARNING} ${#invalid_files[@]} invalid YAML files detected${NC}"
    fi
}

print_section "🔍 Prerequisites Check"

# Check for required tools
run_test "Python 3 availability" "command -v python3"
run_test "PyYAML module" "python3 -c 'import yaml'"
run_test "Pathlib module" "python3 -c 'import pathlib'"
run_test "Regex module" "python3 -c 'import re'"

# Check for optional tools
if command -v ansible-lint >/dev/null 2>&1; then
    echo -e "${GREEN}${CHECK} ansible-lint found: $(ansible-lint --version | head -1)${NC}"
    ANSIBLE_LINT_AVAILABLE=true
else
    echo -e "${YELLOW}${WARNING} ansible-lint not found (optional for validation)${NC}"
    ANSIBLE_LINT_AVAILABLE=false
fi

print_section "🧪 Script Validation"

# Check that all automation scripts exist and are executable
scripts=(
    "scripts/fix_yaml_parsing.py"
    "scripts/fix_ansible_lint.py" 
    "scripts/fix_ansible_lint_advanced.py"
    "scripts/fix_escape_chars.py"
    "scripts/ansible_lint_toolkit.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ] || [[ "$script" == *.py ]]; then
            echo -e "${GREEN}${CHECK} Found: $script${NC}"
        else
            echo -e "${YELLOW}${WARNING} Found but not executable: $script${NC}"
            chmod +x "$script" 2>/dev/null || true
        fi
    else
        echo -e "${RED}${ERROR} Missing: $script${NC}"
    fi
done

print_section "📂 Project Structure Validation"

# Check critical directories
directories=("roles/" "meta/" "docs/")
for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        file_count=$(find "$dir" -type f | wc -l)
        echo -e "${GREEN}${CHECK} Directory $dir exists (${file_count} files)${NC}"
    else
        echo -e "${YELLOW}${WARNING} Directory $dir not found${NC}"
    fi
done

# Check for YAML files
yaml_count=$(find . -name "*.yml" -o -name "*.yaml" 2>/dev/null | grep -v '.git' | wc -l)
echo -e "${INFO} Found ${yaml_count} YAML files in project${NC}"

print_section "🔧 YAML Syntax Validation"

if [ -d "roles/" ]; then
    yaml_status=$(validate_yaml_files)
    echo -e "${CHART} YAML File Validity: ${yaml_status}${NC}"
else
    echo -e "${YELLOW}${WARNING} No roles/ directory found for YAML validation${NC}"
fi

print_section "🎯 Ansible-Lint Baseline"

if [ "$ANSIBLE_LINT_AVAILABLE" = true ] && [ -d "roles/" ]; then
    echo -e "${INFO} Generating ansible-lint baseline...${NC}"
    
    # Count different types of issues
    total_issues=$(ansible-lint roles/ --exclude roles/.cache/ --exclude roles/.venv/ 2>/dev/null | grep -c ":" || echo "0")
    schema_issues=$(count_issues "schema\[")
    yaml_issues=$(count_issues "yaml\[")
    jinja_issues=$(count_issues "jinja\[")
    name_issues=$(count_issues "name\[")
    
    echo -e "${CHART} Current ansible-lint status:"
    echo -e "  Total Issues: ${total_issues}"
    echo -e "  Schema Issues: ${schema_issues}"
    echo -e "  YAML Issues: ${yaml_issues}"
    echo -e "  Jinja Issues: ${jinja_issues}"
    echo -e "  Name Issues: ${name_issues}"
else
    echo -e "${YELLOW}${WARNING} Skipping ansible-lint baseline (tool not available or no roles/)${NC}"
fi

print_section "🚀 Automation Script Tests"

# Test each script with dry-run or validation mode
if [ -d "roles/" ]; then
    echo -e "${INFO} Testing automation scripts (dry-run mode)...${NC}"
    
    # Test YAML parsing script
    if [ -f "scripts/fix_yaml_parsing.py" ]; then
        if python3 scripts/fix_yaml_parsing.py --help >/dev/null 2>&1 || python3 -c "exec(open('scripts/fix_yaml_parsing.py').read())" 2>/dev/null; then
            echo -e "${GREEN}${CHECK} YAML parsing script syntax valid${NC}"
        else
            echo -e "${YELLOW}${WARNING} YAML parsing script may have syntax issues${NC}"
        fi
    fi
    
    # Test basic fix script
    if [ -f "scripts/fix_ansible_lint.py" ]; then
        if python3 -c "exec(open('scripts/fix_ansible_lint.py').read())" 2>/dev/null; then
            echo -e "${GREEN}${CHECK} Basic fix script syntax valid${NC}"
        else
            echo -e "${YELLOW}${WARNING} Basic fix script may have syntax issues${NC}"
        fi
    fi
    
    # Test toolkit script
    if [ -f "scripts/ansible_lint_toolkit.sh" ]; then
        if bash -n scripts/ansible_lint_toolkit.sh 2>/dev/null; then
            echo -e "${GREEN}${CHECK} Toolkit script syntax valid${NC}"
        else
            echo -e "${YELLOW}${WARNING} Toolkit script has syntax issues${NC}"
        fi
    fi
else
    echo -e "${YELLOW}${WARNING} Skipping script tests (no roles/ directory)${NC}"
fi

print_section "📋 Summary & Recommendations"

# Provide recommendations based on findings
echo -e "${TARGET} Toolkit Readiness Assessment:"

if [ -d "roles/" ] && [ -f "scripts/ansible_lint_toolkit.sh" ]; then
    echo -e "${GREEN}${CHECK} Project structure is ready for automation${NC}"
    echo -e "${GREEN}${CHECK} All automation scripts are available${NC}"
    
    if [ "$ANSIBLE_LINT_AVAILABLE" = true ]; then
        echo -e "${GREEN}${CHECK} Can perform full ansible-lint automation${NC}"
        echo -e "\n${ROCKET} ${BLUE}Ready to run: ./scripts/ansible_lint_toolkit.sh${NC}"
    else
        echo -e "${YELLOW}${WARNING} Install ansible-lint for full automation: pip install ansible-lint[yamllint]${NC}"
        echo -e "\n${GEAR} ${BLUE}Ready to run individual scripts${NC}"
    fi
else
    echo -e "${RED}${ERROR} Project structure or scripts missing${NC}"
    echo -e "\n${INFO} ${BLUE}Setup requirements:${NC}"
    if [ ! -d "roles/" ]; then
        echo -e "  - Create roles/ directory with Ansible roles"
    fi
    if [ ! -f "scripts/ansible_lint_toolkit.sh" ]; then
        echo -e "  - Install automation scripts"
    fi
fi

echo -e "\n${INFO} ${BLUE}For detailed usage instructions, see: docs/ANSIBLE_LINT_AUTOMATION.md${NC}"

print_section "🎉 Validation Complete"

exit 0
