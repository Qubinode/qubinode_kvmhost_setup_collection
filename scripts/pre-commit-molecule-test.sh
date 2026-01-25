#!/bin/bash
# =============================================================================
# Pre-commit Molecule Test Hook - ADR-0011 Enforcement
# =============================================================================
# This script is called by pre-commit on push to enforce mandatory local
# Molecule testing before code reaches CI/CD.
#
# Exit codes:
#   0 - All tests passed, push allowed
#   1 - Tests failed or skipped, push blocked
# =============================================================================

set -e

echo "=============================================="
echo "ADR-0011: Local Molecule Testing Quality Gate"
echo "=============================================="
echo ""

# Check if we're in the right directory
if [ ! -f "galaxy.yml" ] && [ ! -f "molecule/default/molecule.yml" ]; then
    echo "Warning: Not in collection root directory"
    echo "Skipping Molecule tests..."
    exit 0
fi

# Check for Ansible-related changes
ANSIBLE_CHANGES=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.(yml|yaml)$' | grep -vE '^(\.github/|docs/|\.ansible/)' || true)

if [ -z "$ANSIBLE_CHANGES" ]; then
    echo "No Ansible-related changes detected."
    echo "Skipping Molecule tests..."
    exit 0
fi

echo "Ansible-related changes detected:"
echo "$ANSIBLE_CHANGES" | head -10
if [ $(echo "$ANSIBLE_CHANGES" | wc -l) -gt 10 ]; then
    echo "... and $(( $(echo "$ANSIBLE_CHANGES" | wc -l) - 10 )) more files"
fi
echo ""

# Check for skip flag (emergency use only)
if [ "$SKIP_MOLECULE_TESTS" = "1" ] || [ "$SKIP_MOLECULE_TESTS" = "true" ]; then
    echo "WARNING: SKIP_MOLECULE_TESTS is set"
    echo "Molecule tests skipped - use with caution!"
    echo ""
    echo "This bypasses ADR-0011 quality gates."
    echo "CI/CD may fail if issues are present."
    exit 0
fi

# Check if molecule is available
if ! command -v molecule &> /dev/null; then
    echo "ERROR: Molecule not found in PATH"
    echo ""
    echo "To install:"
    echo "  ./scripts/setup-local-testing.sh"
    echo ""
    echo "Or manually:"
    echo "  pip install molecule molecule-podman ansible-core>=2.18"
    echo ""
    echo "To skip (emergency only):"
    echo "  SKIP_MOLECULE_TESTS=1 git push"
    exit 1
fi

# Check if podman/docker is available
if ! command -v podman &> /dev/null && ! command -v docker &> /dev/null; then
    echo "ERROR: No container runtime found (podman or docker)"
    echo ""
    echo "Install Podman (recommended):"
    echo "  dnf install podman"
    exit 1
fi

echo "Running local Molecule tests..."
echo ""

# Determine which scenario to run based on changes
SCENARIO="default"

# Check for specific role changes
if echo "$ANSIBLE_CHANGES" | grep -q "roles/kvmhost_setup"; then
    echo "Changes detected in kvmhost_setup role"
fi

# Run the main testing script
if [ -x "scripts/test-local-molecule.sh" ]; then
    echo "Executing: scripts/test-local-molecule.sh"
    echo ""

    if ./scripts/test-local-molecule.sh; then
        echo ""
        echo "=============================================="
        echo "All Molecule tests PASSED"
        echo "Push allowed - ADR-0011 compliance verified"
        echo "=============================================="
        exit 0
    else
        echo ""
        echo "=============================================="
        echo "ERROR: Molecule tests FAILED"
        echo "Push BLOCKED - Fix issues before pushing"
        echo "=============================================="
        echo ""
        echo "Troubleshooting:"
        echo "  1. Review test output above for failures"
        echo "  2. Run manually: ./scripts/test-local-molecule.sh"
        echo "  3. Check molecule/default/molecule.yml configuration"
        echo "  4. See: docs/archive/adrs/adr-0011-local-molecule-testing-validation-before-cicd.md"
        echo ""
        echo "Emergency skip (use with caution):"
        echo "  SKIP_MOLECULE_TESTS=1 git push"
        exit 1
    fi
else
    echo "ERROR: scripts/test-local-molecule.sh not found or not executable"
    echo "Run: chmod +x scripts/test-local-molecule.sh"
    exit 1
fi
