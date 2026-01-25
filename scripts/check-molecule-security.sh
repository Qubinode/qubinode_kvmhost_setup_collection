#!/bin/bash
# =============================================================================
# Molecule Security Compliance Check - ADR-0012 & ADR-0013 Enforcement
# =============================================================================
# Validates that Molecule configurations comply with security requirements:
# - No privileged containers (ADR-0012)
# - Use of init containers with systemd support
# - Proper capability configuration (SYS_ADMIN only, not privileged)
# =============================================================================

# Don't use set -e as arithmetic expansion can return non-zero

echo "Checking Molecule security compliance (ADR-0012 & ADR-0013)..."

VIOLATIONS=0
WARNINGS=0

# Check all molecule.yml files
for molecule_file in molecule/*/molecule.yml; do
    if [ ! -f "$molecule_file" ]; then
        continue
    fi

    scenario=$(basename $(dirname "$molecule_file"))

    # Check for privileged: true (security violation)
    if grep -qE "^\s*privileged:\s*true" "$molecule_file" 2>/dev/null; then
        echo "ERROR: [$scenario] Privileged container detected - ADR-0012 violation"
        echo "       File: $molecule_file"
        echo "       Fix: Remove 'privileged: true' and use 'capabilities: [SYS_ADMIN]' instead"
        ((VIOLATIONS++))
    fi

    # Check for non-init images (warning)
    if grep -qE "^\s*image:" "$molecule_file"; then
        images=$(grep -E "^\s*image:" "$molecule_file" | sed 's/.*image:\s*//' | tr -d '"' | tr -d "'" || true)
        while IFS= read -r image; do
            if [ -z "$image" ]; then
                continue
            fi
            # Check if it's an init container
            if ! echo "$image" | grep -qE "(ubi.*-init|rockylinux.*-init|almalinux.*-init|stream9)"; then
                echo "WARNING: [$scenario] Non-init image detected: $image"
                echo "         Consider using init-enabled image for systemd support"
                ((WARNINGS++))
            fi
        done <<< "$images"
    fi

    # Check for systemd: always (recommended pattern)
    if ! grep -qE "^\s*systemd:\s*(always|true)" "$molecule_file" 2>/dev/null; then
        if grep -qE "^\s*command:.*init" "$molecule_file" 2>/dev/null; then
            # Has init command, acceptable alternative
            :
        else
            echo "INFO: [$scenario] Consider adding 'systemd: always' for automatic tmpfs handling"
        fi
    fi
done

echo ""

if [ $VIOLATIONS -gt 0 ]; then
    echo "=============================================="
    echo "FAILED: $VIOLATIONS security violation(s) found"
    echo "=============================================="
    echo ""
    echo "See ADR-0012 for security-enhanced container testing requirements:"
    echo "  docs/archive/adrs/adr-0012-init-container-vs-regular-container-molecule-testing.md"
    exit 1
fi

if [ $WARNINGS -gt 0 ]; then
    echo "Completed with $WARNINGS warning(s)"
else
    echo "All Molecule configurations comply with security requirements"
fi

exit 0
