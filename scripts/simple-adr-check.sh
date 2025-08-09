#!/bin/bash

# =============================================================================
# Quick ADR Validator - The "Compliance Quick-Check"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script provides rapid validation of core ADR implementations,
# offering a lightweight alternative to comprehensive compliance checking.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Core ADR Identification - Identifies critical ADRs for validation
# 2. [PHASE 2]: Quick Validation - Performs rapid checks of ADR compliance
# 3. [PHASE 3]: Pass/Fail Assessment - Provides simple pass/fail results
# 4. [PHASE 4]: Summary Reporting - Generates concise compliance summary
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Validates: Core ADR implementations quickly without deep analysis
# - Complements: adr-compliance-checker.sh with lightweight validation
# - Provides: Fast feedback for developers during development
# - Integrates: With development workflows for quick compliance checks
# - Supports: Rapid validation in resource-constrained environments
# - Enables: Quick pre-commit compliance verification
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - SPEED: Optimized for rapid execution and quick feedback
# - SIMPLICITY: Focuses on essential ADR compliance checks only
# - LIGHTWEIGHT: Minimal resource usage and dependencies
# - BINARY: Provides clear pass/fail results without detailed analysis
# - COMPLEMENTARY: Works alongside comprehensive compliance tools
# - DEVELOPER-FRIENDLY: Designed for frequent use during development
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Core ADRs: Add quick checks for new critical ADRs
# - Check Logic: Modify validation logic for improved accuracy
# - Performance: Optimize for even faster execution
# - Integration: Add hooks for development tools or IDEs
# - Reporting: Enhance summary reporting for better clarity
# - Automation: Add integration with pre-commit hooks or CI/CD
#
# 🚨 IMPORTANT FOR LLMs: This is a quick validation tool, not comprehensive.
# Use adr-compliance-checker.sh for detailed compliance analysis. This script
# is designed for rapid feedback during development cycles.

# Simple ADR Compliance Checker
# Quick validation of core ADR implementations

set -e

echo "🔍 Simple ADR Compliance Check"
echo "=============================="

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASSED=0
FAILED=0

check_adr() {
    local adr_name="$1"
    local check_description="$2"
    local check_command="$3"
    
    echo -n "Checking $adr_name: $check_description... "
    
    if eval "$check_command" >/dev/null 2>&1; then
        echo "✅ PASS"
        ((PASSED++))
    else
        echo "❌ FAIL"
        ((FAILED++))
    fi
}

# ADR-0002: Role Architecture Standards
check_adr "ADR-0002" "Role structure" "test -d '$PROJECT_ROOT/roles/kvmhost_base' && test -f '$PROJECT_ROOT/roles/kvmhost_base/tasks/main.yml'"

# ADR-0005: Molecule Testing Framework  
check_adr "ADR-0005" "Molecule scenarios" "test -d '$PROJECT_ROOT/molecule/default' && test -f '$PROJECT_ROOT/molecule/default/molecule.yml'"

# ADR-0009: Dependabot Configuration
check_adr "ADR-0009" "Dependabot config" "test -f '$PROJECT_ROOT/.github/dependabot.yml'"

# ADR-0011: Local Testing Requirements
check_adr "ADR-0011" "Testing scripts" "test -f '$PROJECT_ROOT/scripts/test-local-molecule.sh' && test -x '$PROJECT_ROOT/scripts/test-local-molecule.sh'"

# ADR-0013: Molecule systemd Configuration
check_adr "ADR-0013" "systemd configuration" "grep -q 'systemd: always' '$PROJECT_ROOT/molecule/default/molecule.yml'"

echo ""
echo "Summary:"
echo "✅ Passed: $PASSED"
echo "❌ Failed: $FAILED"
echo "📊 Total: $((PASSED + FAILED))"
echo "📈 Compliance Rate: $(( PASSED * 100 / (PASSED + FAILED) ))%"

if [[ $FAILED -eq 0 ]]; then
    echo "🎉 All ADR compliance checks passed!"
    exit 0
else
    echo "🚨 $FAILED ADR compliance check(s) failed!"
    exit 1
fi
