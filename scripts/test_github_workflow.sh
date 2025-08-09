#!/bin/bash

# =============================================================================
# GitHub Workflow Validator - The "CI/CD Integration Tester"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script helps test and validate GitHub Actions workflows locally,
# ensuring automated ansible-lint fixes and CI/CD processes work correctly.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: GitHub CLI Validation - Ensures GitHub CLI tools are available
# 2. [PHASE 2]: Workflow Simulation - Simulates GitHub Actions workflow steps
# 3. [PHASE 3]: Integration Testing - Tests workflow integration with repository
# 4. [PHASE 4]: Result Validation - Validates workflow execution results
# 5. [PHASE 5]: Error Detection - Identifies workflow issues and failures
# 6. [PHASE 6]: Troubleshooting Guidance - Provides workflow troubleshooting help
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Tests: GitHub Actions workflows for ansible-lint automation
# - Validates: CI/CD integration and workflow functionality
# - Simulates: Workflow execution in local development environment
# - Coordinates: With GitHub CLI for workflow testing and validation
# - Supports: Workflow development and troubleshooting processes
# - Ensures: Workflows function correctly before deployment
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - SIMULATION: Simulates GitHub Actions workflow execution locally
# - VALIDATION: Validates workflow functionality and integration
# - TESTING: Provides comprehensive workflow testing capabilities
# - TROUBLESHOOTING: Helps identify and resolve workflow issues
# - INTEGRATION: Tests integration between local and CI/CD environments
# - GUIDANCE: Provides clear guidance for workflow development
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Workflows: Add testing for new GitHub Actions workflows
# - CLI Updates: Update for new GitHub CLI features or commands
# - Integration: Add integration with new CI/CD platforms or tools
# - Validation: Add new workflow validation checks and tests
# - Troubleshooting: Enhance troubleshooting guidance and diagnostics
# - Automation: Add automated workflow testing and validation
#
# 🚨 IMPORTANT FOR LLMs: This script tests CI/CD workflows that affect
# production systems. Ensure workflow tests are accurate and comprehensive.
# Workflow issues can disrupt development and deployment processes.

# Quick Test of GitHub Actions Workflow
# This script helps you test the automated ansible-lint fixes workflow

echo "🚀 GitHub Actions Workflow Test Helper"
echo "======================================"

# Check if GitHub CLI is available
if ! command -v gh >/dev/null 2>&1; then
    echo "❌ GitHub CLI not found. Install with:"
    echo "   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo "   echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
    echo "   sudo apt update && sudo apt install gh"
    echo ""
    echo "🔧 Alternative: Test locally with our verification script:"
    echo "   ./scripts/verify_github_actions.sh"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "❌ Not in a git repository. Please run this from your project root."
    exit 1
fi

# Check if user is authenticated with GitHub
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ Not authenticated with GitHub. Run:"
    echo "   gh auth login"
    exit 1
fi

echo "✅ Prerequisites check passed!"
echo ""

# Show current status
echo "📊 Current Project Status:"
echo "=========================="

# Count current ansible-lint issues
CURRENT_ISSUES=$(ansible-lint roles/ --exclude roles/.cache/ --exclude roles/.venv/ 2>/dev/null | wc -l || echo "0")
echo "Current ansible-lint output lines: $CURRENT_ISSUES"

# Check for existing automation PRs
EXISTING_PRS=$(gh pr list --label="automated,ansible-lint" --state=open 2>/dev/null | wc -l || echo "0")
echo "Open automation PRs: $EXISTING_PRS"

echo ""

# Options for user
echo "🎯 Testing Options:"
echo "=================="
echo "1. 🧪 Test locally (recommended first step)"
echo "2. 🚀 Trigger GitHub Actions workflow"
echo "3. 📊 Check workflow status"
echo "4. 📋 View automation dashboard"
echo ""

read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo "🧪 Running local verification..."
        if [ -f "./scripts/verify_github_actions.sh" ]; then
            ./scripts/verify_github_actions.sh
        else
            echo "❌ Verification script not found. Please ensure you're in the project root."
        fi
        ;;
    2)
        echo "🚀 Triggering GitHub Actions workflow..."
        echo "This will run the automated ansible-lint fixes in GitHub Actions."
        read -p "Continue? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            gh workflow run automated-ansible-lint-fixes.yml
            echo "✅ Workflow triggered! Check GitHub Actions tab for progress."
            echo "🔗 View at: https://github.com/$(gh repo view --json owner,name -q '.owner.login + \"/\" + .name')/actions"
        else
            echo "Cancelled."
        fi
        ;;
    3)
        echo "📊 Checking workflow status..."
        echo "Recent workflow runs:"
        gh run list --workflow="automated-ansible-lint-fixes.yml" --limit=5
        ;;
    4)
        echo "📋 Running automation dashboard..."
        if [ -f "./scripts/automation_dashboard.sh" ]; then
            ./scripts/automation_dashboard.sh
        else
            echo "❌ Dashboard script not found."
        fi
        ;;
    *)
        echo "Invalid option. Please choose 1-4."
        ;;
esac

echo ""
echo "💡 Pro Tips:"
echo "- Test locally first with option 1"
echo "- Monitor workflow runs with: gh run watch"
echo "- View PR details with: gh pr list --label=\"automated\""
echo "- Use the dashboard regularly: ./scripts/automation_dashboard.sh"
