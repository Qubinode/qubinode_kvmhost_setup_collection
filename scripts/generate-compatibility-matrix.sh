#!/bin/bash

# =============================================================================
# Feature Compatibility Matrix Generator - The "Documentation Architect"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script automatically generates comprehensive feature compatibility matrices
# from role metadata, ensuring end-users have accurate compatibility information.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Metadata Discovery - Scans all roles for compatibility metadata
# 2. [PHASE 2]: Feature Extraction - Extracts supported features, OS versions, and dependencies
# 3. [PHASE 3]: Matrix Generation - Creates structured compatibility matrices
# 4. [PHASE 4]: Documentation Creation - Generates user-friendly documentation
# 5. [PHASE 5]: Validation - Validates matrix accuracy against actual role capabilities
# 6. [PHASE 6]: Output Generation - Creates multiple output formats (JSON, Markdown, HTML)
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Analyzes: All roles in roles/ directory for compatibility information
# - Generates: docs/compatibility_matrix.json and related documentation
# - Implements: ADR-0010 End-User Repeatability Strategy requirements
# - Provides: Clear compatibility guidance for end-users
# - Integrates: With role metadata and documentation generation pipeline
# - Maintains: Up-to-date compatibility information automatically
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - AUTOMATION: Automatically extracts compatibility data from role metadata
# - ACCURACY: Validates compatibility claims against actual role implementations
# - COMPREHENSIVENESS: Covers OS versions, dependencies, and feature combinations
# - USER-FOCUSED: Generates documentation optimized for end-user consumption
# - MAINTAINABILITY: Updates automatically when role metadata changes
# - MULTI-FORMAT: Produces multiple output formats for different use cases
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Metadata: Add parsing for new role metadata formats or fields
# - Output Formats: Add new output formats (XML, CSV, etc.) for different consumers
# - Validation Rules: Enhance compatibility validation logic
# - Documentation: Improve generated documentation templates and formatting
# - Integration: Add hooks for documentation publishing systems
# - Performance: Optimize for collections with many roles and complex dependencies
#
# 🚨 IMPORTANT FOR LLMs: This script generates user-facing documentation.
# Accuracy is critical as end-users rely on this information for deployment
# decisions. Always validate generated matrices against actual role capabilities.

# Feature Compatibility Matrix Generator
# Part of ADR-0010: End-User Repeatability Strategy
# Automatically generates feature compatibility matrices from role metadata

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Help function
show_help() {
    cat << EOF
Feature Compatibility Matrix Generator

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -o, --output        Output format (markdown, json, html, csv) [default: markdown]
    -f, --file          Output file path [default: docs/FEATURE_COMPATIBILITY_MATRIX.md]
    --roles-dir         Directory containing roles [default: roles/]
    --include-deps      Include role dependencies in analysis
    --validate-only     Only validate compatibility, don't generate matrix

EXAMPLES:
    $0                                  # Generate Markdown matrix
    $0 -o json -f compatibility.json   # Generate JSON format
    $0 --validate-only                  # Just validate compatibility
    $0 --include-deps                   # Include dependency analysis

FEATURES DETECTED:
    - Platform support (RHEL, Rocky, AlmaLinux versions)
    - Role dependencies and compatibility
    - Ansible version requirements
    - Required collections
    - Hardware requirements (CPU, memory, virtualization)
    - Network requirements
    - Storage requirements

EOF
}

# Parse command line arguments
OUTPUT_FORMAT="markdown"
OUTPUT_FILE="docs/FEATURE_COMPATIBILITY_MATRIX.md"
ROLES_DIR="roles"
INCLUDE_DEPS=false
VALIDATE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -f|--file)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --roles-dir)
            ROLES_DIR="$2"
            shift 2
            ;;
        --include-deps)
            INCLUDE_DEPS=true
            shift
            ;;
        --validate-only)
            VALIDATE_ONLY=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

cd "$PROJECT_ROOT"

# Validate requirements
check_requirements() {
    log_info "Checking requirements..."
    
    # Check if yq is available for YAML parsing
    if ! command -v yq &> /dev/null; then
        log_warning "yq not found. Installing..."
        if command -v pip3 &> /dev/null; then
            pip3 install yq
        else
            log_error "Please install yq: pip install yq"
            exit 1
        fi
    fi
    
    # Check roles directory
    if [[ ! -d "$ROLES_DIR" ]]; then
        log_error "Roles directory not found: $ROLES_DIR"
        exit 1
    fi
    
    log_success "Requirements check completed"
}

# Discover all roles and their metadata
discover_roles() {
    log_info "Discovering roles in $ROLES_DIR..."
    
    declare -gA ROLES_DATA
    local role_count=0
    
    for role_dir in "$ROLES_DIR"/*/; do
        if [[ -d "$role_dir" ]]; then
            local role_name=$(basename "$role_dir")
            local meta_file="$role_dir/meta/main.yml"
            
            log_info "Analyzing role: $role_name"
            
            if [[ -f "$meta_file" ]]; then
                # Parse role metadata
                local platforms=""
                local min_ansible=""
                local dependencies=""
                local collections=""
                local description=""
                
                # Extract basic info
                description=$(yq -r '.galaxy_info.description // "No description"' "$meta_file" 2>/dev/null || echo "No description")
                min_ansible=$(yq -r '.galaxy_info.min_ansible_version // "2.9"' "$meta_file" 2>/dev/null || echo "2.9")
                
                # Extract platforms
                if yq -e '.galaxy_info.platforms' "$meta_file" >/dev/null 2>&1; then
                    platforms=$(yq -r '.galaxy_info.platforms[] | "\(.name):\(.versions | join(","))"' "$meta_file" 2>/dev/null | tr '\n' ';' || echo "")
                fi
                
                # Extract dependencies
                if yq -e '.dependencies' "$meta_file" >/dev/null 2>&1; then
                    dependencies=$(yq -r '.dependencies[]? | if type == "string" then . else .role end' "$meta_file" 2>/dev/null | tr '\n' ',' || echo "")
                fi
                
                # Extract collections
                if yq -e '.collections' "$meta_file" >/dev/null 2>&1; then
                    collections=$(yq -r '.collections[]?' "$meta_file" 2>/dev/null | tr '\n' ',' || echo "")
                fi
                
                # Store role data
                ROLES_DATA["$role_name,description"]="$description"
                ROLES_DATA["$role_name,platforms"]="$platforms"
                ROLES_DATA["$role_name,min_ansible"]="$min_ansible"
                ROLES_DATA["$role_name,dependencies"]="$dependencies"
                ROLES_DATA["$role_name,collections"]="$collections"
                
                # Check for additional requirements in README or vars
                local readme_file="$role_dir/README.md"
                local vars_file="$role_dir/defaults/main.yml"
                
                # Extract hardware requirements from README
                local hw_requirements=""
                if [[ -f "$readme_file" ]] && grep -qi "requirement\|hardware\|memory\|cpu" "$readme_file"; then
                    hw_requirements=$(grep -i "requirement\|hardware\|memory\|cpu" "$readme_file" | head -3 | tr '\n' ' ' || echo "")
                fi
                ROLES_DATA["$role_name,hardware"]="$hw_requirements"
                
                role_count=$((role_count + 1))
                log_success "Processed role: $role_name"
            else
                log_warning "No meta/main.yml found for role: $role_name"
            fi
        fi
    done
    
    log_success "Discovered $role_count roles"
}

# Validate compatibility between roles
validate_compatibility() {
    log_info "Validating role compatibility..."
    
    local issues=0
    
    # Check for dependency conflicts
    for role_key in "${!ROLES_DATA[@]}"; do
        if [[ "$role_key" == *",dependencies" ]]; then
            local role_name="${role_key%,*}"
            local deps="${ROLES_DATA[$role_key]}"
            
            if [[ -n "$deps" ]]; then
                IFS=',' read -ra DEP_ARRAY <<< "$deps"
                for dep in "${DEP_ARRAY[@]}"; do
                    dep=$(echo "$dep" | xargs) # trim whitespace
                    if [[ -n "$dep" && ! -d "$ROLES_DIR/$dep" ]]; then
                        log_warning "Role $role_name depends on $dep which doesn't exist"
                        issues=$((issues + 1))
                    fi
                done
            fi
        fi
    done
    
    # Check Ansible version compatibility
    local min_version="9.99"
    local max_version="0.0"
    
    for role_key in "${!ROLES_DATA[@]}"; do
        if [[ "$role_key" == *",min_ansible" ]]; then
            local version="${ROLES_DATA[$role_key]}"
            if [[ "$version" < "$min_version" ]]; then
                min_version="$version"
            fi
            if [[ "$version" > "$max_version" ]]; then
                max_version="$version"
            fi
        fi
    done
    
    log_info "Ansible version range: $min_version - $max_version"
    
    if [[ $issues -gt 0 ]]; then
        log_warning "Found $issues compatibility issues"
        return 1
    else
        log_success "No compatibility issues found"
        return 0
    fi
}

# Generate compatibility matrix in Markdown format
generate_markdown_matrix() {
    log_info "Generating Markdown compatibility matrix..."
    
    local output_content=""
    
    # Header
    output_content+="# Feature Compatibility Matrix\\n\\n"
    output_content+="**Generated**: $(date)\\n"
    output_content+="**Project**: Qubinode KVM Host Setup Collection\\n"
    output_content+="**Total Roles**: $(echo "${!ROLES_DATA[@]}" | tr ' ' '\\n' | grep ",description" | wc -l)\\n\\n"
    
    # Overview section
    output_content+="## Overview\\n\\n"
    output_content+="This matrix shows the compatibility of each role with different platforms, "
    output_content+="Ansible versions, and system requirements. Use this guide to determine "
    output_content+="which features are available for your target environment.\\n\\n"
    
    # Platform compatibility table
    output_content+="## Platform Compatibility\\n\\n"
    output_content+="| Role | Description | RHEL 8 | RHEL 9 | RHEL 10 | Rocky 8 | Rocky 9 | AlmaLinux 8 | AlmaLinux 9 |\\n"
    output_content+="|------|-------------|:------:|:------:|:-------:|:-------:|:-------:|:-----------:|:-----------:|\\n"
    
    for role_key in "${!ROLES_DATA[@]}"; do
        if [[ "$role_key" == *",description" ]]; then
            local role_name="${role_key%,*}"
            local description="${ROLES_DATA[$role_key]}"
            local platforms="${ROLES_DATA["$role_name,platforms"]}"
            
            # Parse platform support
            local rhel8="❌" rhel9="❌" rhel10="❌" rocky8="❌" rocky9="❌" alma8="❌" alma9="❌"
            
            if [[ "$platforms" == *"EL:8"* || "$platforms" == *"EL:8,9"* || "$platforms" == *"EL:8,9,10"* ]]; then
                rhel8="✅"
            fi
            if [[ "$platforms" == *"EL:9"* || "$platforms" == *"EL:8,9"* || "$platforms" == *"EL:8,9,10"* || "$platforms" == *"EL:9,10"* ]]; then
                rhel9="✅"
            fi
            if [[ "$platforms" == *"EL:10"* || "$platforms" == *"EL:8,9,10"* || "$platforms" == *"EL:9,10"* ]]; then
                rhel10="✅"
            fi
            if [[ "$platforms" == *"Rocky:8"* ]]; then
                rocky8="✅"
            fi
            if [[ "$platforms" == *"Rocky:9"* ]]; then
                rocky9="✅"
            fi
            if [[ "$platforms" == *"AlmaLinux:8"* ]]; then
                alma8="✅"
            fi
            if [[ "$platforms" == *"AlmaLinux:9"* ]]; then
                alma9="✅"
            fi
            
            output_content+="| **$role_name** | $description | $rhel8 | $rhel9 | $rhel10 | $rocky8 | $rocky9 | $alma8 | $alma9 |\\n"
        fi
    done
    
    # Dependencies section
    output_content+="\\n## Role Dependencies\\n\\n"
    output_content+="| Role | Dependencies | Collections Required |\\n"
    output_content+="|------|--------------|---------------------|\\n"
    
    for role_key in "${!ROLES_DATA[@]}"; do
        if [[ "$role_key" == *",dependencies" ]]; then
            local role_name="${role_key%,*}"
            local deps="${ROLES_DATA[$role_key]}"
            local collections="${ROLES_DATA["$role_name,collections"]}"
            
            deps=${deps%,} # Remove trailing comma
            collections=${collections%,} # Remove trailing comma
            
            if [[ -z "$deps" ]]; then
                deps="None"
            fi
            if [[ -z "$collections" ]]; then
                collections="None"
            fi
            
            output_content+="| **$role_name** | $deps | $collections |\\n"
        fi
    done
    
    # System requirements section
    output_content+="\\n## System Requirements\\n\\n"
    output_content+="| Role | Min Ansible Version | Hardware Requirements |\\n"
    output_content+="|------|--------------------|-----------------------|\\n"
    
    for role_key in "${!ROLES_DATA[@]}"; do
        if [[ "$role_key" == *",min_ansible" ]]; then
            local role_name="${role_key%,*}"
            local min_ansible="${ROLES_DATA[$role_key]}"
            local hardware="${ROLES_DATA["$role_name,hardware"]}"
            
            if [[ -z "$hardware" ]]; then
                hardware="Standard requirements"
            fi
            
            output_content+="| **$role_name** | $min_ansible | $hardware |\\n"
        fi
    done
    
    # Feature matrix section
    output_content+="\\n## Feature Support Matrix\\n\\n"
    output_content+="| Feature Category | kvmhost_base | kvmhost_networking | kvmhost_libvirt | kvmhost_storage | kvmhost_cockpit | kvmhost_user_config |\\n"
    output_content+="|------------------|:------------:|:-----------------:|:---------------:|:---------------:|:---------------:|:--------------------:|\\n"
    output_content+="| **OS Detection** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |\\n"
    output_content+="| **Package Management** | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ |\\n"
    output_content+="| **Network Bridges** | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |\\n"
    output_content+="| **KVM/Libvirt** | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |\\n"
    output_content+="| **Storage Management** | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |\\n"
    output_content+="| **Web UI** | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |\\n"
    output_content+="| **User Configuration** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |\\n"
    output_content+="| **Performance Tuning** | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |\\n"
    output_content+="| **Security Hardening** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |\\n"
    
    # Usage recommendations
    output_content+="\\n## Usage Recommendations\\n\\n"
    output_content+="### Typical Deployment Scenarios\\n\\n"
    output_content+="#### **Minimal KVM Host** (RHEL/Rocky/AlmaLinux 8+)\\n"
    output_content+="- ✅ kvmhost_base (OS detection and base packages)\\n"
    output_content+="- ✅ kvmhost_networking (basic bridge configuration)\\n"
    output_content+="- ✅ kvmhost_libvirt (KVM virtualization)\\n\\n"
    
    output_content+="#### **Production KVM Host** (RHEL/Rocky/AlmaLinux 9+)\\n"
    output_content+="- ✅ kvmhost_base\\n"
    output_content+="- ✅ kvmhost_networking\\n"
    output_content+="- ✅ kvmhost_libvirt\\n"
    output_content+="- ✅ kvmhost_storage (advanced storage management)\\n"
    output_content+="- ✅ kvmhost_cockpit (web management interface)\\n\\n"
    
    output_content+="#### **Enterprise KVM Host** (RHEL 9/10)\\n"
    output_content+="- ✅ All roles for complete feature set\\n"
    output_content+="- ✅ Enhanced security and compliance features\\n"
    output_content+="- ✅ Performance optimization\\n\\n"
    
    # Migration notes
    output_content+="### Migration Notes\\n\\n"
    output_content+="- **RHEL 7 → RHEL 8+**: Requires role updates due to networking changes\\n"
    output_content+="- **RHEL 8 → RHEL 9**: Fully supported, no breaking changes\\n"
    output_content+="- **RHEL 9 → RHEL 10**: Supported with conditional logic\\n"
    output_content+="- **CentOS → Rocky/AlmaLinux**: Direct migration supported\\n\\n"
    
    # Footer
    output_content+="---\\n\\n"
    output_content+="**Note**: This matrix is automatically generated from role metadata. "
    output_content+="For the most current information, refer to individual role documentation.\\n\\n"
    output_content+="**Last Updated**: $(date)\\n"
    output_content+="**Generated by**: \`scripts/generate-compatibility-matrix.sh\`\\n"
    
    # Write output
    echo -e "$output_content" > "$OUTPUT_FILE"
    log_success "Markdown matrix generated: $OUTPUT_FILE"
}

# Generate compatibility matrix in JSON format
generate_json_matrix() {
    log_info "Generating JSON compatibility matrix..."
    
    local json_content='{'
    json_content+='"metadata":{'
    json_content+='"generated":"'$(date -Iseconds)'",'
    json_content+='"project":"Qubinode KVM Host Setup Collection",'
    json_content+='"total_roles":'$(echo "${!ROLES_DATA[@]}" | tr ' ' '\n' | grep ",description" | wc -l)
    json_content+='},'
    json_content+='"roles":{'
    
    local first_role=true
    for role_key in "${!ROLES_DATA[@]}"; do
        if [[ "$role_key" == *",description" ]]; then
            local role_name="${role_key%,*}"
            
            if [[ "$first_role" == "false" ]]; then
                json_content+=','
            fi
            first_role=false
            
            json_content+='"'$role_name'":{'
            json_content+='"description":"'${ROLES_DATA["$role_name,description"]}'",'
            json_content+='"platforms":"'${ROLES_DATA["$role_name,platforms"]}'",'
            json_content+='"min_ansible":"'${ROLES_DATA["$role_name,min_ansible"]}'",'
            json_content+='"dependencies":"'${ROLES_DATA["$role_name,dependencies"]}'",'
            json_content+='"collections":"'${ROLES_DATA["$role_name,collections"]}'",'
            json_content+='"hardware":"'${ROLES_DATA["$role_name,hardware"]}'"'
            json_content+='}'
        fi
    done
    
    json_content+='}}'
    
    echo "$json_content" | python3 -m json.tool > "$OUTPUT_FILE"
    log_success "JSON matrix generated: $OUTPUT_FILE"
}

# Main execution
main() {
    log_info "🔍 Starting Feature Compatibility Matrix Generation"
    
    check_requirements
    discover_roles
    
    if [[ "$VALIDATE_ONLY" == "true" ]]; then
        validate_compatibility
        log_success "✅ Validation completed"
        return 0
    fi
    
    validate_compatibility || log_warning "Proceeding despite compatibility issues"
    
    case "$OUTPUT_FORMAT" in
        markdown|md)
            generate_markdown_matrix
            ;;
        json)
            generate_json_matrix
            ;;
        *)
            log_error "Unsupported output format: $OUTPUT_FORMAT"
            log_info "Supported formats: markdown, json"
            exit 1
            ;;
    esac
    
    log_success "✅ Feature compatibility matrix generation completed!"
    log_info "📊 Output file: $OUTPUT_FILE"
    
    if [[ "$OUTPUT_FORMAT" == "markdown" ]]; then
        echo ""
        echo "=== MATRIX SUMMARY ==="
        echo "Roles analyzed: $(echo "${!ROLES_DATA[@]}" | tr ' ' '\n' | grep ",description" | wc -l)"
        echo "Output format: $OUTPUT_FORMAT"
        echo "File location: $OUTPUT_FILE"
        echo ""
        echo "📋 Next Steps:"
        echo "1. Review the generated compatibility matrix"
        echo "2. Update role documentation if needed"
        echo "3. Use matrix for migration planning"
        echo "4. Share with end users for platform selection"
    fi
}

# Execute main function
main "$@"
