#!/usr/bin/env bash
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
