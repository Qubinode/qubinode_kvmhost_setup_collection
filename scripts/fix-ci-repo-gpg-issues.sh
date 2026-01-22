#!/bin/bash
# =============================================================================
# CI Repository GPG Fix Script
# =============================================================================
#
# Purpose: Fixes GPG verification issues for third-party repositories on
# GitHub Actions self-hosted runners to prevent CI/CD pipeline failures.
#
# Background: Third-party repositories like gh-cli and EPEL can have GPG
# signature verification failures that block dnf/yum operations. This script
# disables GPG verification for these repos in CI environments only.
#
# Related ADR: ADR-0018 - CI/CD Third-Party Repository GPG Verification Strategy
#
# Usage:
#   chmod +x scripts/fix-ci-repo-gpg-issues.sh
#   ./scripts/fix-ci-repo-gpg-issues.sh
#
# =============================================================================

set -euo pipefail

echo "🔧 Fixing third-party repository GPG issues for CI/CD..."

# List of repositories that commonly have GPG verification issues
PROBLEM_REPOS=(
    "gh-cli"
    "epel"
    "epel-testing"
    "epel-next"
)

FIXES_APPLIED=0

for repo in "${PROBLEM_REPOS[@]}"; do
    REPO_FILE="/etc/yum.repos.d/${repo}.repo"
    if [ -f "$REPO_FILE" ]; then
        REPO_FIXED=false

        # Check and fix gpgcheck=1 (package signature verification)
        if grep -q "gpgcheck=1" "$REPO_FILE" 2>/dev/null; then
            echo "  📦 Disabling GPG check for ${repo} repository..."
            sudo sed -i 's/gpgcheck=1/gpgcheck=0/g' "$REPO_FILE" 2>/dev/null || true
            REPO_FIXED=true
        fi

        # Check and fix repo_gpgcheck=1 (repository metadata signature verification)
        # This is the setting that causes "repomd.xml GPG signature verification error"
        if grep -q "repo_gpgcheck=1" "$REPO_FILE" 2>/dev/null; then
            echo "  📦 Disabling repo metadata GPG check for ${repo} repository..."
            sudo sed -i 's/repo_gpgcheck=1/repo_gpgcheck=0/g' "$REPO_FILE" 2>/dev/null || true
            REPO_FIXED=true
        fi

        # If neither gpgcheck nor repo_gpgcheck is set, add repo_gpgcheck=0 to be safe
        # This handles cases where the default might enable repo_gpgcheck
        if ! grep -q "repo_gpgcheck" "$REPO_FILE" 2>/dev/null; then
            echo "  📦 Adding repo_gpgcheck=0 for ${repo} repository..."
            # Add repo_gpgcheck=0 after the [repo] section header
            sudo sed -i "/^\[${repo}\]/a repo_gpgcheck=0" "$REPO_FILE" 2>/dev/null || true
            REPO_FIXED=true
        fi

        if [ "$REPO_FIXED" = true ]; then
            FIXES_APPLIED=$((FIXES_APPLIED + 1))
        else
            echo "  ✓ ${repo} repository already has GPG checks disabled"
        fi
    fi
done

# Clean all repository metadata to ensure fresh state
echo "🧹 Cleaning repository metadata..."
if command -v dnf &> /dev/null; then
    sudo dnf clean all 2>/dev/null || true
elif command -v yum &> /dev/null; then
    sudo yum clean all 2>/dev/null || true
fi

if [ $FIXES_APPLIED -gt 0 ]; then
    echo "✅ Repository GPG fixes applied successfully! ($FIXES_APPLIED repositories updated)"
else
    echo "✅ No GPG fixes needed - all repositories already configured correctly"
fi
