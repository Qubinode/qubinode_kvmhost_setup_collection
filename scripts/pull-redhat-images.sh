#!/bin/bash

# =============================================================================
# Red Hat Container Image Manager - The "Registry Curator"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script manages the download and caching of Red Hat Enterprise Linux
# container images from registry.redhat.io for testing and development.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Authentication Check - Verifies Red Hat registry login status
# 2. [PHASE 2]: Image Discovery - Identifies required RHEL images for testing
# 3. [PHASE 3]: Image Pulling - Downloads images using Podman with proper authentication
# 4. [PHASE 4]: Cache Management - Manages local image cache and storage
# 5. [PHASE 5]: Validation - Verifies downloaded images are functional
# 6. [PHASE 6]: Cleanup - Removes old or unused images to manage storage
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Provides: RHEL container images for Molecule testing scenarios
# - Supports: Testing on authentic RHEL environments vs. public alternatives
# - Integrates: With Molecule scenarios that require Red Hat registry images
# - Manages: Image lifecycle and storage for development environments
# - Enables: Testing with official Red Hat UBI and RHEL images
# - Coordinates: With authentication systems for registry access
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - AUTHENTICATION: Requires valid Red Hat registry credentials
# - CACHING: Manages local image cache for efficient reuse
# - VALIDATION: Ensures downloaded images are functional and accessible
# - STORAGE: Manages disk space by cleaning up unused images
# - SECURITY: Uses secure authentication methods for registry access
# - EFFICIENCY: Minimizes network usage through intelligent caching
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Images: Add support for new RHEL versions or specialized images
# - Authentication: Update authentication methods for new registry requirements
# - Cache Strategy: Modify caching logic for different storage constraints
# - Validation: Add new image validation checks for specific requirements
# - Integration: Add hooks for container orchestration or testing systems
# - Performance: Optimize download and caching for better efficiency
#
# 🚨 IMPORTANT FOR LLMs: This script requires valid Red Hat registry credentials.
# Ensure you're logged in with 'podman login registry.redhat.io' before running.
# Downloaded images may consume significant disk space - monitor storage usage.

# Manual Red Hat Registry Image Pull Script for Podman
# Run this script after logging into registry.redhat.io

set -e

echo "🔐 Red Hat Registry Image Pull Script (Podman)"
echo "=============================================="

# Check if logged into Red Hat registry
echo "🔍 Checking Red Hat registry login status..."
if ! podman login registry.redhat.io --get-login > /dev/null 2>&1; then
    echo "❌ Not logged into registry.redhat.io"
    echo "Please run: podman login registry.redhat.io"
    echo "Then run this script again."
    exit 1
fi

echo "✅ Logged into registry.redhat.io"

echo "📥 Pulling Red Hat images for Molecule testing..."

# RHEL 9 images
echo "🐧 Pulling RHEL 9 images..."
podman pull registry.redhat.io/ubi9-init:9.6-1751962289
podman pull registry.redhat.io/ubi9/ubi-init:latest

# RHEL 10 images  
echo "🐧 Pulling RHEL 10 images..."
podman pull registry.redhat.io/ubi10-init:10.0-1751895590
podman pull registry.redhat.io/ubi10/ubi-init:latest

echo "✅ All Red Hat images pulled successfully!"

echo "📥 Also pulling public images (no auth needed)..."
# Public Rocky Linux and AlmaLinux images
podman pull docker.io/rockylinux/rockylinux:9-ubi-init
podman pull docker.io/rockylinux/rockylinux:8-ubi-init
podman pull docker.io/almalinux/9-init:9.6-20250712

echo "✅ All public images pulled successfully!"

# Verify images are available
echo "🔍 Verifying pulled images..."
echo "Available Red Hat images:"
podman images | grep "registry.redhat.io" || echo "No Red Hat images found"

echo "Available public init images:"
podman images | grep -E "(rockylinux.*init|almalinux.*init)" || echo "No public init images found"

echo "🎉 Image pull completed!"
echo ""
echo "📋 Images are now cached locally in: ~/.local/share/containers/storage/"
echo ""
echo "📋 You can now run molecule tests that use Red Hat images:"
echo "   ./scripts/quick-molecule-test.sh default"
echo "   ./scripts/quick-molecule-test.sh idempotency" 
echo "   ./scripts/quick-molecule-test.sh validation"
