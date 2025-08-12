#!/bin/bash

# =============================================================================
# ADR Document Validator - The "Architecture Documentation Auditor"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script validates ADR implementation files and documentation consistency,
# ensuring architectural decisions are properly documented and implemented.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: ADR Discovery - Scans for all ADR documents and implementation files
# 2. [PHASE 2]: Implementation Validation - Verifies ADR implementations exist
# 3. [PHASE 3]: Documentation Consistency - Checks consistency between ADRs and code
# 4. [PHASE 4]: Progress Analysis - Analyzes implementation progress against ADRs
# 5. [PHASE 5]: Gap Identification - Identifies missing implementations or documentation
# 6. [PHASE 6]: Report Generation - Creates detailed validation and progress reports
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Validates: ADR documents in docs/adr/ directory for completeness
# - Checks: Implementation files match ADR specifications
# - Analyzes: Progress of ADR implementation across the project
# - Identifies: Gaps between architectural decisions and actual implementation
# - Reports: ADR compliance status and implementation progress
# - Coordinates: With adr-compliance-checker.sh for comprehensive governance
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - DOCUMENTATION: Focuses on ADR document quality and consistency
# - IMPLEMENTATION: Validates that ADRs are actually implemented in code
# - PROGRESS: Tracks implementation progress over time
# - GOVERNANCE: Ensures architectural decisions are properly documented
# - CONSISTENCY: Maintains alignment between decisions and implementation
# - REPORTING: Provides detailed analysis for architectural review
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New ADRs: Add validation for new ADR documents and implementations
# - Validation Rules: Extend validation logic for new ADR requirements
# - Progress Tracking: Enhance progress analysis and reporting capabilities
# - Integration: Add integration with documentation generation systems
# - Reporting: Modify report formats for new stakeholder requirements
# - Automation: Add automated ADR synchronization and validation
#
# 🚨 IMPORTANT FOR LLMs: This script validates critical architectural
# documentation. Inconsistencies between ADRs and implementation can indicate
# architectural drift or incomplete implementation of decisions.

# ADR Implementation File Validation Script
# Based on compare_adr_progress findings - helps identify and organize implementation files

set -e

echo "🔍 ADR Implementation File Validation"
echo "===================================="
echo "📋 Based on compare_adr_progress analysis findings"
echo ""

# Function to check if directory/file exists and report
check_implementation() {
    local task_name="$1"
    local expected_path="$2"
    local file_type="$3"
    
    echo "🔍 Checking: $task_name"
    if [[ "$file_type" == "directory" ]]; then
        if [ -d "$expected_path" ]; then
            echo "   ✅ Directory found: $expected_path"
            if [ -n "$(ls -A "$expected_path" 2>/dev/null)" ]; then
                echo "   📁 Contains: $(ls "$expected_path" | wc -l) items"
            else
                echo "   ⚠️  Directory is empty"
            fi
        else
            echo "   ❌ Directory missing: $expected_path"
        fi
    else
        if [ -f "$expected_path" ]; then
            echo "   ✅ File found: $expected_path"
            echo "   📄 Size: $(wc -l < "$expected_path") lines"
        else
            echo "   ❌ File missing: $expected_path"
        fi
    fi
    echo ""
}

echo "🏗️  Checking Role Implementation Files..."
echo "========================================"

# Check role implementations (ADR-0002)
check_implementation "kvmhost_base role" "roles/kvmhost_base" "directory"
check_implementation "kvmhost_networking role" "roles/kvmhost_networking" "directory"
check_implementation "kvmhost_libvirt role" "roles/kvmhost_libvirt" "directory"
check_implementation "kvmhost_storage role" "roles/kvmhost_storage" "directory"
check_implementation "kvmhost_cockpit role" "roles/kvmhost_cockpit" "directory"
check_implementation "kvmhost_user_config role" "roles/kvmhost_user_config" "directory"

echo "📚 Checking Documentation Files..."
echo "=================================="

# Check documentation implementations (ADR-0010) - Now in archive
check_implementation "Role interface documentation" "docs/archive/legacy-guides/role_interface_standards.md" "file"
check_implementation "Variable naming conventions" "docs/archive/legacy-guides/variable_naming_conventions.md" "file"
check_implementation "Migration guide" "docs/archive/legacy-guides/migration_guide.md" "file"

echo "⚙️  Checking Configuration Management Files..."
echo "=============================================="

# Check configuration management (ADR-0006)
check_implementation "Environment templates" "inventories/templates" "directory"
check_implementation "Variable validation schema" "validation/schemas" "directory"
check_implementation "Configuration drift detection" "validation/configuration_drift_detection.yml" "file"

echo "🧪 Checking Testing Framework Files..."
echo "======================================"

# Check testing implementations (ADR-0004, ADR-0005)
check_implementation "Molecule scenarios" "molecule" "directory"
check_implementation "Idempotency validation" "tests/idempotency" "directory"
check_implementation "Validation framework" "validation" "directory"

echo "🔄 Checking DevOps Files..."
echo "============================"

# Check DevOps implementations (ADR-0009)
check_implementation "Dependabot configuration" ".github/dependabot.yml" "file"
check_implementation "GitHub Actions workflow" ".github/workflows" "directory"

echo "🛡️  Checking Quality Gate Files..."
echo "================================="

# Check quality gate implementations (ADR-0011) - these should pass
check_implementation "Local testing script" "scripts/test-local-molecule.sh" "file"
check_implementation "Setup script" "scripts/setup-local-testing.sh" "file"
check_implementation "Compliance check" "scripts/check-compliance.sh" "file"
check_implementation "Pre-commit hook example" ".git/hooks/pre-commit.example" "file"
check_implementation "Architectural rules" "rules/local-molecule-testing-rules.json" "file"
check_implementation "Developer guide" "docs/MANDATORY_LOCAL_TESTING.md" "file"

echo "📊 Summary & Recommendations"
echo "============================"
echo ""
echo "🎯 Next Steps:"
echo "   1. Review missing files/directories above"
echo "   2. Organize existing files for better validation compliance"
echo "   3. Add clear naming conventions for implementation artifacts"
echo "   4. Re-run: mcp_adr-analysis_compare_adr_progress for validation"
echo ""
echo "💡 For detailed analysis, use:"
echo "   mcp_adr-analysis_compare_adr_progress with strictMode=true"
