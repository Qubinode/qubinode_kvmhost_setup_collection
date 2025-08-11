#!/bin/bash
set -e

echo "🚀 Deploying tag detection fix to GitHub..."

# Check if we have the correct logic locally
echo "🔍 Verifying local fix..."
if grep -q 'if \[ -n "\${{ inputs\.tag }}" \]' .github/workflows/release.yml; then
    echo "✅ Local file contains correct tag detection logic"
else
    echo "❌ Local file missing correct logic!"
    exit 1
fi

# Add the specific file
echo "📝 Adding workflow file..."
git add .github/workflows/release.yml

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo "ℹ️ No changes to commit - fix may already be pushed"
    exit 0
fi

# Commit with descriptive message
echo "💾 Committing tag detection fix..."
git commit -m "fix: Use inputs.tag presence for workflow_call detection

- Replace github.event_name check with inputs.tag presence check
- More reliable detection for workflow_call vs push events  
- Resolves tag detection failure in AI-powered release pipeline
- Enables proper version extraction from manual release workflow"

# Push to main branch
echo "🚀 Pushing to GitHub..."
git push origin main

echo "✅ Tag detection fix deployed successfully!"
echo "🔗 Check GitHub repository to verify changes"
