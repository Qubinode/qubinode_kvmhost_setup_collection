#!/bin/bash
# Manual trigger for RHEL 10 package availability check
# This script can be used to manually test the monitoring system

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Manual RHEL 10 Package Check Trigger${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
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

echo -e "${GREEN}✅ Running local package availability check...${NC}"
./scripts/check-rhel10-packages.sh

# Check the exit code
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 Packages are available! This would trigger a PR in the automated workflow.${NC}"
    
    if [ "$LOCAL_ONLY" = false ]; then
        echo ""
        read -p "Would you like to trigger the GitHub Actions workflow manually? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}🔄 Triggering GitHub Actions workflow...${NC}"
            gh workflow run rhel10-auto-pr.yml --field force_check=true
            echo -e "${GREEN}✅ Workflow triggered! Check the Actions tab for progress.${NC}"
        fi
    fi
else
    echo ""
    echo -e "${YELLOW}⏳ Packages not yet available. Monitoring will continue automatically.${NC}"
fi

echo ""
echo -e "${BLUE}📊 Next steps:${NC}"
echo "1. The automated workflow runs every Monday at 6 AM UTC"
echo "2. When packages are available, a PR will be created automatically"
echo "3. You can manually trigger the workflow anytime with:"
echo "   gh workflow run rhel10-auto-pr.yml --field force_check=true"
echo ""
echo -e "${GREEN}✅ Check complete!${NC}"
