#!/bin/bash
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
