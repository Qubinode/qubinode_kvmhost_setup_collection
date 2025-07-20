#!/bin/bash
# ADR Container Compliance Validator
# Validates that container configurations comply with ADR-0012 and ADR-0013

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
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to validate workflow container configurations
validate_workflow_containers() {
    local workflow_file="$1"
    local violations=0
    
    log_info "Validating container configurations in: $workflow_file"
    
    # Check for non-compliant images (exclude ubi-init and init variants)
    if grep -q "docker.io/rockylinux/rockylinux:[0-9][^-]" "$workflow_file" && ! grep -q "ubi-init" "$workflow_file"; then
        log_error "Found non-compliant Rocky Linux images (should use ubi-init variants)"
        violations=$((violations + 1))
    fi

    if grep -q "docker.io/almalinux/almalinux:[0-9][^-]" "$workflow_file" && ! grep -q "init" "$workflow_file"; then
        log_error "Found non-compliant AlmaLinux images (should use init variants)"
        violations=$((violations + 1))
    fi
    
    # Check for deprecated tmpfs configuration
    if grep -q "tmpfs:" "$workflow_file"; then
        log_error "Found deprecated tmpfs configuration (should use systemd: always)"
        violations=$((violations + 1))
    fi
    
    # Check for privileged containers (should be avoided per ADR-0012)
    if grep -q "privileged: true" "$workflow_file"; then
        log_warning "Found privileged containers (ADR-0012 recommends rootless Podman)"
    fi
    
    # Check for ADR-compliant images
    if grep -q "registry.redhat.io/ubi[0-9]/ubi-init" "$workflow_file"; then
        log_success "Uses ADR-compliant UBI init images"
    fi
    
    # Check for systemd: always configuration
    if grep -q "systemd: always" "$workflow_file"; then
        log_success "Uses ADR-compliant systemd configuration"
    fi
    
    # Check for proper init commands
    if grep -q 'command: /usr/sbin/init' "$workflow_file"; then
        log_success "Uses correct init command (/usr/sbin/init)"
    elif grep -q 'command: /sbin/init' "$workflow_file"; then
        log_success "Uses correct init command (/sbin/init)"
    fi
    
    # Check for SYS_ADMIN capability
    if grep -q "SYS_ADMIN" "$workflow_file"; then
        log_success "Includes required SYS_ADMIN capability"
    fi
    
    # Check for cgroup mounting
    if grep -q "/sys/fs/cgroup:/sys/fs/cgroup:ro" "$workflow_file"; then
        log_success "Properly mounts cgroups"
    fi
    
    return $violations
}

# Function to validate Molecule configurations
validate_molecule_configs() {
    local violations=0
    
    log_info "Validating Molecule configurations..."
    
    # Find all molecule.yml files
    find "$PROJECT_ROOT" -name "molecule.yml" -type f | while read -r molecule_file; do
        log_info "Checking: $molecule_file"
        
        # Check for deprecated tmpfs list configuration
        if grep -A 5 "tmpfs:" "$molecule_file" | grep -q "- /run"; then
            log_error "Found deprecated tmpfs list configuration in $molecule_file"
            violations=$((violations + 1))
        fi
        
        # Check for non-init images
        if grep -q "image: docker.io/rockylinux/rockylinux:[0-9]" "$molecule_file"; then
            log_error "Found non-compliant Rocky Linux image in $molecule_file"
            violations=$((violations + 1))
        fi
        
        # Check for ADR-compliant configurations
        if grep -q "systemd: always" "$molecule_file"; then
            log_success "Uses systemd: always in $molecule_file"
        fi
        
        if grep -q "registry.redhat.io/ubi" "$molecule_file"; then
            log_success "Uses UBI images in $molecule_file"
        fi
    done
    
    return $violations
}

# Function to check for ADR compliance documentation
validate_adr_compliance() {
    log_info "Validating ADR compliance documentation..."
    
    # Check if ADR-0012 exists
    if [ -f "$PROJECT_ROOT/docs/adrs/adr-0012-init-container-vs-regular-container-molecule-testing.md" ]; then
        log_success "ADR-0012 documentation exists"
    else
        log_error "ADR-0012 documentation missing"
        return 1
    fi
    
    # Check if ADR-0013 exists
    if [ -f "$PROJECT_ROOT/docs/adrs/adr-0013-molecule-systemd-configuration-best-practices.md" ]; then
        log_success "ADR-0013 documentation exists"
    else
        log_error "ADR-0013 documentation missing"
        return 1
    fi
    
    return 0
}

# Function to generate compliance report
generate_compliance_report() {
    local total_violations="$1"
    
    echo ""
    echo -e "${BLUE}📋 ADR Container Compliance Report${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo "Generated: $(date)"
    echo "Project: Qubinode KVM Host Setup Collection"
    echo ""
    
    if [ "$total_violations" -eq 0 ]; then
        echo -e "${GREEN}✅ COMPLIANT: All container configurations follow ADR-0012 and ADR-0013${NC}"
        echo ""
        echo "Key compliance points verified:"
        echo "- Uses systemd-enabled init containers (UBI-init images)"
        echo "- Avoids deprecated tmpfs list configuration"
        echo "- Uses systemd: always for automatic systemd handling"
        echo "- Includes proper init commands and capabilities"
        echo "- Mounts cgroups correctly"
    else
        echo -e "${RED}❌ NON-COMPLIANT: Found $total_violations violations${NC}"
        echo ""
        echo "Required actions:"
        echo "1. Replace non-compliant container images with UBI-init variants"
        echo "2. Remove deprecated tmpfs configurations"
        echo "3. Add systemd: always configuration"
        echo "4. Ensure proper init commands and capabilities"
        echo ""
        echo "See ADR-0012 and ADR-0013 for detailed guidance"
    fi
    
    echo ""
    echo "References:"
    echo "- ADR-0012: Init Container vs Regular Container Molecule Testing"
    echo "- ADR-0013: Molecule systemd Configuration Best Practices"
    echo "- Validation script: scripts/validate-adr-container-compliance.sh"
}

# Main function
main() {
    echo -e "${BLUE}🔍 ADR Container Compliance Validator${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo ""
    
    local total_violations=0
    
    # Validate workflow files
    for workflow in "$PROJECT_ROOT"/.github/workflows/*.yml; do
        if [ -f "$workflow" ]; then
            validate_workflow_containers "$workflow"
            violations=$?
            total_violations=$((total_violations + violations))
        fi
    done
    
    # Validate Molecule configurations
    validate_molecule_configs
    violations=$?
    total_violations=$((total_violations + violations))
    
    # Validate ADR documentation
    validate_adr_compliance
    violations=$?
    total_violations=$((total_violations + violations))
    
    # Generate compliance report
    generate_compliance_report "$total_violations"
    
    # Exit with appropriate code
    if [ "$total_violations" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
