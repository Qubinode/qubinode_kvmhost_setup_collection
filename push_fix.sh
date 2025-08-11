#!/bin/bash
set -e

echo "🔧 Pushing tag detection fix..."

# Add all changes
git add .github/workflows/release.yml

# Commit with simple message
git commit -m "fix: Use inputs.tag presence for workflow_call detection"

# Push to main
git push origin main

echo "✅ Fix pushed successfully!"
