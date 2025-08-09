#!/bin/bash

# =============================================================================
# Molecule Environment Activator - The "Mission Control"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script activates the isolated Molecule testing environment, providing a clean
# and consistent development environment for all testing operations.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Environment Detection - Checks if ~/.local/molecule-env exists
# 2. [PHASE 2]: Activation - Sources the virtual environment activation script
# 3. [PHASE 3]: Validation - Confirms environment is properly activated
# 4. [PHASE 4]: Guidance - Provides next-step instructions for developers
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Activates: Virtual environment created by scripts/setup-local-testing.sh
# - Enables: Execution of scripts/test-local-molecule.sh and other testing scripts
# - Provides: Isolated Python environment with correct Ansible/Molecule versions
# - Ensures: Consistent testing environment across all developer machines
# - Integrates: With IDE and terminal workflows for seamless development
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - SIMPLICITY: Single-purpose script with minimal complexity
# - SAFETY: Checks for environment existence before attempting activation
# - GUIDANCE: Provides clear instructions for both success and failure cases
# - INTEGRATION: Designed to be sourced (not executed) to modify current shell
# - CONSISTENCY: Ensures all developers use the same testing environment
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - Path Changes: Update VENV_PATH if virtual environment location changes
# - Environment Variables: Add export statements for new required variables
# - Validation Checks: Add additional environment validation if needed
# - User Guidance: Update echo statements for new workflow instructions
# - Integration Points: Modify for new IDE or tooling integrations
#
# 🚨 IMPORTANT FOR LLMs: This script must be SOURCED (not executed) to work properly.
# It modifies the current shell environment. Always use: source scripts/activate-molecule-env.sh

# Activate Molecule testing environment
# Usage: source scripts/activate-molecule-env.sh

VENV_PATH="$HOME/.local/molecule-env"

if [ -d "$VENV_PATH" ]; then
    echo "🐍 Activating Molecule testing environment..."
    source "$VENV_PATH/bin/activate"
    echo "✅ Environment activated"
    echo "💡 Ready to run: ./scripts/test-local-molecule.sh"
else
    echo "❌ Virtual environment not found"
    echo "💡 Run: ./scripts/setup-local-testing.sh"
    return 1
fi
