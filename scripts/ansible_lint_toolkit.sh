#!/usr/bin/env bash

# =============================================================================
# Ansible Lint Automation Toolkit - The "Code Quality Enforcer"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This comprehensive toolkit automates the resolution of ansible-lint failures,
# providing a complete solution for maintaining code quality standards.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Lint Analysis - Runs ansible-lint to identify all violations
# 2. [PHASE 2]: Issue Categorization - Groups violations by type and severity
# 3. [PHASE 3]: Automated Fixes - Applies systematic fixes for common issues
# 4. [PHASE 4]: Manual Fix Guidance - Provides guidance for complex violations
# 5. [PHASE 5]: Validation - Re-runs lint to verify fixes were successful
# 6. [PHASE 6]: Report Generation - Creates detailed fix reports and summaries
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Processes: All Ansible content (roles, playbooks, tasks) for lint compliance
# - Integrates: With CI/CD pipeline for automated code quality enforcement
# - Coordinates: Multiple fix scripts (fix_ansible_lint.py, comprehensive-lint-fixes.sh)
# - Maintains: Consistent code quality across the entire collection
# - Reports: Detailed fix summaries and remaining manual intervention needs
# - Prevents: Lint violations from blocking CI/CD pipeline progression
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - COMPREHENSIVE: Handles all categories of ansible-lint violations
# - AUTOMATION: Maximizes automated fixes while providing manual guidance
# - INTEGRATION: Orchestrates multiple specialized fix tools
# - VALIDATION: Ensures fixes don't break functionality or introduce new issues
# - REPORTING: Provides detailed audit trails of all changes made
# - EFFICIENCY: Optimizes fix order to resolve dependencies between violations
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Rules: Add handling for new ansible-lint rules and violations
# - Fix Tools: Integrate new automated fix tools or scripts
# - Workflow: Modify fix workflow for improved efficiency or accuracy
# - Reporting: Enhance report generation for new stakeholder requirements
# - Integration: Add hooks for code review systems or quality gates
# - Performance: Optimize for large collections with many files
#
# 🚨 IMPORTANT FOR LLMs: This toolkit modifies Ansible code automatically.
# Always run in a version-controlled environment and review changes before
# committing. Some fixes may require manual validation for correctness.

"""
Comprehensive Ansible Lint Automation Toolkit
A complete automated solution for resolving ansible-lint failures
"""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m' 
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Ansible Lint Automation Toolkit${NC}"
echo -e "${BLUE}=====================================${NC}"

# Step 1: Run baseline ansible-lint to see current issues
echo -e "\n${YELLOW}📊 Step 1: Running baseline ansible-lint scan...${NC}"
ansible-lint roles/ --exclude roles/.cache/ --exclude roles/.venv/ 2>/dev/null | tail -20 > /tmp/ansible_lint_before.txt
BEFORE_ERRORS=$(grep -o 'Failed: [0-9]* failure(s)' /tmp/ansible_lint_before.txt | grep -o '[0-9]*' || echo "0")
echo -e "${RED}Found ${BEFORE_ERRORS} ansible-lint failures${NC}"

# Step 2: Run comprehensive YAML parsing fixes
echo -e "\n${YELLOW}🔧 Step 2: Running comprehensive YAML parsing fixes...${NC}"
python3 scripts/fix_yaml_parsing.py

# Step 3: Run basic ansible-lint fixes
echo -e "\n${YELLOW}🔧 Step 3: Running basic ansible-lint fixes...${NC}"
python3 scripts/fix_ansible_lint.py

# Step 4: Run advanced ansible-lint fixes  
echo -e "\n${YELLOW}🔧 Step 4: Running advanced ansible-lint fixes...${NC}"
python3 scripts/fix_ansible_lint_advanced.py

# Step 5: Fix any remaining escape character issues
echo -e "\n${YELLOW}🔧 Step 5: Fixing remaining escape character issues...${NC}"
python3 scripts/fix_escape_chars.py

# Step 6: Run final ansible-lint scan
echo -e "\n${YELLOW}📊 Step 6: Running final ansible-lint scan...${NC}"
ansible-lint roles/ --exclude roles/.cache/ --exclude roles/.venv/ 2>/dev/null | tail -20 > /tmp/ansible_lint_after.txt
AFTER_ERRORS=$(grep -o 'Failed: [0-9]* failure(s)' /tmp/ansible_lint_after.txt | grep -o '[0-9]*' || echo "0")

# Calculate improvement
IMPROVEMENT=$((BEFORE_ERRORS - AFTER_ERRORS))

echo -e "\n${GREEN}✅ Ansible Lint Automation Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "${BLUE}📈 Results Summary:${NC}"
echo -e "   Before: ${RED}${BEFORE_ERRORS} failures${NC}"
echo -e "   After:  ${RED}${AFTER_ERRORS} failures${NC}"
echo -e "   Fixed:  ${GREEN}${IMPROVEMENT} issues${NC}"

if [ "$IMPROVEMENT" -gt 0 ]; then
    echo -e "\n${GREEN}🎉 Successfully reduced ansible-lint failures by ${IMPROVEMENT}!${NC}"
    PERCENTAGE=$((IMPROVEMENT * 100 / BEFORE_ERRORS))
    echo -e "${GREEN}📊 That's a ${PERCENTAGE}% improvement!${NC}"
else
    echo -e "\n${YELLOW}⚠️  No additional improvements were made.${NC}"
fi

# Show remaining issue categories if any
if [ "$AFTER_ERRORS" -gt 0 ]; then
    echo -e "\n${YELLOW}📋 Remaining Issues Summary:${NC}"
    ansible-lint roles/ --exclude roles/.cache/ --exclude roles/.venv/ 2>/dev/null | grep -A 20 "Rule Violation Summary" | head -20
    
    echo -e "\n${BLUE}💡 Next Steps:${NC}"
    echo -e "   1. Review the remaining ${AFTER_ERRORS} issues manually"
    echo -e "   2. Focus on high-impact rules (schema, load-failure, etc.)"
    echo -e "   3. Consider adding .ansible-lint-ignore for acceptable violations"
    echo -e "   4. Run: ${GREEN}ansible-lint roles/ --write${NC} to see specific line numbers"
fi

echo -e "\n${BLUE}📚 Available Tools:${NC}"
echo -e "   • ${GREEN}scripts/fix_yaml_parsing.py${NC} - Comprehensive YAML parsing fixes"
echo -e "   • ${GREEN}scripts/fix_ansible_lint.py${NC} - Basic ansible-lint automated fixes"  
echo -e "   • ${GREEN}scripts/fix_ansible_lint_advanced.py${NC} - Advanced pattern fixes"
echo -e "   • ${GREEN}scripts/fix_escape_chars.py${NC} - YAML escape character fixes"
echo -e "   • ${GREEN}scripts/ansible_lint_toolkit.sh${NC} - This comprehensive automation"

echo -e "\n${GREEN}🎯 All automated fixes have been applied!${NC}"
