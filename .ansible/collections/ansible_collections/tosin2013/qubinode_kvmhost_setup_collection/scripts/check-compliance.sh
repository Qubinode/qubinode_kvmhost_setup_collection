#!/bin/bash
# Quick compliance check for mandatory local testing rules
# Rule: mandatory-local-testing-before-push (ADR-0011)
# Usage: ./scripts/check-compliance.sh

set -e

echo "🛡️  Mandatory Local Testing Compliance Check (ADR-0011)"
echo "========================================================"
echo "📋 Checking compliance with: mandatory-local-testing-before-push"
echo "📋 Severity: CRITICAL"
echo ""

compliance_passed=true

# Check 1: Local testing script exists
echo "🔍 Check 1: Local testing script exists..."
if [ ! -f "scripts/test-local-molecule.sh" ]; then
    echo "❌ FAIL: scripts/test-local-molecule.sh not found"
    echo "   💡 Create the script: touch scripts/test-local-molecule.sh"
    compliance_passed=false
else
    echo "✅ PASS: Local testing script exists"
fi

# Check 2: Script is executable
echo ""
echo "🔍 Check 2: Script is executable..."
if [ ! -x "scripts/test-local-molecule.sh" ]; then
    echo "❌ FAIL: scripts/test-local-molecule.sh is not executable"
    echo "   💡 Fix: chmod +x scripts/test-local-molecule.sh"
    compliance_passed=false
else
    echo "✅ PASS: Script is executable"
fi

# Check 3: Architectural rules file exists
echo ""
echo "🔍 Check 3: Architectural rules file exists..."
if [ ! -f "rules/local-molecule-testing-rules.json" ]; then
    echo "❌ FAIL: rules/local-molecule-testing-rules.json not found"
    echo "   💡 This file defines the mandatory testing rules"
    compliance_passed=false
else
    echo "✅ PASS: Architectural rules file exists"
    if command -v jq > /dev/null 2>&1; then
        version=$(jq -r '.metadata.version' rules/local-molecule-testing-rules.json 2>/dev/null || echo "unknown")
        rule_count=$(jq '.rules | length' rules/local-molecule-testing-rules.json 2>/dev/null || echo "unknown")
        echo "   📋 Version: $version"
        echo "   📋 Rules: $rule_count"
    fi
fi

# Check 4: Pre-commit hook example exists
echo ""
echo "🔍 Check 4: Pre-commit hook example exists..."
if [ ! -f ".git/hooks/pre-commit.example" ]; then
    echo "⚠️  WARN: .git/hooks/pre-commit.example not found"
    echo "   💡 This helps enforce local testing before commits"
else
    echo "✅ PASS: Pre-commit hook example exists"
    if [ -f ".git/hooks/pre-commit" ]; then
        echo "   ✅ Active pre-commit hook found"
    else
        echo "   💡 To activate: cp .git/hooks/pre-commit.example .git/hooks/pre-commit"
    fi
fi

# Check 5: Environment prerequisites
echo ""
echo "🔍 Check 5: Environment prerequisites..."
if command -v molecule > /dev/null 2>&1; then
    echo "✅ PASS: Molecule is installed"
    molecule_version=$(molecule --version 2>/dev/null | head -1 || echo "version unknown")
    echo "   📋 $molecule_version"
else
    echo "❌ FAIL: Molecule is not installed"
    echo "   💡 Quick setup: ./scripts/setup-local-testing.sh"
    echo "   💡 Manual install: pip install molecule molecule-plugins[docker]"
    compliance_passed=false
fi

if command -v ansible > /dev/null 2>&1; then
    echo "✅ PASS: Ansible is installed"
    ansible_version=$(ansible --version 2>/dev/null | head -1 || echo "version unknown")
    echo "   📋 $ansible_version"
else
    echo "❌ FAIL: Ansible is not installed"
    echo "   💡 Install: pip install ansible-core"
    compliance_passed=false
fi

# Final result
echo ""
echo "========================================================"
if [ "$compliance_passed" = true ]; then
    echo "🎉 COMPLIANCE CHECK PASSED"
    echo "✅ All mandatory requirements satisfied"
    echo "✅ Ready to run: ./scripts/test-local-molecule.sh"
    echo "✅ Ready for: git commit and push"
    echo ""
    echo "🛡️ ADR-0011 Compliance: SATISFIED"
    echo "📋 Rule: mandatory-local-testing-before-push"
    exit 0
else
    echo "❌ COMPLIANCE CHECK FAILED"
    echo "🚫 Mandatory requirements not satisfied"
    echo "🛑 Must fix issues before pushing to CI/CD"
    echo ""
    echo "🛡️ ADR-0011 Compliance: VIOLATED"
    echo "📋 Rule: mandatory-local-testing-before-push"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Run setup script: ./scripts/setup-local-testing.sh"
    echo "   2. Or fix issues manually (see above)"
    echo "   3. Re-run: ./scripts/check-compliance.sh"
    echo "   4. Run: ./scripts/test-local-molecule.sh"
    echo "   5. Commit and push when all tests pass"
    exit 1
fi
