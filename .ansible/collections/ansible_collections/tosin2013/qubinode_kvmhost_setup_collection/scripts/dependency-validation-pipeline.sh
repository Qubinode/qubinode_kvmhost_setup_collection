#!/bin/bash
# Dependency Update Validation Pipeline
# Validates dependency updates before merging
# Part of DevOps & Automation Tasks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
VALIDATION_MODE="${1:-full}"  # full, quick, security-only
TEMP_DIR="$PROJECT_ROOT/.dependency-validation"
REPORT_DIR="$PROJECT_ROOT/dependency-validation-reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Validation counters
VALIDATION_STEPS=0
PASSED_STEPS=0
FAILED_STEPS=0
WARNING_STEPS=0

# Function to log validation results
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    ((PASSED_STEPS++))
    ((VALIDATION_STEPS++))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    ((WARNING_STEPS++))
    ((VALIDATION_STEPS++))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((FAILED_STEPS++))
    ((VALIDATION_STEPS++))
}

log_critical() {
    echo -e "${RED}[CRITICAL]${NC} $1"
    ((FAILED_STEPS++))
    ((VALIDATION_STEPS++))
}

# Function to setup validation environment
setup_validation_environment() {
    log_info "Setting up validation environment"
    
    # Create temporary directories
    mkdir -p "$TEMP_DIR"
    mkdir -p "$REPORT_DIR"
    
    # Create isolated Python environment for testing
    if [[ ! -d "$TEMP_DIR/venv" ]]; then
        python3 -m venv "$TEMP_DIR/venv"
    fi
    
    source "$TEMP_DIR/venv/bin/activate"
    pip install --upgrade pip wheel setuptools
    
    log_success "Validation environment ready"
}

# Function to validate Python dependencies
validate_python_dependencies() {
    log_info "Validating Python dependencies"
    
    source "$TEMP_DIR/venv/bin/activate"
    
    # Check if requirements files exist
    local requirements_files=()
    if [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
        requirements_files+=("requirements.txt")
    fi
    if [[ -f "$PROJECT_ROOT/requirements-dev.txt" ]]; then
        requirements_files+=("requirements-dev.txt")
    fi
    if [[ -f "$PROJECT_ROOT/molecule/requirements.txt" ]]; then
        requirements_files+=("molecule/requirements.txt")
    fi
    
    if [[ ${#requirements_files[@]} -eq 0 ]]; then
        log_warning "No requirements.txt files found"
        return 0
    fi
    
    # Test installation of each requirements file
    for req_file in "${requirements_files[@]}"; do
        log_info "Testing installation of $req_file"
        
        if pip install -r "$PROJECT_ROOT/$req_file" --dry-run >/dev/null 2>&1; then
            log_success "Dependencies in $req_file are installable"
        else
            log_error "Dependencies in $req_file have installation issues"
            # Try to get more details
            pip install -r "$PROJECT_ROOT/$req_file" --dry-run 2>&1 | head -20
        fi
    done
    
    # Test core dependencies specifically
    log_info "Testing core Ansible and Molecule dependencies"
    
    # Test Ansible installation
    if pip install "ansible-core>=2.17,<2.19" --dry-run >/dev/null 2>&1; then
        log_success "Ansible core dependencies are compatible"
    else
        log_error "Ansible core dependency conflicts detected"
    fi
    
    # Test Molecule installation
    if pip install "molecule[podman]>=25.0" --dry-run >/dev/null 2>&1; then
        log_success "Molecule dependencies are compatible"
    else
        log_error "Molecule dependency conflicts detected"
    fi
}

# Function to validate Ansible Galaxy dependencies
validate_ansible_dependencies() {
    log_info "Validating Ansible Galaxy dependencies"
    
    source "$TEMP_DIR/venv/bin/activate"
    
    # Install ansible-core for galaxy operations
    pip install ansible-core
    
    # Check galaxy.yml
    if [[ -f "$PROJECT_ROOT/galaxy.yml" ]]; then
        log_info "Validating galaxy.yml dependencies"
        
        # Test collection build
        cd "$PROJECT_ROOT"
        if ansible-galaxy collection build --force >/dev/null 2>&1; then
            log_success "Collection builds successfully"
        else
            log_error "Collection build failed"
            ansible-galaxy collection build --force 2>&1 | head -10
        fi
        
        # Test dependency installation (if any)
        if grep -q "dependencies:" "$PROJECT_ROOT/galaxy.yml"; then
            if ansible-galaxy collection install -r galaxy.yml --force >/dev/null 2>&1; then
                log_success "Galaxy dependencies install successfully"
            else
                log_error "Galaxy dependency installation failed"
            fi
        else
            log_info "No galaxy dependencies to validate"
        fi
    else
        log_warning "No galaxy.yml found"
    fi
}

# Function to validate container dependencies
validate_container_dependencies() {
    log_info "Validating container dependencies"
    
    # Check if podman is available
    if ! command -v podman &> /dev/null; then
        log_warning "Podman not available - skipping container validation"
        return 0
    fi
    
    # Extract container images from molecule configurations
    local container_images=()
    
    if [[ -d "$PROJECT_ROOT/molecule" ]]; then
        for scenario_dir in "$PROJECT_ROOT/molecule"/*; do
            if [[ -f "$scenario_dir/molecule.yml" ]]; then
                # Extract image names from molecule.yml
                local images=$(grep -E "^\s*image:" "$scenario_dir/molecule.yml" | sed 's/.*image:\s*//' | tr -d '"' || true)
                while IFS= read -r image; do
                    if [[ -n "$image" ]]; then
                        container_images+=("$image")
                    fi
                done <<< "$images"
            fi
        done
    fi
    
    # Remove duplicates
    readarray -t unique_images < <(printf '%s\n' "${container_images[@]}" | sort -u)
    
    if [[ ${#unique_images[@]} -eq 0 ]]; then
        log_warning "No container images found in molecule configurations"
        return 0
    fi
    
    # Test each container image
    for image in "${unique_images[@]}"; do
        log_info "Testing container image: $image"
        
        # Try to pull the image
        if podman pull "$image" >/dev/null 2>&1; then
            log_success "Container image $image is accessible"
        else
            log_error "Container image $image cannot be pulled"
        fi
    done
}

# Function to run security validation
validate_security() {
    log_info "Running security validation"
    
    source "$TEMP_DIR/venv/bin/activate"
    
    # Install security tools
    pip install safety bandit semgrep 2>/dev/null || log_warning "Could not install all security tools"
    
    # Run safety check on Python dependencies
    if command -v safety &> /dev/null; then
        log_info "Running safety check on Python dependencies"
        
        # Create a temporary requirements file with current dependencies
        pip freeze > "$TEMP_DIR/current-requirements.txt"
        
        if safety check -r "$TEMP_DIR/current-requirements.txt" --json > "$TEMP_DIR/safety-report.json" 2>/dev/null; then
            log_success "No known security vulnerabilities found in Python dependencies"
        else
            local vuln_count=$(jq length "$TEMP_DIR/safety-report.json" 2>/dev/null || echo "unknown")
            if [[ "$vuln_count" == "0" ]]; then
                log_success "No known security vulnerabilities found in Python dependencies"
            else
                log_error "Found $vuln_count security vulnerabilities in Python dependencies"
                # Show first few vulnerabilities
                jq -r '.[0:3][] | "- \(.package_name): \(.vulnerability)"' "$TEMP_DIR/safety-report.json" 2>/dev/null || true
            fi
        fi
    else
        log_warning "Safety tool not available - skipping Python security check"
    fi
    
    # Run enhanced dependency scanner if available
    if [[ -f "$PROJECT_ROOT/scripts/enhanced-dependency-scanner.sh" ]]; then
        log_info "Running enhanced dependency scanner"
        
        if "$PROJECT_ROOT/scripts/enhanced-dependency-scanner.sh" --format json --output-dir "$TEMP_DIR" >/dev/null 2>&1; then
            log_success "Enhanced dependency scanner completed successfully"
        else
            log_warning "Enhanced dependency scanner reported issues"
        fi
    fi
}

# Function to run compatibility tests
validate_compatibility() {
    log_info "Running compatibility validation"
    
    source "$TEMP_DIR/venv/bin/activate"
    
    # Test with different Python versions (if available)
    local python_versions=("python3.11" "python3.12")
    
    for py_version in "${python_versions[@]}"; do
        if command -v "$py_version" &> /dev/null; then
            log_info "Testing compatibility with $py_version"
            
            # Create separate environment for this Python version
            "$py_version" -m venv "$TEMP_DIR/venv-$(echo $py_version | tr '.' '-')" 2>/dev/null || continue
            source "$TEMP_DIR/venv-$(echo $py_version | tr '.' '-')/bin/activate"
            
            # Test basic dependency installation
            if pip install --upgrade pip >/dev/null 2>&1 && \
               pip install ansible-core molecule >/dev/null 2>&1; then
                log_success "$py_version compatibility confirmed"
            else
                log_warning "$py_version compatibility issues detected"
            fi
            
            deactivate
        fi
    done
    
    # Re-activate main environment
    source "$TEMP_DIR/venv/bin/activate"
}

# Function to validate molecule scenarios
validate_molecule_scenarios() {
    log_info "Validating Molecule scenarios"
    
    source "$TEMP_DIR/venv/bin/activate"
    
    # Install required tools
    pip install molecule[podman] ansible-core >/dev/null 2>&1
    
    if [[ -d "$PROJECT_ROOT/molecule" ]]; then
        for scenario_dir in "$PROJECT_ROOT/molecule"/*; do
            if [[ -d "$scenario_dir" ]]; then
                local scenario_name=$(basename "$scenario_dir")
                log_info "Validating Molecule scenario: $scenario_name"
                
                cd "$PROJECT_ROOT"
                
                # Test molecule syntax check
                if molecule syntax --scenario-name "$scenario_name" >/dev/null 2>&1; then
                    log_success "Molecule scenario $scenario_name syntax is valid"
                else
                    log_error "Molecule scenario $scenario_name has syntax errors"
                fi
                
                # Test molecule check (dependency validation)
                if molecule check --scenario-name "$scenario_name" >/dev/null 2>&1; then
                    log_success "Molecule scenario $scenario_name dependency check passed"
                else
                    log_warning "Molecule scenario $scenario_name dependency check had issues"
                fi
            fi
        done
    else
        log_warning "No Molecule scenarios found"
    fi
}

# Function to generate validation report
generate_validation_report() {
    local report_file="$REPORT_DIR/dependency-validation-$TIMESTAMP.json"
    
    cat > "$report_file" << EOF
{
  "validation_metadata": {
    "timestamp": "$(date -Iseconds)",
    "validation_mode": "$VALIDATION_MODE",
    "project_root": "$PROJECT_ROOT",
    "total_steps": $VALIDATION_STEPS,
    "passed_steps": $PASSED_STEPS,
    "failed_steps": $FAILED_STEPS,
    "warning_steps": $WARNING_STEPS,
    "success_rate": $(( PASSED_STEPS * 100 / VALIDATION_STEPS ))
  },
  "validation_summary": {
    "overall_status": "$(if [[ $FAILED_STEPS -eq 0 ]]; then echo "PASSED"; else echo "FAILED"; fi)",
    "critical_failures": $FAILED_STEPS,
    "warnings": $WARNING_STEPS
  }
}
EOF
    
    log_success "Validation report generated: $report_file"
}

# Function to cleanup validation environment
cleanup_validation_environment() {
    log_info "Cleaning up validation environment"
    
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    
    log_success "Cleanup completed"
}

# Function to create GitHub Actions summary
create_github_summary() {
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
        cat >> "$GITHUB_STEP_SUMMARY" << EOF
# Dependency Validation Results

## Summary
- **Validation Mode**: $VALIDATION_MODE
- **Total Steps**: $VALIDATION_STEPS
- **Passed**: $PASSED_STEPS ✅
- **Failed**: $FAILED_STEPS ❌
- **Warnings**: $WARNING_STEPS ⚠️
- **Success Rate**: $(( PASSED_STEPS * 100 / VALIDATION_STEPS ))%

## Status
$(if [[ $FAILED_STEPS -eq 0 ]]; then echo "✅ **All validations passed!**"; else echo "❌ **$FAILED_STEPS validation(s) failed**"; fi)

Generated: $(date)
EOF
    fi
}

# Main function
main() {
    echo -e "${BLUE}🔍 Dependency Update Validation Pipeline${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo "Validation mode: $VALIDATION_MODE"
    echo "Project root: $PROJECT_ROOT"
    echo ""
    
    # Setup validation environment
    setup_validation_environment
    
    # Run validations based on mode
    case "$VALIDATION_MODE" in
        "full")
            validate_python_dependencies
            validate_ansible_dependencies
            validate_container_dependencies
            validate_security
            validate_compatibility
            validate_molecule_scenarios
            ;;
        "quick")
            validate_python_dependencies
            validate_ansible_dependencies
            ;;
        "security-only")
            validate_security
            ;;
        *)
            log_error "Unknown validation mode: $VALIDATION_MODE"
            echo "Valid modes: full, quick, security-only"
            exit 1
            ;;
    esac
    
    # Generate reports
    generate_validation_report
    create_github_summary
    
    # Cleanup
    cleanup_validation_environment
    
    # Final summary
    echo ""
    echo -e "${PURPLE}=== Validation Summary ===${NC}"
    echo -e "${GREEN}✅ Passed: $PASSED_STEPS${NC}"
    echo -e "${YELLOW}⚠️  Warnings: $WARNING_STEPS${NC}"
    echo -e "${RED}❌ Failed: $FAILED_STEPS${NC}"
    echo -e "${BLUE}📊 Total: $VALIDATION_STEPS${NC}"
    echo -e "${BLUE}📈 Success Rate: $(( PASSED_STEPS * 100 / VALIDATION_STEPS ))%${NC}"
    
    if [[ $FAILED_STEPS -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All dependency validations passed!${NC}"
        if [[ $WARNING_STEPS -gt 0 ]]; then
            echo -e "${YELLOW}💡 Consider addressing warnings for optimal dependency health.${NC}"
        fi
        exit 0
    else
        echo -e "\n${RED}🚨 $FAILED_STEPS validation(s) failed!${NC}"
        echo -e "${YELLOW}🛠️  Please address the failed validations before proceeding.${NC}"
        exit 1
    fi
}

# Help function
show_help() {
    echo "Dependency Update Validation Pipeline"
    echo ""
    echo "Usage: $0 [MODE]"
    echo ""
    echo "Modes:"
    echo "  full          Complete validation (default)"
    echo "  quick         Basic Python and Ansible validation"
    echo "  security-only Security-focused validation"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "This tool validates:"
    echo "  - Python dependency compatibility"
    echo "  - Ansible Galaxy dependencies"
    echo "  - Container image availability"
    echo "  - Security vulnerabilities"
    echo "  - Cross-version compatibility"
    echo "  - Molecule scenario dependencies"
    echo ""
    echo "Exit codes:"
    echo "  0: All validations passed"
    echo "  1: One or more validations failed"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    full|quick|security-only)
        VALIDATION_MODE="$1"
        main
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown argument: $1"
        show_help
        exit 1
        ;;
esac
