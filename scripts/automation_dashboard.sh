#!/bin/bash

# Ansible Lint Automation Dashboard
# Provides status overview of automated ansible-lint fixes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Emojis for better UX
CHECK="✅"
ERROR="❌"
WARNING="⚠️"
INFO="ℹ️"
ROCKET="🚀"
CHART="📊"
BOT="🤖"

echo -e "${BLUE}${BOT} Ansible Lint Automation Dashboard${NC}"
echo "======================================="

# Function to get last workflow run status
get_workflow_status() {
    if command -v gh >/dev/null 2>&1; then
        echo -e "${INFO} Checking latest workflow runs...${NC}"
        
        # Get latest ansible-lint automation workflow
        LATEST_RUN=$(gh run list --workflow="automated-ansible-lint-fixes.yml" --limit=1 --json=status,conclusion,createdAt,headBranch 2>/dev/null || echo "")
        
        if [ -n "$LATEST_RUN" ] && [ "$LATEST_RUN" != "[]" ]; then
            STATUS=$(echo "$LATEST_RUN" | jq -r '.[0].status')
            CONCLUSION=$(echo "$LATEST_RUN" | jq -r '.[0].conclusion')
            CREATED_AT=$(echo "$LATEST_RUN" | jq -r '.[0].createdAt')
            BRANCH=$(echo "$LATEST_RUN" | jq -r '.[0].headBranch')
            
            echo -e "${CHART} Latest Automation Run:"
            echo -e "  Status: $STATUS"
            echo -e "  Result: $CONCLUSION"
            echo -e "  Date: $CREATED_AT"
            echo -e "  Branch: $BRANCH"
            
            case "$CONCLUSION" in
                "success")
                    echo -e "${GREEN}${CHECK} Last run completed successfully${NC}"
                    ;;
                "failure")
                    echo -e "${RED}${ERROR} Last run failed${NC}"
                    ;;
                "cancelled")
                    echo -e "${YELLOW}${WARNING} Last run was cancelled${NC}"
                    ;;
                *)
                    echo -e "${BLUE}${INFO} Last run: $CONCLUSION${NC}"
                    ;;
            esac
        else
            echo -e "${YELLOW}${WARNING} No automation workflow runs found${NC}"
        fi
    else
        echo -e "${YELLOW}${WARNING} GitHub CLI not available - install 'gh' for workflow status${NC}"
    fi
}

# Function to check for open automation PRs
check_automation_prs() {
    if command -v gh >/dev/null 2>&1; then
        echo -e "\n${INFO} Checking for open automation PRs...${NC}"
        
        # Look for open PRs with automation labels
        AUTOMATION_PRS=$(gh pr list --label="automated,ansible-lint" --state=open --json=number,title,createdAt,author 2>/dev/null || echo "[]")
        
        if [ "$AUTOMATION_PRS" != "[]" ] && [ -n "$AUTOMATION_PRS" ]; then
            PR_COUNT=$(echo "$AUTOMATION_PRS" | jq length)
            echo -e "${CHART} Found $PR_COUNT open automation PR(s):"
            
            echo "$AUTOMATION_PRS" | jq -r '.[] | "  PR #\(.number): \(.title) (by \(.author.login))"'
            echo -e "${INFO} Review and merge these PRs to apply automated fixes${NC}"
        else
            echo -e "${GREEN}${CHECK} No open automation PRs found${NC}"
        fi
    fi
}

# Function to show current ansible-lint status
show_current_status() {
    echo -e "\n${CHART} Current Ansible-Lint Status:"
    echo "============================"
    
    if command -v ansible-lint >/dev/null 2>&1; then
        # Count current issues by counting lines that contain violations
        CURRENT_ISSUES=$(ansible-lint roles/ --exclude roles/.cache/ --exclude roles/.venv/ 2>/dev/null | grep -c ":" || echo "0")
        # Clean up any newlines or extra characters
        CURRENT_ISSUES=$(echo "$CURRENT_ISSUES" | tr -d '\n' | tr -d ' ')
        echo -e "Current ansible-lint failures: ${CURRENT_ISSUES}"
        
        # Check YAML validity
        YAML_STATUS=$(python3 -c "
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
" 2>/dev/null || echo "N/A")
        
        echo -e "YAML file validity: ${YAML_STATUS}"
        
        if [ "$CURRENT_ISSUES" -eq 0 ]; then
            echo -e "${GREEN}${CHECK} Excellent! No ansible-lint issues detected${NC}"
        elif [ "$CURRENT_ISSUES" -lt 10 ]; then
            echo -e "${YELLOW}${WARNING} Low priority: $CURRENT_ISSUES issues detected${NC}"
        elif [ "$CURRENT_ISSUES" -lt 50 ]; then
            echo -e "${YELLOW}${WARNING} Medium priority: $CURRENT_ISSUES issues detected${NC}"
        else
            echo -e "${RED}${ERROR} High priority: $CURRENT_ISSUES issues detected${NC}"
        fi
    else
        echo -e "${YELLOW}${WARNING} ansible-lint not installed${NC}"
        echo -e "Install with: pip install ansible-lint[yamllint]"
    fi
}

# Function to show automation toolkit status
show_toolkit_status() {
    echo -e "\n${ROCKET} Automation Toolkit Status:"
    echo "=========================="
    
    # Check if scripts exist
    SCRIPTS=(
        "scripts/ansible_lint_toolkit.sh"
        "scripts/fix_yaml_parsing.py"
        "scripts/fix_ansible_lint.py"
        "scripts/fix_ansible_lint_advanced.py"
        "scripts/fix_escape_chars.py"
        "scripts/validate_automation_toolkit.sh"
    )
    
    SCRIPT_COUNT=0
    for script in "${SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            ((SCRIPT_COUNT++))
            echo -e "${GREEN}${CHECK} $script${NC}"
        else
            echo -e "${RED}${ERROR} $script (missing)${NC}"
        fi
    done
    
    echo -e "\nToolkit completeness: $SCRIPT_COUNT/${#SCRIPTS[@]} scripts available"
    
    # Check workflow file
    if [ -f ".github/workflows/automated-ansible-lint-fixes.yml" ]; then
        echo -e "${GREEN}${CHECK} GitHub Actions workflow configured${NC}"
    else
        echo -e "${RED}${ERROR} GitHub Actions workflow missing${NC}"
    fi
}

# Function to show recommendations
show_recommendations() {
    echo -e "\n${INFO} Recommendations:"
    echo "=================="
    
    # Check if automation is scheduled
    if [ -f ".github/workflows/automated-ansible-lint-fixes.yml" ]; then
        echo -e "${CHECK} Weekly automation is configured"
        echo -e "${INFO} The automation will run every Sunday at 2 AM UTC"
    fi
    
    # Check current issues
    if command -v ansible-lint >/dev/null 2>&1; then
        CURRENT_ISSUES=$(ansible-lint roles/ --exclude roles/.cache/ --exclude roles/.venv/ 2>/dev/null | grep -c ":" || echo "0")
        # Clean up any newlines or extra characters
        CURRENT_ISSUES=$(echo "$CURRENT_ISSUES" | tr -d '\n' | tr -d ' ')
        
        if [ "$CURRENT_ISSUES" -gt 0 ]; then
            echo -e "${ROCKET} Run manual automation now:"
            echo -e "   ./scripts/ansible_lint_toolkit.sh"
            echo -e "${INFO} Or trigger GitHub Action:"
            echo -e "   gh workflow run automated-ansible-lint-fixes.yml"
        fi
    fi
    
    echo -e "${INFO} Monitor automation PRs regularly and merge approved fixes"
    echo -e "${INFO} Check this dashboard weekly: ./scripts/automation_dashboard.sh"
}

# Main execution
get_workflow_status
check_automation_prs
show_current_status
show_toolkit_status
show_recommendations

echo -e "\n${BOT} Dashboard complete! Use 'gh workflow run automated-ansible-lint-fixes.yml' to trigger automation manually."
