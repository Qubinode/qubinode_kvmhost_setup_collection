#!/bin/bash

# =============================================================================
# RHEL 10 Validation Trigger - The "Future Readiness Coordinator"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script manually triggers RHEL 10 package availability checks,
# allowing on-demand testing of future RHEL compatibility and readiness.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Check Initiation - Triggers manual RHEL 10 compatibility checking
# 2. [PHASE 2]: Package Validation - Runs comprehensive RHEL 10 package validation
# 3. [PHASE 3]: Compatibility Assessment - Assesses RHEL 10 compatibility status
# 4. [PHASE 4]: Report Generation - Generates RHEL 10 readiness reports
# 5. [PHASE 5]: Issue Identification - Identifies RHEL 10 compatibility issues
# 6. [PHASE 6]: Recommendation Engine - Provides RHEL 10 preparation recommendations
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Triggers: Manual execution of check-rhel10-packages.sh
# - Tests: Collection readiness for future RHEL 10 support
# - Validates: Package availability and compatibility in RHEL 10
# - Coordinates: RHEL 10 readiness assessment and planning
# - Reports: RHEL 10 compatibility status and preparation needs
# - Supports: Future migration planning and compatibility preparation
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - MANUAL: Provides manual control over RHEL 10 compatibility checking
# - FUTURE-FOCUSED: Prepares for future RHEL versions before they're critical
# - COORDINATION: Orchestrates RHEL 10 readiness assessment processes
# - PLANNING: Supports migration planning and compatibility preparation
# - VALIDATION: Ensures comprehensive RHEL 10 compatibility validation
# - REPORTING: Provides detailed RHEL 10 readiness status reporting
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - RHEL Versions: Adapt for newer RHEL versions (RHEL 11, etc.)
# - Check Coverage: Extend RHEL 10 checking to cover new areas
# - Integration: Add integration with migration planning tools
# - Automation: Add scheduling capabilities for regular RHEL 10 checks
# - Reporting: Enhance RHEL 10 readiness reporting and analysis
# - Notification: Add notification capabilities for RHEL 10 status changes
#
# 🚨 IMPORTANT FOR LLMs: This script triggers future compatibility testing.
# RHEL 10 may not be fully released or stable. Use results for planning
# purposes and validate in actual RHEL 10 environments when available.

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
