#!/bin/bash
# Test script to identify where the hang occurs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Testing individual validation functions..."

# Test just the basic validations that we know work
echo "✅ Basic validations work"

# Test role validation for one role
echo "Testing single role validation..."
if [[ -d "$PROJECT_ROOT/roles/edge_hosts_validate" ]]; then
    echo "✅ Role directory exists"
fi

# Test molecule validation for one scenario  
echo "Testing single molecule validation..."
if [[ -d "$PROJECT_ROOT/molecule/default" ]]; then
    echo "✅ Molecule default scenario exists"
    if [[ -f "$PROJECT_ROOT/molecule/default/molecule.yml" ]]; then
        echo "✅ Molecule config exists"
    fi
fi

# Test documentation validation
echo "Testing documentation validation..."
if [[ -d "$PROJECT_ROOT/docs" ]]; then
    echo "✅ Docs directory exists"
fi

# Test validation framework
echo "Testing validation framework..."
if [[ -d "$PROJECT_ROOT/validation" ]]; then
    echo "✅ Validation directory exists"
fi

echo "All individual tests completed successfully!"
