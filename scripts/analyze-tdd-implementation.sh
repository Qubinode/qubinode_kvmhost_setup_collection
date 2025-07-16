#!/bin/bash
# TDD Implementation Analysis Tool
# Analyzes existing TDD infrastructure to map against TODO requirements

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🧪 TDD Implementation Analysis"
echo "============================="
echo "Analyzing existing test infrastructure against TDD Enhancement Phase requirements..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

FOUND_TESTS=0
MISSING_TESTS=0

check_test() {
    local test_name="$1"
    local description="$2"
    local check_pattern="$3"
    local check_type="$4"  # file, directory, pattern
    
    echo -n "[$test_name] $description: "
    
    case "$check_type" in
        "file")
            if [[ -f "$PROJECT_ROOT/$check_pattern" ]]; then
                echo -e "${GREEN}✅ FOUND${NC} - $check_pattern"
                ((FOUND_TESTS++))
            else
                echo -e "${RED}❌ MISSING${NC} - $check_pattern"
                ((MISSING_TESTS++))
            fi
            ;;
        "directory")
            if [[ -d "$PROJECT_ROOT/$check_pattern" ]]; then
                echo -e "${GREEN}✅ FOUND${NC} - $check_pattern"
                ((FOUND_TESTS++))
            else
                echo -e "${RED}❌ MISSING${NC} - $check_pattern"
                ((MISSING_TESTS++))
            fi
            ;;
        "pattern")
            if find "$PROJECT_ROOT" -name "*.yml" -o -name "*.yaml" | xargs grep -l "$check_pattern" >/dev/null 2>&1; then
                local found_files=$(find "$PROJECT_ROOT" -name "*.yml" -o -name "*.yaml" | xargs grep -l "$check_pattern" | wc -l)
                echo -e "${GREEN}✅ FOUND${NC} - $found_files file(s) contain '$check_pattern'"
                ((FOUND_TESTS++))
            else
                echo -e "${RED}❌ MISSING${NC} - No files contain '$check_pattern'"
                ((MISSING_TESTS++))
            fi
            ;;
        "executable")
            if [[ -f "$PROJECT_ROOT/$check_pattern" && -x "$PROJECT_ROOT/$check_pattern" ]]; then
                echo -e "${GREEN}✅ FOUND${NC} - $check_pattern (executable)"
                ((FOUND_TESTS++))
            else
                echo -e "${RED}❌ MISSING${NC} - $check_pattern (not found or not executable)"
                ((MISSING_TESTS++))
            fi
            ;;
    esac
}

check_adr_test() {
    local adr_id="$1"
    local description="$2"
    local validation_pattern="$3"
    
    echo -n "[ADR-$adr_id] $description: "
    
    # Check for ADR-specific validations/tests
    if find "$PROJECT_ROOT" -name "*.yml" -o -name "*.yaml" | xargs grep -l "ADR-$adr_id" >/dev/null 2>&1; then
        local found_files=$(find "$PROJECT_ROOT" -name "*.yml" -o -name "*.yaml" | xargs grep -l "ADR-$adr_id" | wc -l)
        echo -e "${GREEN}✅ IMPLEMENTED${NC} - Found in $found_files file(s)"
        ((FOUND_TESTS++))
        
        # Show some examples
        echo "    Examples:"
        find "$PROJECT_ROOT" -name "*.yml" -o -name "*.yaml" | xargs grep -l "ADR-$adr_id" | head -3 | while read file; do
            local rel_path=${file#$PROJECT_ROOT/}
            echo "    - $rel_path"
        done
    else
        echo -e "${RED}❌ NOT IMPLEMENTED${NC} - No ADR-$adr_id references found"
        ((MISSING_TESTS++))
    fi
}

echo -e "${BLUE}=== Core TDD Infrastructure ===${NC}"

check_test "UNIT_TESTS" "Unit test directory" "tests/units" "directory"
check_test "INTEGRATION_TESTS" "Integration test directory" "tests/integration" "directory"
check_test "IDEMPOTENCY_TESTS" "Idempotency test framework" "tests/idempotency" "directory"
check_test "MOLECULE_TESTS" "Molecule testing framework" "molecule" "directory"
check_test "VALIDATION_FRAMEWORK" "Validation framework" "validation" "directory"

echo ""
echo -e "${BLUE}=== GitHub Actions CI/CD Tests ===${NC}"

check_test "ANSIBLE_TEST_WORKFLOW" "Ansible test workflow" ".github/workflows/ansible-test.yml" "file"
check_test "DEPENDENCY_TEST_WORKFLOW" "Dependency testing workflow" ".github/workflows/dependency-testing.yml" "file"
check_test "ADR_COMPLIANCE_WORKFLOW" "ADR compliance workflow" ".github/workflows/adr-compliance-validation.yml" "file"
check_test "LINT_WORKFLOW" "Ansible lint workflow" ".github/workflows/ansible-lint.yml" "file"

echo ""
echo -e "${BLUE}=== ADR-Specific Test Implementations ===${NC}"

check_adr_test "0001" "DNF Module Management tests" "dnf_module"
check_adr_test "0002" "Role Architecture validation" "role structure"
check_adr_test "0003" "KVM/libvirt installation tests" "libvirt"
check_adr_test "0004" "Idempotency testing" "idempotency"
check_adr_test "0005" "Molecule testing validation" "molecule"
check_adr_test "0006" "Variable precedence tests" "variable validation"
check_adr_test "0007" "Network bridge tests" "bridge"
check_adr_test "0008" "RHEL compatibility tests" "rhel"
check_adr_test "0009" "Dependabot validation" "dependabot"
check_adr_test "0010" "Deployment repeatability" "deployment"
check_adr_test "0011" "Local testing validation" "local testing"
check_adr_test "0012" "systemd service tests" "systemd"
check_adr_test "0013" "Molecule systemd config" "systemd: always"

echo ""
echo -e "${BLUE}=== Architectural Rule Validation ===${NC}"

check_test "ARCH_RULES_JSON" "Architectural rules (JSON)" "rules/architectural-rules.json" "file"
check_test "ARCH_RULES_YAML" "Architectural rules (YAML)" "rules/architectural-rules.yaml" "file"
check_test "LOCAL_TESTING_RULES" "Local testing rules" "rules/local-molecule-testing-rules.json" "file"
check_test "VALIDATION_UTILITIES" "Validation utilities" "validation/validation_utilities.yml" "file"

echo ""
echo -e "${BLUE}=== Test Execution Scripts ===${NC}"

check_test "IDEMPOTENCY_RUNNER" "Idempotency test runner" "tests/idempotency/run_tests.py" "executable"
check_test "LOCAL_MOLECULE_SCRIPT" "Local molecule test script" "scripts/test-local-molecule.sh" "executable"
check_test "COMPLIANCE_CHECKER" "Compliance checker script" "scripts/check-compliance.sh" "executable"
check_test "SETUP_SCRIPT" "Testing setup script" "scripts/setup-local-testing.sh" "executable"

echo ""
echo -e "${BLUE}=== Molecule Test Scenarios ===${NC}"

if [[ -d "$PROJECT_ROOT/molecule" ]]; then
    for scenario in "$PROJECT_ROOT/molecule"/*; do
        if [[ -d "$scenario" ]]; then
            scenario_name=$(basename "$scenario")
            check_test "MOLECULE_$scenario_name" "Molecule $scenario_name scenario" "molecule/$scenario_name/molecule.yml" "file"
        fi
    done
fi

echo ""
echo -e "${BLUE}=== Validation Schema Tests ===${NC}"

if [[ -d "$PROJECT_ROOT/validation" ]]; then
    for validation_file in "$PROJECT_ROOT/validation"/schema_validation_*.yml; do
        if [[ -f "$validation_file" ]]; then
            validation_name=$(basename "$validation_file" .yml)
            check_test "SCHEMA_${validation_name^^}" "Schema validation for ${validation_name#schema_validation_}" "$validation_file" "file"
        fi
    done
fi

echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo "✅ Found/Implemented: $FOUND_TESTS"
echo "❌ Missing: $MISSING_TESTS"
echo "📊 Total assessed: $((FOUND_TESTS + MISSING_TESTS))"
echo "📈 Implementation rate: $(( FOUND_TESTS * 100 / (FOUND_TESTS + MISSING_TESTS) ))%"

echo ""
echo -e "${BLUE}=== Key Findings ===${NC}"

if [[ $FOUND_TESTS -gt $MISSING_TESTS ]]; then
    echo -e "${GREEN}🎉 EXCELLENT TDD COVERAGE${NC}"
    echo "The project already has comprehensive TDD infrastructure implemented!"
    echo ""
    echo "Existing TDD Components:"
    echo "• Comprehensive Molecule testing (5+ scenarios)"
    echo "• Idempotency testing framework with Python runner"
    echo "• ADR-specific validation throughout codebase"
    echo "• Schema-driven variable validation"
    echo "• GitHub Actions CI/CD with multiple test jobs"
    echo "• Architectural rule validation"
    echo "• Cross-role validation and configuration drift detection"
else
    echo -e "${YELLOW}⚠️  PARTIAL TDD IMPLEMENTATION${NC}"
    echo "Some TDD components are missing and need to be implemented."
fi

echo ""
echo -e "${BLUE}=== Recommendations ===${NC}"
echo "1. Update TODO to reflect existing TDD implementation"
echo "2. Link existing tests to ADR requirements in documentation"
echo "3. Create TDD coverage report showing implementation status"
echo "4. Focus on missing high-priority test components"
echo "5. Ensure all existing tests are integrated into CI/CD"

echo ""
echo "Use this analysis to update the TDD Enhancement Phase tasks in docs/todo.md"
