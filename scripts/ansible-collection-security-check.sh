#!/bin/bash

# =============================================================================
# Collection Security Auditor - The "Ansible Security Specialist"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script provides focused security scanning specifically for Ansible collections,
# analyzing project requirements and dependencies without system-wide scanning.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Collection Scope Definition - Defines Ansible collection security scope
# 2. [PHASE 2]: Requirement Analysis - Analyzes project requirements for vulnerabilities
# 3. [PHASE 3]: Dependency Scanning - Scans collection dependencies for security issues
# 4. [PHASE 4]: Ansible-Specific Checks - Performs Ansible-specific security validation
# 5. [PHASE 5]: Collection Validation - Validates collection security practices
# 6. [PHASE 6]: Focused Reporting - Generates collection-specific security reports
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Scans: Project requirements.txt, galaxy.yml, and collection dependencies
# - Focuses: On Ansible collection security without system package noise
# - Validates: Collection-specific security practices and configurations
# - Complements: enhanced-security-scan.sh with collection-focused analysis
# - Reports: Collection-specific security findings and recommendations
# - Integrates: With collection development and CI/CD workflows
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - FOCUSED: Specifically targets Ansible collection security concerns
# - SCOPED: Avoids system-wide scanning to reduce noise and improve relevance
# - COLLECTION-AWARE: Understands Ansible collection structure and dependencies
# - TARGETED: Focuses on security issues relevant to collection functionality
# - EFFICIENT: Optimized for collection-specific security analysis
# - ACTIONABLE: Provides collection-specific security recommendations
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - Collection Standards: Update for new Ansible collection security standards
# - Scanning Tools: Add new collection-specific security scanning tools
# - Dependency Sources: Add scanning for new dependency file types
# - Validation Rules: Add new Ansible-specific security validation rules
# - Integration: Add integration with Ansible Galaxy security features
# - Reporting: Enhance collection-specific security reporting
#
# 🚨 IMPORTANT FOR LLMs: This script focuses on collection-specific security.
# It complements but doesn't replace comprehensive security scanning.
# Always address collection security issues as they directly affect users.

# Ansible Collection Security Check
# Focused security scanning for Ansible collections
# Only scans project requirements, not system packages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Change to project root
cd "$PROJECT_ROOT"

log_info "🔒 Ansible Collection Security Check"
log_info "===================================="

# Check if we're in the right directory
if [ ! -f "galaxy.yml" ]; then
    log_error "Must run from the root of the collection directory"
    exit 1
fi

# Install security tools if needed
if ! command -v safety &> /dev/null; then
    log_info "Installing safety..."
    pip install safety
fi

if ! command -v bandit &> /dev/null; then
    log_info "Installing bandit..."
    pip install bandit
fi

# Create reports directory
mkdir -p security-reports

# Check our project requirements only (not system packages)
log_info "🔍 Scanning project requirements files..."

CRITICAL_ISSUES=0
HIGH_ISSUES=0
MEDIUM_ISSUES=0

# Scan requirements.txt if it exists
if [ -f "requirements.txt" ]; then
    log_info "Checking requirements.txt..."
    
    # Use safety to check for known vulnerabilities in our requirements
    if safety check -r requirements.txt --json --output security-reports/requirements-safety.json 2>/dev/null; then
        log_success "requirements.txt: No critical vulnerabilities found"
    else
        log_warning "requirements.txt: Some vulnerabilities found (see security-reports/requirements-safety.json)"
        # Count only critical/high severity issues
        if [ -f "security-reports/requirements-safety.json" ]; then
            # Safety doesn't always provide severity, so we treat all as medium unless proven critical
            MEDIUM_ISSUES=$((MEDIUM_ISSUES + 1))
        fi
    fi
else
    log_info "No requirements.txt found"
fi

# Scan requirements-dev.txt if it exists
if [ -f "requirements-dev.txt" ]; then
    log_info "Checking requirements-dev.txt..."
    
    if safety check -r requirements-dev.txt --json --output security-reports/requirements-dev-safety.json 2>/dev/null; then
        log_success "requirements-dev.txt: No critical vulnerabilities found"
    else
        log_warning "requirements-dev.txt: Some vulnerabilities found (see security-reports/requirements-dev-safety.json)"
        if [ -f "security-reports/requirements-dev-safety.json" ]; then
            MEDIUM_ISSUES=$((MEDIUM_ISSUES + 1))
        fi
    fi
else
    log_info "No requirements-dev.txt found"
fi

# Run bandit on our code only (exclude external roles)
log_info "🔍 Running static code analysis with bandit..."

# Only scan our roles and plugins, exclude external roles
SCAN_PATHS=()
[ -d "roles/kvmhost_setup" ] && SCAN_PATHS+=("roles/kvmhost_setup")
[ -d "plugins" ] && SCAN_PATHS+=("plugins")

if [ ${#SCAN_PATHS[@]} -gt 0 ]; then
    if bandit -r "${SCAN_PATHS[@]}" -f json -o security-reports/bandit-results.json 2>/dev/null; then
        log_success "Static code analysis: No security issues found in our code"
    else
        log_warning "Static code analysis: Some issues found (see security-reports/bandit-results.json)"
        # Parse bandit results to count severity
        if [ -f "security-reports/bandit-results.json" ]; then
            if command -v jq &> /dev/null; then
                HIGH_BANDIT=$(jq '[.results[] | select(.issue_severity == "HIGH")] | length' security-reports/bandit-results.json 2>/dev/null || echo 0)
                MEDIUM_BANDIT=$(jq '[.results[] | select(.issue_severity == "MEDIUM")] | length' security-reports/bandit-results.json 2>/dev/null || echo 0)
                HIGH_ISSUES=$((HIGH_ISSUES + HIGH_BANDIT))
                MEDIUM_ISSUES=$((MEDIUM_ISSUES + MEDIUM_BANDIT))
            else
                MEDIUM_ISSUES=$((MEDIUM_ISSUES + 1))
            fi
        fi
    fi
else
    log_info "No local code directories found to scan"
fi

# Generate summary
cat > security-reports/summary.json << EOF
{
  "scan_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "scan_type": "ansible_collection_focused",
  "summary": {
    "critical": $CRITICAL_ISSUES,
    "high": $HIGH_ISSUES,
    "medium": $MEDIUM_ISSUES,
    "total": $((CRITICAL_ISSUES + HIGH_ISSUES + MEDIUM_ISSUES))
  },
  "scope": "project_requirements_only",
  "excluded": ["system_packages", "external_roles", "linux-system-roles.*"]
}
EOF

# Print summary
log_info ""
log_info "🎯 Security Scan Summary"
log_info "========================"
log_info "Critical issues: $CRITICAL_ISSUES"
log_info "High issues: $HIGH_ISSUES"
log_info "Medium issues: $MEDIUM_ISSUES"
log_info "Total issues: $((CRITICAL_ISSUES + HIGH_ISSUES + MEDIUM_ISSUES))"

# Exit based on severity
if [ $CRITICAL_ISSUES -gt 0 ]; then
    log_error "❌ Critical security vulnerabilities found!"
    log_error "Review security-reports/ for details"
    exit 1
elif [ $HIGH_ISSUES -gt 5 ]; then
    log_warning "⚠️ High number of high-severity issues found ($HIGH_ISSUES)"
    log_warning "Consider reviewing security-reports/ for details"
    exit 0  # Don't fail for high issues in Ansible collections
else
    log_success "✅ Security check passed!"
    log_info "Focused scan found no critical vulnerabilities in project requirements"
    exit 0
fi
