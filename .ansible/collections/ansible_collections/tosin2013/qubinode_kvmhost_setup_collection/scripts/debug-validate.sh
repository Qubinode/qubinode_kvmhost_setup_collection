#!/bin/bash
# Debug version of file structure validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Validation result counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Function to log validation results
log_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

log_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

log_info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
}

log_header() {
    echo -e "\n${PURPLE}=== $1 ===${NC}"
}

# Function to validate directory structure
validate_directory() {
    local dir_path="$1"
    local description="$2"
    local required="${3:-true}"
    
    if [[ -d "$PROJECT_ROOT/$dir_path" ]]; then
        log_pass "$description exists at $dir_path"
        return 0
    else
        if [[ "$required" == "true" ]]; then
            log_fail "$description missing at $dir_path"
        else
            log_warning "$description not found at $dir_path (optional)"
        fi
        return 1
    fi
}

# Function to validate file exists
validate_file() {
    local file_path="$1"
    local description="$2"
    local required="${3:-true}"
    
    if [[ -f "$PROJECT_ROOT/$file_path" ]]; then
        log_pass "$description exists at $file_path"
        return 0
    else
        if [[ "$required" == "true" ]]; then
            log_fail "$description missing at $file_path"
        else
            log_warning "$description not found at $file_path (optional)"
        fi
        return 1
    fi
}

echo -e "${BLUE}🔍 Debug File Structure Validation Tool${NC}"
echo -e "${BLUE}=======================================${NC}"
echo "Project root: $PROJECT_ROOT"
echo ""

# Test basic structure
log_header "Core Project Structure"
validate_file "galaxy.yml" "Ansible Galaxy collection metadata"
validate_file "ansible.cfg" "Ansible configuration"

# Test one role
log_header "Role Structure Validation (One Role Test)"
log_info "Testing role: edge_hosts_validate"
validate_directory "roles/edge_hosts_validate" "Role edge_hosts_validate directory"
validate_directory "roles/edge_hosts_validate/tasks" "Role edge_hosts_validate tasks directory"
validate_file "roles/edge_hosts_validate/tasks/main.yml" "Role edge_hosts_validate main tasks file"

echo ""
echo -e "${PURPLE}=== Summary ===${NC}"
echo -e "${GREEN}✅ Passed: $PASSED_CHECKS${NC}"
echo -e "${YELLOW}⚠️  Warnings: $WARNING_CHECKS${NC}"
echo -e "${RED}❌ Failed: $FAILED_CHECKS${NC}"
echo -e "${BLUE}📊 Total checks: $TOTAL_CHECKS${NC}"

if [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 Debug validation completed successfully!${NC}"
    exit 0
else
    echo -e "\n${RED}🚨 $FAILED_CHECKS validation(s) failed!${NC}"
    exit 1
fi
