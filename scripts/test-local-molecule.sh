#!/bin/bash
# Local Molecule Testing Script
# Based on research findings from docs/research/local-molecule-testing-validation-2025-01-12.md
# Validates ADR-0012 compliance: Use Init Containers for Molecule Testing

set -e

echo "🧪 Local Molecule Testing Validation Script"
echo "==========================================="

# Check Python version (research recommends 3.11 for RHEL 9)
python_version=$(python3 --version 2>&1 | cut -d" " -f2 | cut -d"." -f1,2)
echo "📋 Python version detected: $python_version"

if [[ "$python_version" == "3.11" ]] || [[ "$python_version" == "3.12" ]]; then
    echo "✅ Python version is optimal for Molecule testing"
elif [[ "$python_version" == "3.9" ]]; then
    echo "⚠️  Python 3.9 detected - consider upgrading to 3.11 for better performance"
    echo "   Install with: dnf install python3.11"
else
    echo "❌ Python version may have compatibility issues"
fi

# Check Molecule version
if command -v molecule &> /dev/null; then
    molecule_version=$(molecule --version | head -1 | cut -d" " -f2)
    echo "📋 Molecule version: $molecule_version"
    
    if [[ "${molecule_version%%.*}" -ge "6" ]] || [[ "${molecule_version}" == "25"* ]]; then
        echo "✅ Molecule version is current (research recommends v25.6.0+)"
    else
        echo "⚠️  Consider upgrading Molecule: pip install 'molecule>=25.6.0'"
    fi
else
    echo "❌ Molecule not found."
    echo ""
    echo "🔧 To fix this:"
    echo "   Option 1 (Recommended): Run setup script"
    echo "     ./scripts/setup-local-testing.sh"
    echo ""
    echo "   Option 2: Manual installation"
    echo "     pip install molecule molecule-plugins[docker]"
    echo ""
    echo "   Option 3: Use virtual environment"
    echo "     python3 -m venv ~/.local/molecule-env"
    echo "     source ~/.local/molecule-env/bin/activate"
    echo "     pip install molecule molecule-plugins[docker] ansible-core"
    echo ""
    echo "🛡️ This is a CRITICAL requirement for ADR-0011 compliance"
    echo "📋 Rule: mandatory-local-testing-before-push"
    exit 1
fi

# Check Ansible version
if command -v ansible &> /dev/null; then
    ansible_version=$(ansible --version | head -1 | cut -d" " -f3 | cut -d"]" -f1)
    echo "📋 Ansible version: $ansible_version"
    
    if [[ "${ansible_version%%.*}" -ge "2" ]] && [[ "${ansible_version#*.}" -ge "17" ]] 2>/dev/null; then
        echo "✅ Ansible version supports current best practices"
    else
        echo "⚠️  Consider upgrading Ansible: pip install 'ansible-core>=2.17'"
    fi
else
    echo "❌ Ansible not found"
    exit 1
fi

# Check container runtime (research recommends Podman over Docker)
if command -v podman &> /dev/null; then
    echo "✅ Podman available (research-recommended for RHEL 9)"
elif command -v docker &> /dev/null; then
    echo "⚠️  Docker available (consider migrating to Podman for RHEL 9)"
else
    echo "❌ No container runtime found. Install Podman: dnf install podman"
    exit 1
fi

echo ""
echo "🐳 Validating Container Image Compliance (ADR-0012)"
echo "===================================================="

# Check for init container compliance in molecule configurations
init_compliance_failed=false

if [ -d "molecule" ]; then
    for molecule_file in molecule/*/molecule.yml; do
        if [ -f "$molecule_file" ]; then
            scenario_name=$(basename $(dirname "$molecule_file"))
            echo "📋 Checking scenario: $scenario_name"
            
            # Extract image names from molecule.yml
            images=$(grep -E "^\s*image:" "$molecule_file" | sed 's/.*image:\s*//' | tr -d '"' | tr -d "'" || true)
            
            if [ -n "$images" ]; then
                while IFS= read -r image; do
                    # Check if image is an init container per ADR-0012
                    if echo "$image" | grep -qE "(ubi.*-init|rockylinux.*-init|almalinux.*-init)" || \
                       echo "$image" | grep -qE "centos:stream9"; then
                        echo "  ✅ Init image compliant: $image"
                    else
                        echo "  ❌ Non-init image found: $image"
                        echo "     🚫 Violates ADR-0012: Use Init Containers for Molecule Testing"
                        echo "     💡 Available init images documented in: molecule/AVAILABLE_INIT_IMAGES.md"
                        init_compliance_failed=true
                    fi
                done <<< "$images"
            else
                echo "  ⚠️  No images found in $molecule_file"
            fi
        fi
    done
    
    if [ "$init_compliance_failed" = true ]; then
        echo ""
        echo "❌ CRITICAL: ADR-0012 Compliance Failed"
        echo "🚫 BLOCKING CI/CD - Update to use only init containers"
        echo "📖 See: docs/adrs/adr-0012-init-container-vs-regular-container-molecule-testing.md"
        echo "📋 Available images: molecule/AVAILABLE_INIT_IMAGES.md"
        exit 1
    else
        echo "✅ All images comply with ADR-0012 init container requirement"
    fi
else
    echo "⚠️  No molecule directory found"
fi

echo ""
echo "🧪 Running Local Molecule Tests"
echo "================================"

# Define test scenarios based on project structure
test_scenarios=("default")

# Check for additional scenarios
if [ -d "molecule" ]; then
    scenarios=$(find molecule -maxdepth 1 -type d ! -name molecule | sed 's|molecule/||' | grep -v '^$' || true)
    if [ -n "$scenarios" ]; then
        test_scenarios=($(echo $scenarios))
    fi
fi

echo "📋 Found test scenarios: ${test_scenarios[*]}"

# Run tests for each scenario
for scenario in "${test_scenarios[@]}"; do
    echo ""
    echo "🔬 Testing scenario: $scenario"
    echo "------------------------------"
    
    if [ -d "molecule/$scenario" ]; then
        echo "✅ Scenario directory exists"
        
        # Run molecule test for this scenario
        if molecule test -s "$scenario"; then
            echo "✅ Scenario '$scenario' passed"
        else
            echo "❌ Scenario '$scenario' failed"
            echo "🚫 BLOCKING CI/CD - Fix issues before pushing"
            exit 1
        fi
    else
        echo "⚠️  Scenario directory not found: molecule/$scenario"
    fi
done

echo ""
echo "🎉 All local Molecule tests passed!"
echo "✅ Safe to proceed with CI/CD"
echo ""
echo "💡 Tips based on research findings:"
echo "   - Use Python 3.11 for 10-60% performance improvement"
echo "   - Consider upgrading to Ansible-core 2.17+ for enhanced features"
echo "   - Podman is preferred over Docker for RHEL 9 environments"
echo "   - Self-hosted runners are essential for KVM/libvirt testing"
echo "   - Only use init containers (ADR-0012): ubi-init, rockylinux-init, almalinux-init"
echo "   - Available init images documented in: molecule/AVAILABLE_INIT_IMAGES.md"
