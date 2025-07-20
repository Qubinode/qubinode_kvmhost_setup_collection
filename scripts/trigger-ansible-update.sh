#!/bin/bash
# Manual trigger for Ansible version update check
# This script can be used to manually test the Ansible monitoring system

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Manual Ansible Version Update Trigger${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

# Check if GitHub CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI not found. Install with: brew install gh${NC}"
    echo "Continuing with local check only..."
    LOCAL_ONLY=true
else
    LOCAL_ONLY=false
fi

echo -e "${GREEN}✅ Running local Ansible version check...${NC}"
./scripts/check-ansible-versions.sh

# Check the exit code
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 New Ansible version available and compatible! This would trigger a PR in the automated workflow.${NC}"
    
    if [ "$LOCAL_ONLY" = false ]; then
        echo ""
        echo "Available actions:"
        echo "1. Trigger automated workflow"
        echo "2. Trigger with specific version"
        echo "3. View current workflow status"
        echo "4. Exit"
        echo ""
        read -p "Choose an option (1-4): " -n 1 -r
        echo
        
        case $REPLY in
            1)
                echo -e "${BLUE}🔄 Triggering automated Ansible update workflow...${NC}"
                gh workflow run ansible-version-auto-pr.yml --field force_check=true
                echo -e "${GREEN}✅ Workflow triggered! Check the Actions tab for progress.${NC}"
                ;;
            2)
                echo ""
                read -p "Enter specific Ansible version to test (e.g., 2.19.0): " VERSION
                if [ -n "$VERSION" ]; then
                    echo -e "${BLUE}🔄 Triggering workflow with version $VERSION...${NC}"
                    gh workflow run ansible-version-auto-pr.yml --field force_check=true --field target_version="$VERSION"
                    echo -e "${GREEN}✅ Workflow triggered with version $VERSION!${NC}"
                else
                    echo -e "${YELLOW}⚠️  No version specified, skipping.${NC}"
                fi
                ;;
            3)
                echo -e "${BLUE}📊 Current workflow status:${NC}"
                gh run list --workflow=ansible-version-auto-pr.yml --limit=5
                ;;
            4)
                echo -e "${BLUE}👋 Exiting...${NC}"
                ;;
            *)
                echo -e "${YELLOW}⚠️  Invalid option selected.${NC}"
                ;;
        esac
    fi
else
    echo ""
    if [ $EXIT_CODE -eq 1 ]; then
        echo -e "${BLUE}✅ Ansible version is up to date. No action needed.${NC}"
    else
        echo -e "${YELLOW}⚠️ Issues detected with Ansible version testing. Check the output above.${NC}"
    fi
fi

echo ""
echo -e "${BLUE}📊 Next steps:${NC}"
echo "1. The automated workflow runs every Tuesday at 8 AM UTC"
echo "2. When new versions are available and pass tests, a PR will be created automatically"
echo "3. You can manually trigger the workflow anytime with:"
echo "   gh workflow run ansible-version-auto-pr.yml --field force_check=true"
echo "4. To test a specific version:"
echo "   gh workflow run ansible-version-auto-pr.yml --field target_version=X.Y.Z"
echo ""

# Show current Ansible version info
if command -v ansible &> /dev/null; then
    echo -e "${BLUE}📋 Current Environment:${NC}"
    ansible --version | head -3
else
    echo -e "${YELLOW}⚠️  Ansible not found in current environment${NC}"
fi

echo ""
echo -e "${GREEN}✅ Check complete!${NC}"
