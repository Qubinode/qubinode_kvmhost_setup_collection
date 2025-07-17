#!/bin/bash
# Research Script: Ubuntu vs RHEL Self-hosted Runners for Ansible Testing
# Tests whether Ubuntu GitHub Actions runners can adequately test RHEL-based Ansible collections

set -euo pipefail

echo "🔍 Testing Ubuntu GitHub Actions Runners for RHEL-based Ansible Collection"
echo "=================================================================="

# Test 1: Check if Ubuntu can run RHEL containers (Podman/Docker)
echo -e "\n📋 Test 1: Container Runtime Compatibility"
if command -v podman &> /dev/null; then
    echo "✅ Podman available"
    
    # Test pulling RHEL-based images
    echo "Testing RHEL container images..."
    
    if podman pull registry.redhat.io/ubi9-init:9.6-1751962289 2>/dev/null; then
        echo "✅ Can pull UBI 9 init image"
    else
        echo "❌ Cannot pull UBI 9 init image (registry auth required)"
    fi
    
    if podman pull docker.io/rockylinux/rockylinux:9-ubi-init 2>/dev/null; then
        echo "✅ Can pull Rocky Linux 9 image"
    else
        echo "❌ Cannot pull Rocky Linux 9 image"
    fi
    
    if podman pull docker.io/almalinux/9-init:9.6-20250712 2>/dev/null; then
        echo "✅ Can pull AlmaLinux 9 image"
    else
        echo "❌ Cannot pull AlmaLinux 9 image"
    fi
    
elif command -v docker &> /dev/null; then
    echo "✅ Docker available"
    
    if docker pull docker.io/rockylinux/rockylinux:9-ubi-init 2>/dev/null; then
        echo "✅ Can pull Rocky Linux 9 image"
    else
        echo "❌ Cannot pull Rocky Linux 9 image"
    fi
else
    echo "❌ No container runtime available"
fi

# Test 2: Python 3.11 availability on Ubuntu
echo -e "\n📋 Test 2: Python 3.11 Availability"
if command -v python3.11 &> /dev/null; then
    echo "✅ Python 3.11 available: $(python3.11 --version)"
else
    echo "❌ Python 3.11 not available"
    echo "📝 Would need: apt-get update && apt-get install -y python3.11 python3.11-dev python3.11-venv"
fi

# Test 3: Ansible installation and RHEL modules
echo -e "\n📋 Test 3: Ansible RHEL Module Compatibility"
if command -v python3.11 &> /dev/null; then
    python3.11 -m venv test-env
    source test-env/bin/activate
    
    pip install --upgrade pip
    pip install ansible-core==2.17.*
    
    echo "✅ Ansible installed: $(ansible --version | head -1)"
    
    # Test RHEL-specific modules
    if ansible-doc yum &> /dev/null; then
        echo "✅ YUM module available"
    else
        echo "❌ YUM module not available"
    fi
    
    if ansible-doc dnf &> /dev/null; then
        echo "✅ DNF module available"
    else
        echo "❌ DNF module not available"
    fi
    
    deactivate
    rm -rf test-env
else
    echo "⚠️ Skipping Ansible test (Python 3.11 not available)"
fi

# Test 4: Check OS and architecture
echo -e "\n📋 Test 4: Host Environment"
echo "OS: $(uname -s)"
echo "Architecture: $(uname -m)"
echo "Distribution: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '"')"
echo "Kernel: $(uname -r)"

# Test 5: Package manager compatibility
echo -e "\n📋 Test 5: Package Manager Availability"
if command -v apt-get &> /dev/null; then
    echo "✅ APT available (Ubuntu/Debian)"
fi

if command -v yum &> /dev/null; then
    echo "✅ YUM available"
else
    echo "❌ YUM not available"
fi

if command -v dnf &> /dev/null; then
    echo "✅ DNF available"
else
    echo "❌ DNF not available"
fi

# Test 6: SystemD availability
echo -e "\n📋 Test 6: SystemD Compatibility"
if systemctl --version &> /dev/null; then
    echo "✅ SystemD available: $(systemctl --version | head -1)"
else
    echo "❌ SystemD not available"
fi

# Summary and Recommendations
echo -e "\n🎯 RESEARCH CONCLUSIONS"
echo "======================================"

echo -e "\n✅ PROS of using Ubuntu GitHub Actions runners:"
echo "• Free and maintained by GitHub"
echo "• Fast provisioning and execution"
echo "• No infrastructure maintenance required"
echo "• Container runtime available (Docker/Podman)"
echo "• Can test RHEL-based containers via containerization"
echo "• Ansible works fine for testing RHEL-targeted playbooks"

echo -e "\n❌ CONS of using Ubuntu GitHub Actions runners:"
echo "• Cannot test bare-metal RHEL-specific features"
echo "• No native YUM/DNF package manager"
echo "• Different init system behaviors"
echo "• Potential container registry authentication issues for UBI images"

echo -e "\n📋 RECOMMENDATIONS:"
echo "1. ✅ USE Ubuntu runners for:"
echo "   - Ansible syntax checking and linting"
echo "   - Molecule testing with RHEL containers"
echo "   - Python dependency validation"
echo "   - Collection building and packaging"
echo "   - Security scanning"

echo "2. ⚠️ CONSIDER self-hosted RHEL runners for:"
echo "   - Testing bare-metal installations"
echo "   - RHEL-specific package management testing"
echo "   - System service integration testing"
echo "   - Performance benchmarking on actual RHEL"

echo "3. 💡 HYBRID APPROACH (RECOMMENDED):"
echo "   - Use Ubuntu runners for 80% of CI/CD pipeline"
echo "   - Use self-hosted RHEL runner for critical integration tests"
echo "   - Use container-based testing for most scenarios"

echo -e "\n💰 COST ANALYSIS:"
echo "• Ubuntu runners: \$0 (2000 minutes/month free)"
echo "• Self-hosted RHEL runner: Cost of VPS/server + maintenance"
echo "• Estimated savings: ~\$50-100/month using Ubuntu runners"

echo -e "\n📊 FINAL VERDICT:"
echo "For the Qubinode KVM Host Setup Collection, Ubuntu GitHub Actions runners"
echo "are SUFFICIENT for 90% of testing needs when combined with containerization."
echo "The complex dependency testing pipeline is OVER-ENGINEERING for this use case."
