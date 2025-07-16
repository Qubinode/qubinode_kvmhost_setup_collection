#!/bin/bash
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
