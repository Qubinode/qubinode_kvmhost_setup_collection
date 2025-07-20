#!/bin/bash
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
