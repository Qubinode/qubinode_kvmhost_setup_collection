#!/bin/bash
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
