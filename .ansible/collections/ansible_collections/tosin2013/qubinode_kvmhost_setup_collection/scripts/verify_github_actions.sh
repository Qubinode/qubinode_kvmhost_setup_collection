#!/bin/bash

# GitHub Actions Workflow Verification Script
# This script verifies that our automation does exactly what the GitHub Actions workflow claims

set -euo pipefail

echo "🤖 GitHub Actions Workflow Verification"
echo "======================================="
echo "This simulates the exact steps that run in GitHub Actions"
echo ""

# Step 1: Install dependencies (simulated - we assume they're already installed)
echo "✅ Step 1: Dependencies (ansible-lint, PyYAML) - checking..."
if command -v ansible-lint >/dev/null && python3 -c "import yaml" 2>/dev/null; then
    echo "   ✅ All dependencies available"
else
    echo "   ❌ Missing dependencies - install with: pip install ansible-lint[yamllint] PyYAML"
    exit 1
fi

# Step 2: Make scripts executable  
echo "✅ Step 2: Making automation scripts executable..."
chmod +x scripts/*.sh scripts/*.py 2>/dev/null || true

# Step 3: Pre-automation scan (exactly like GitHub Actions)
echo "✅ Step 3: Running pre-automation ansible-lint scan..."
INITIAL_FAILURES=$(ansible-lint roles/ --exclude roles/.cache/ --exclude roles/.venv/ 2>/dev/null | grep -c ":" || echo "0")
echo "   📊 Initial ansible-lint failures: $INITIAL_FAILURES"

# YAML validity check (exactly like GitHub Actions)
INITIAL_YAML_VALID=$(python3 -c "
import yaml
from pathlib import Path
total = 0
valid = 0
for file in Path('roles/').rglob('*.yml'):
    if '.cache' in str(file) or '.venv' in str(file):
        continue
    total += 1
    try:
        with open(file) as f:
            yaml.safe_load(f)
        valid += 1
    except:
        pass
print(f'{valid}/{total}')
" 2>/dev/null || echo "0/0")
echo "   📊 Initial YAML validity: $INITIAL_YAML_VALID"

# Step 4: Run automation toolkit (exactly like GitHub Actions) 
echo "✅ Step 4: Running automated ansible-lint fixes..."
echo "   🚀 Executing: ./scripts/ansible_lint_toolkit.sh"

# Create backup of git state
BACKUP_DIR="verification_backup_$(date +%s)"
mkdir -p "$BACKUP_DIR"
git status --porcelain > "$BACKUP_DIR/git_status_before.txt" 2>/dev/null || echo "No git repo"

# Run the automation (with output capture like GitHub Actions)
if ./scripts/ansible_lint_toolkit.sh > verification_output.log 2>&1; then
    echo "   ✅ Automation completed successfully"
    AUTOMATION_SUCCESS="true"
else
    echo "   ⚠️ Automation completed with warnings (this may be normal)"
    AUTOMATION_SUCCESS="false"
fi

# Step 5: Extract metrics (exactly like GitHub Actions)
echo "✅ Step 5: Extracting automation metrics..."
FIXED_FILES=$(grep -o "Total files fixed: [0-9]*" verification_output.log | tail -1 | grep -o "[0-9]*" || echo "0")
echo "   📊 Files processed by automation: $FIXED_FILES"

# Check for file changes (exactly like GitHub Actions)
git status --porcelain > "$BACKUP_DIR/git_status_after.txt" 2>/dev/null || echo "No git repo"

if git diff --quiet 2>/dev/null; then
    echo "   📊 File changes: NONE (no modifications detected)"
    CHANGES_MADE="false"
else
    echo "   📊 File changes: DETECTED (files were modified)"
    CHANGES_MADE="true"
    echo "   📝 Modified files:"
    git diff --name-only 2>/dev/null | head -10 | sed 's/^/      - /'
fi

# Step 6: Post-automation scan (exactly like GitHub Actions)
echo "✅ Step 6: Running post-automation ansible-lint scan..."
FINAL_FAILURES=$(ansible-lint roles/ --exclude roles/.cache/ --exclude roles/.venv/ 2>/dev/null | grep -c ":" || echo "0")
echo "   📊 Final ansible-lint failures: $FINAL_FAILURES"

FINAL_YAML_VALID=$(python3 -c "
import yaml
from pathlib import Path
total = 0
valid = 0
for file in Path('roles/').rglob('*.yml'):
    if '.cache' in str(file) or '.venv' in str(file):
        continue
    total += 1
    try:
        with open(file) as f:
            yaml.safe_load(f)
        valid += 1
    except:
        pass
print(f'{valid}/{total}')
" 2>/dev/null || echo "0/0")
echo "   📊 Final YAML validity: $FINAL_YAML_VALID"

# Calculate improvements
if [ "$INITIAL_FAILURES" -ge 0 ] && [ "$FINAL_FAILURES" -ge 0 ] 2>/dev/null; then
    IMPROVEMENTS=$((INITIAL_FAILURES - FINAL_FAILURES))
    echo "   📈 Improvements: $IMPROVEMENTS issues resolved"
else
    IMPROVEMENTS="Unknown"
    echo "   📈 Improvements: Unable to calculate"
fi

# Step 7: Simulation of PR creation decision (like GitHub Actions)
echo "✅ Step 7: GitHub Actions PR creation logic..."
if [ "$CHANGES_MADE" = "true" ]; then
    echo "   🎯 RESULT: GitHub Actions WOULD create a pull request"
    echo "   📋 PR Title: '🤖 Automated Ansible Lint Fixes - $IMPROVEMENTS issues resolved'"
    echo "   🏷️ PR Labels: automated, ansible-lint, code-quality, maintenance"
    echo "   📄 PR would include:"
    echo "      - Before/after metrics"
    echo "      - List of modified files"
    echo "      - Detailed diff (expandable)"
    echo "      - Full automation log (expandable)"
else
    echo "   ✅ RESULT: GitHub Actions would NOT create a pull request (no changes needed)"
    echo "   💬 Would comment: 'No fixes needed - code quality is already excellent!'"
fi

# Summary
echo ""
echo "🎉 GITHUB ACTIONS VERIFICATION COMPLETE"
echo "========================================"
echo "Summary of what GitHub Actions workflow would do:"
echo ""
echo "📊 Before automation:"
echo "   - Ansible-lint failures: $INITIAL_FAILURES"
echo "   - YAML validity: $INITIAL_YAML_VALID"
echo ""
echo "📊 After automation:"
echo "   - Ansible-lint failures: $FINAL_FAILURES" 
echo "   - YAML validity: $FINAL_YAML_VALID"
echo "   - Files modified: $FIXED_FILES"
echo "   - Changes detected: $CHANGES_MADE"
echo ""
echo "🎯 GitHub Actions outcome:"
if [ "$CHANGES_MADE" = "true" ]; then
    echo "   ✅ Would create automated pull request with fixes"
else
    echo "   ✅ Would complete successfully with no action needed"
fi

echo ""
echo "📋 Verification artifacts created:"
echo "   - verification_output.log (automation log)"
echo "   - $BACKUP_DIR/ (git state backup)"
echo ""
echo "🚀 To test the workflow manually in GitHub:"
echo "   gh workflow run automated-ansible-lint-fixes.yml"
