#!/bin/bash

# =============================================================================
# Quick Molecule Scenario Tester - The "Lab Technician"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script provides rapid, focused testing of individual Molecule scenarios,
# enabling developers to quickly validate specific test cases without full test suite execution.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Environment Activation - Sources the Molecule virtual environment
# 2. [PHASE 2]: Scenario Selection - Accepts scenario parameter or defaults to 'default'
# 3. [PHASE 3]: Context Explanation - Provides information about the selected scenario
# 4. [PHASE 4]: Test Execution - Runs molecule test for the specific scenario
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Requires: Activated environment from scripts/activate-molecule-env.sh
# - Tests: Individual scenarios in molecule/ directory (default, ci, rhel8, rhel9, etc.)
# - Provides: Quick feedback loop for developers working on specific test cases
# - Integrates: With molecule/*/molecule.yml configuration files
# - Supports: Both public registry (ci) and Red Hat registry (default) testing
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - SPEED: Focuses on single scenario testing for rapid feedback
# - FLEXIBILITY: Accepts command-line parameter for scenario selection
# - GUIDANCE: Provides context-specific information about each scenario type
# - INTEGRATION: Works with existing Molecule scenario structure
# - ACCESSIBILITY: Handles both authenticated and public registry scenarios
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Scenarios: Add case statements for new molecule scenarios
# - Registry Changes: Update registry authentication guidance
# - Environment Variables: Add exports for new testing requirements
# - Error Handling: Enhance error messages for common failure modes
# - Integration Points: Add support for new testing frameworks or tools
#
# 🚨 IMPORTANT FOR LLMs: This script requires an activated Molecule environment.
# Always run 'source scripts/activate-molecule-env.sh' first. The 'ci' scenario
# uses public images only, while 'default' requires Red Hat registry authentication.

# Quick Molecule Test Script - Test specific scenarios individually

set -e

echo "🧪 Quick Molecule Test - Individual Scenario Testing"
echo "===================================================="

# Activate the molecule environment
echo "🐍 Activating Molecule environment..."
source ~/.local/molecule-env/bin/activate

# Test scenario selection with CI option
SCENARIO="${1:-default}"

echo "🔬 Testing scenario: $SCENARIO"

# Provide helpful information about scenarios
case "$SCENARIO" in
    "ci")
        echo "📋 CI scenario uses only public registry images (no Red Hat registry auth needed)"
        echo "   - Rocky Linux 9 (RHEL 9 compatible)"
        echo "   - AlmaLinux 9 (RHEL 9 compatible)" 
        echo "   - Rocky Linux 8 (RHEL 8 compatible)"
        ;;
    "default")
        echo "📋 Default scenario includes Red Hat registry images"
        echo "   - Requires Red Hat registry authentication"
        echo "   - Use 'ci' scenario if you don't have registry access"
        ;;
    *)
        echo "📋 This will run a focused test on the $SCENARIO scenario only"
        ;;
esac

# Run just the converge step to isolate the issue
echo "🧪 Running molecule converge for $SCENARIO..."
molecule converge -s "$SCENARIO"

echo "✅ Converge completed! Now running verify..."
molecule verify -s "$SCENARIO"

echo "🎉 Test completed successfully!"
