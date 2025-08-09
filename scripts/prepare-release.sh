#!/bin/bash

# =============================================================================
# Release Preparation Manager - The "Release Orchestrator"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script prepares and validates releases for Ansible Galaxy deployment,
# ensuring all requirements are met before triggering the release pipeline.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Release Validation - Validates current state is ready for release
# 2. [PHASE 2]: Version Management - Handles version calculation and updates
# 3. [PHASE 3]: Pre-Release Testing - Runs comprehensive validation suite
# 4. [PHASE 4]: Release Preparation - Prepares all release artifacts
# 5. [PHASE 5]: Deployment Options - Provides automated and manual deployment options
# 6. [PHASE 6]: Post-Release Validation - Validates successful release deployment
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Prepares: Releases for Ansible Galaxy deployment
# - Validates: All pre-release requirements and quality checks
# - Coordinates: With GitHub Actions workflows for automated deployment
# - Manages: Version consistency across galaxy.yml and Makefile
# - Ensures: Release quality and compliance before deployment
# - Provides: Both automated and manual release preparation options
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - VALIDATION: Comprehensive pre-release validation before any deployment
# - CONSISTENCY: Ensures version consistency across all project files
# - FLEXIBILITY: Supports both automated and manual release workflows
# - SAFETY: Includes dry-run mode and comprehensive error checking
# - INTEGRATION: Seamlessly integrates with GitHub Actions workflows
# - QUALITY: Enforces quality gates before allowing releases
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Validation: Add new pre-release validation checks
# - Version Files: Add new files that need version updates
# - Quality Gates: Add new quality assurance requirements
# - Integration: Add integration with new release management tools
# - Automation: Enhance automation capabilities for release preparation
# - Reporting: Add release preparation reporting and metrics
#
# 🚨 IMPORTANT FOR LLMs: This script prepares critical releases that affect
# the entire user community. Always ensure validation passes before proceeding.
# Failed releases can disrupt user installations and damage project reputation.

set -euo pipefail

# 📊 GLOBAL VARIABLES (shared with other scripts):
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GALAXY_FILE="$PROJECT_ROOT/galaxy.yml"
MAKEFILE="$PROJECT_ROOT/Makefile"

# 🔧 CONFIGURATION CONSTANTS FOR LLMs:
PYTHON_VERSION="3.11"  # Target Python version for release validation
MIN_ANSIBLE_VERSION="2.17"  # Minimum Ansible version for compatibility

# Display usage information
show_usage() {
    cat << EOF
🚀 Release Preparation Manager

Usage: $0 [OPTIONS] <version>

OPTIONS:
    -t, --type TYPE     Release type: patch, minor, major (default: auto-detect)
    -d, --dry-run      Validate and prepare but don't create release
    -s, --skip-tests   Skip comprehensive testing (use with caution)
    -h, --help         Show this help message

EXAMPLES:
    $0 0.10.0                    # Prepare release 0.10.0 (auto-detect type)
    $0 --type minor 0.10.0       # Prepare minor release 0.10.0
    $0 --dry-run 0.10.0          # Validate release readiness without creating
    $0 --skip-tests 0.10.1       # Emergency release without full testing

AUTOMATED WORKFLOWS:
    • Dependency updates trigger automatic patch releases
    • Manual releases can be triggered via GitHub Actions
    • This script prepares releases for both automated and manual workflows

EOF
}

# Validate version format
validate_version() {
    local version="$1"
    
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "❌ Invalid version format: $version"
        echo "Expected format: X.Y.Z (e.g., 1.0.0)"
        return 1
    fi
    
    echo "✅ Version format valid: $version"
    return 0
}

# Get current version from galaxy.yml
get_current_version() {
    if [[ ! -f "$GALAXY_FILE" ]]; then
        echo "❌ galaxy.yml not found at $GALAXY_FILE"
        return 1
    fi
    
    local current_version
    current_version=$(grep "version:" "$GALAXY_FILE" | sed 's/version: *"\([^"]*\)".*/\1/')
    
    if [[ -z "$current_version" ]]; then
        echo "❌ Could not extract version from galaxy.yml"
        return 1
    fi
    
    echo "$current_version"
}

# Determine release type based on version comparison
determine_release_type() {
    local current="$1"
    local new="$2"
    
    IFS='.' read -r curr_major curr_minor curr_patch <<< "$current"
    IFS='.' read -r new_major new_minor new_patch <<< "$new"
    
    if [[ $new_major -gt $curr_major ]]; then
        echo "major"
    elif [[ $new_minor -gt $curr_minor ]]; then
        echo "minor"
    elif [[ $new_patch -gt $curr_patch ]]; then
        echo "patch"
    else
        echo "invalid"
    fi
}

# Run pre-release validation
run_validation() {
    local skip_tests="$1"
    
    echo "🧪 Running pre-release validation..."
    
    # Check if we're in the right directory
    if [[ ! -f "$GALAXY_FILE" ]]; then
        echo "❌ Not in project root directory"
        return 1
    fi
    
    # Run compliance checks
    if [[ -f "$SCRIPT_DIR/check-compliance.sh" ]]; then
        echo "📋 Running compliance checks..."
        bash "$SCRIPT_DIR/check-compliance.sh" || {
            echo "❌ Compliance checks failed"
            return 1
        }
    fi
    
    # Run security scan
    if [[ -f "$SCRIPT_DIR/enhanced-security-scan.sh" ]]; then
        echo "🛡️ Running security scan..."
        bash "$SCRIPT_DIR/enhanced-security-scan.sh" || {
            echo "❌ Security scan failed"
            return 1
        }
    fi
    
    # Validate file structure
    if [[ -f "$SCRIPT_DIR/validate-file-structure.sh" ]]; then
        echo "📁 Validating file structure..."
        bash "$SCRIPT_DIR/validate-file-structure.sh" || {
            echo "❌ File structure validation failed"
            return 1
        }
    fi
    
    # Test collection build
    echo "🔨 Testing collection build..."
    cd "$PROJECT_ROOT"
    ansible-galaxy collection build . --force || {
        echo "❌ Collection build failed"
        return 1
    }
    
    # Run comprehensive tests if not skipped
    if [[ "$skip_tests" != "true" ]]; then
        if [[ -f "$SCRIPT_DIR/test-local-molecule.sh" ]]; then
            echo "🧪 Running comprehensive tests..."
            bash "$SCRIPT_DIR/test-local-molecule.sh" || {
                echo "❌ Comprehensive tests failed"
                return 1
            }
        fi
    fi
    
    echo "✅ All validation checks passed"
    return 0
}

# Prepare release
prepare_release() {
    local version="$1"
    local release_type="$2"
    local dry_run="$3"
    
    echo "📝 Preparing release $version ($release_type)..."
    
    if [[ "$dry_run" == "true" ]]; then
        echo "🧪 DRY RUN MODE - No changes will be made"
        echo "Would update:"
        echo "  - galaxy.yml version to: $version"
        echo "  - Makefile TAG to: $version"
        echo "  - Create git tag: v$version"
        return 0
    fi
    
    # Update galaxy.yml
    echo "📝 Updating galaxy.yml version to $version..."
    sed -i "s/version: \"[^\"]*\"/version: \"$version\"/" "$GALAXY_FILE"
    
    # Update Makefile
    echo "📝 Updating Makefile TAG to $version..."
    sed -i "s/TAG=[0-9.]*/TAG=$version/" "$MAKEFILE"
    
    # Show changes
    echo "📊 Version changes made:"
    echo "  galaxy.yml: $(grep "version:" "$GALAXY_FILE")"
    echo "  Makefile: $(grep "TAG=" "$MAKEFILE")"
    
    echo "✅ Release preparation completed"
    echo ""
    echo "🚀 Next steps:"
    echo "1. Review changes: git diff"
    echo "2. Commit changes: git add galaxy.yml Makefile && git commit -m 'chore: bump version to $version'"
    echo "3. Create release tag: git tag -a v$version -m 'Release $version'"
    echo "4. Push changes: git push origin main && git push origin v$version"
    echo ""
    echo "Or use GitHub Actions Manual Release Trigger for automated deployment."
}

# Main function
main() {
    local version=""
    local release_type=""
    local dry_run="false"
    local skip_tests="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                release_type="$2"
                shift 2
                ;;
            -d|--dry-run)
                dry_run="true"
                shift
                ;;
            -s|--skip-tests)
                skip_tests="true"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                echo "❌ Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                version="$1"
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$version" ]]; then
        echo "❌ Version is required"
        show_usage
        exit 1
    fi
    
    # Validate version format
    validate_version "$version" || exit 1
    
    # Get current version
    local current_version
    current_version=$(get_current_version) || exit 1
    echo "📊 Current version: $current_version"
    echo "📊 Target version: $version"
    
    # Determine release type if not specified
    if [[ -z "$release_type" ]]; then
        release_type=$(determine_release_type "$current_version" "$version")
        if [[ "$release_type" == "invalid" ]]; then
            echo "❌ New version $version is not greater than current version $current_version"
            exit 1
        fi
        echo "🎯 Auto-detected release type: $release_type"
    fi
    
    # Run validation
    echo "🧪 Starting pre-release validation..."
    run_validation "$skip_tests" || {
        echo "❌ Pre-release validation failed"
        echo "Fix issues and try again, or use --skip-tests for emergency releases"
        exit 1
    }
    
    # Prepare release
    prepare_release "$version" "$release_type" "$dry_run"
    
    echo "🎉 Release preparation completed successfully!"
}

# Execute main function with all arguments
main "$@"
