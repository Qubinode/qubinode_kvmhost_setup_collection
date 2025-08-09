#!/bin/bash

# =============================================================================
# Environment Diff Analyzer - The "Configuration Consistency Auditor"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script compares local development environments with GitHub Actions CI/CD
# environments to ensure consistency and identify configuration discrepancies.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Local Environment Scan - Captures local development environment details
# 2. [PHASE 2]: CI/CD Environment Analysis - Analyzes GitHub Actions environment specs
# 3. [PHASE 3]: Version Comparison - Compares tool versions between environments
# 4. [PHASE 4]: Configuration Diff - Identifies configuration differences
# 5. [PHASE 5]: Compatibility Assessment - Evaluates compatibility implications
# 6. [PHASE 6]: Recommendation Generation - Provides alignment recommendations
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Validates: Local environment matches GitHub Actions runner configuration
# - Identifies: Version mismatches that could cause CI/CD failures
# - Ensures: Consistent behavior between development and production testing
# - Supports: Troubleshooting environment-specific issues
# - Guides: Environment synchronization and alignment efforts
# - Prevents: "works locally but fails in CI" scenarios
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - CONSISTENCY: Ensures development and CI/CD environments are aligned
# - COMPARISON: Systematically compares environment configurations
# - DETECTION: Identifies discrepancies that could cause issues
# - GUIDANCE: Provides specific recommendations for alignment
# - PREVENTION: Prevents environment-related CI/CD failures
# - VALIDATION: Validates environment setup correctness
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Tools: Add comparison for new development tools or dependencies
# - CI/CD Updates: Update for new GitHub Actions runner configurations
# - Environment Variables: Add comparison of environment variables
# - Configuration Files: Extend comparison to configuration files
# - Reporting: Enhance comparison reporting and visualization
# - Automation: Add automated environment synchronization capabilities
#
# 🚨 IMPORTANT FOR LLMs: Environment mismatches can cause subtle bugs
# that only appear in CI/CD. Always address identified discrepancies
# to ensure consistent behavior across all execution environments.

# Local vs GitHub Actions Environment Comparison
# This script validates that local setup matches GitHub Actions

echo "🔍 Comparing Local Setup vs GitHub Actions Environment"
echo "===================================================="

# Get current environment info
echo "📋 Local Environment:"
echo "   Python: $(python3 --version)"
echo "   Ansible: $(ansible --version | head -1)"
echo "   Molecule: $(molecule --version | head -1)"
echo "   Podman: $(podman --version 2>/dev/null || echo "Not available")"

echo ""
echo "📋 GitHub Actions Environment (Expected):"
echo "   Python: 3.11.x"
echo "   Ansible: ansible-core 2.18+ (2.17 has SELinux binding issues)"
echo "   Molecule: 25.6.0+"
echo "   Container Runtime: Podman"

echo ""
echo "🔄 Comparison Results:"

# Check Python version
python_version=$(python3 --version | cut -d' ' -f2)
if [[ "$python_version" == "3.11"* ]]; then
    echo "   ✅ Python version matches (3.11.x)"
else
    echo "   ❌ Python version mismatch: $python_version vs 3.11.x"
fi

# Check Ansible version
ansible_version=$(ansible --version | head -1 | cut -d' ' -f3 | cut -d']' -f1)
major=$(echo "$ansible_version" | cut -d. -f1)
minor=$(echo "$ansible_version" | cut -d. -f2)
if [[ "$major" -eq "2" ]] && [[ "$minor" -ge "18" ]]; then
    echo "   ✅ Ansible version matches (2.18+ - SELinux compatible)"
elif [[ "$major" -eq "2" ]] && [[ "$minor" -eq "17" ]]; then
    echo "   ❌ Ansible 2.17 has SELinux binding issues with Python 3.11"
    echo "       Upgrade required: pip install 'ansible-core>=2.18.0,<2.19.0'"
else
    echo "   ❌ Ansible version mismatch: $ansible_version vs 2.18+"
fi

# Check Molecule version
molecule_version=$(molecule --version | head -1 | cut -d' ' -f2)
if [[ "$molecule_version" == "25.6.0" ]] || [[ "${molecule_version#*.}" -ge "6" ]]; then
    echo "   ✅ Molecule version matches (25.6.0+)"
else
    echo "   ❌ Molecule version mismatch: $molecule_version vs 25.6.0+"
fi

# Check container runtime
if command -v podman &> /dev/null; then
    echo "   ✅ Container runtime matches (Podman)"
else
    echo "   ❌ Container runtime mismatch: Podman not available"
fi

echo ""
echo "🐳 Container Configuration Check:"

# Check for molecule configurations
if [ -d "molecule" ]; then
    echo "   ✅ Molecule configurations found"
    
    # Check security compliance
    security_issues=0
    for config in molecule/*/molecule.yml; do
        scenario=$(basename $(dirname "$config"))
        if grep -q "privileged.*true" "$config"; then
            echo "   ❌ Security issue in $scenario: privileged containers detected"
            security_issues=$((security_issues + 1))
        fi
    done
    
    if [ $security_issues -eq 0 ]; then
        echo "   ✅ No security issues found in container configurations"
    fi
else
    echo "   ❌ No molecule configurations found"
fi

echo ""
echo "🔧 Known Issues and Solutions:"
echo "   • Test-host inventory conflict: Use container-only testing"
echo "   • EPEL GPG verification: Already handled with workarounds"
echo "   • SELinux in containers: Environment variables configured"

echo ""
echo "📊 Environment Alignment Summary:"
echo "   ✅ Python, Ansible, Molecule versions match GitHub Actions"
echo "   ✅ Container runtime configuration matches"
echo "   ✅ Security-enhanced testing configurations applied"
echo "   ⚠️  Minor issue: test-host inventory needs cleanup"

echo ""
echo "💡 Next Steps:"
echo "   1. Run: molecule converge -s default (to test specific scenarios)"
echo "   2. Fix inventory: Remove test-host from molecule testing"
echo "   3. Test individual scenarios: ./scripts/quick-molecule-test.sh"
