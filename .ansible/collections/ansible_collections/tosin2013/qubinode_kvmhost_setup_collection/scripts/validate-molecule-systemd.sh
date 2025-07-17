#!/bin/bash
# Molecule systemd Container Configuration Validation Script
# Based on ADR-0013: Molecule Container Configuration Best Practices
# Validates systemd functionality and configuration compliance

set -euo pipefail

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

# Configuration validation
validate_molecule_config() {
    local molecule_file="$1"
    local scenario_name=$(basename $(dirname "$molecule_file"))
    
    log_info "Validating Molecule configuration for scenario: $scenario_name"
    
    # Check if file exists
    if [[ ! -f "$molecule_file" ]]; then
        log_error "Molecule configuration file not found: $molecule_file"
        return 1
    fi
    
    # Check for deprecated tmpfs configuration
    if grep -q "tmpfs:" "$molecule_file"; then
        log_error "DEPRECATED: Found tmpfs configuration in $molecule_file"
        log_error "Replace with 'systemd: always' per ADR-0013"
        return 1
    fi
    
    # Check for systemd: always usage
    if grep -q "systemd: always" "$molecule_file"; then
        log_success "✅ Uses 'systemd: always' configuration"
    else
        log_warning "⚠️  Consider using 'systemd: always' for automatic systemd handling"
    fi
    
    # Check for proper init commands
    if grep -q 'command: "/usr/sbin/init"' "$molecule_file"; then
        log_success "✅ Uses correct init command (/usr/sbin/init)"
    elif grep -q 'command: "/sbin/init"' "$molecule_file"; then
        log_success "✅ Uses correct init command (/sbin/init)"
    else
        log_warning "⚠️  No proper init command found"
    fi
    
    # Check for SYS_ADMIN capability
    if grep -q "SYS_ADMIN" "$molecule_file"; then
        log_success "✅ Has SYS_ADMIN capability"
    else
        log_error "❌ Missing SYS_ADMIN capability for systemd"
        return 1
    fi
    
    # Check for cgroup mounting
    if grep -q "/sys/fs/cgroup:/sys/fs/cgroup:ro" "$molecule_file"; then
        log_success "✅ Has proper cgroup mounting"
    else
        log_warning "⚠️  No explicit cgroup mounting found"
    fi
    
    # Check for init container images
    local init_images=(
        "ubi9-init"
        "ubi10-init"
        "9-ubi-init"
        "8-ubi-init"
        "stream9-init"
        "9-init"
    )
    
    local has_init_image=false
    for image in "${init_images[@]}"; do
        if grep -q "$image" "$molecule_file"; then
            log_success "✅ Uses init-enabled container image"
            has_init_image=true
            break
        fi
    done
    
    if [[ "$has_init_image" == "false" ]]; then
        log_warning "⚠️  No recognized init container image found"
    fi
    
    log_success "Configuration validation completed for $scenario_name"
    return 0
}

# Runtime validation
validate_systemd_runtime() {
    local instance_name="$1"
    
    log_info "Validating systemd runtime for instance: $instance_name"
    
    # Check if systemd is running as PID 1
    local systemd_pid
    systemd_pid=$(molecule exec -s "$instance_name" -- ps -p 1 -o comm= 2>/dev/null || echo "")
    
    if [[ "$systemd_pid" == "systemd" ]]; then
        log_success "✅ systemd is running as PID 1"
    else
        log_error "❌ systemd is not running as PID 1 (found: $systemd_pid)"
        return 1
    fi
    
    # Check systemd version
    local systemd_version
    systemd_version=$(molecule exec -s "$instance_name" -- systemctl --version | head -n1 2>/dev/null || echo "failed")
    
    if [[ "$systemd_version" != "failed" ]]; then
        log_success "✅ systemd version: $systemd_version"
    else
        log_error "❌ Failed to get systemd version"
        return 1
    fi
    
    # Check if systemd can list units
    if molecule exec -s "$instance_name" -- systemctl list-units --type=service --no-pager >/dev/null 2>&1; then
        log_success "✅ systemd can list service units"
    else
        log_error "❌ systemd cannot list service units"
        return 1
    fi
    
    # Check cgroup mounting
    if molecule exec -s "$instance_name" -- test -d /sys/fs/cgroup 2>/dev/null; then
        log_success "✅ cgroup filesystem is available"
    else
        log_error "❌ cgroup filesystem not available"
        return 1
    fi
    
    # Check for running systemd processes
    local systemd_processes
    systemd_processes=$(molecule exec -s "$instance_name" -- ps aux | grep -c systemd 2>/dev/null || echo "0")
    
    if [[ "$systemd_processes" -gt 1 ]]; then
        log_success "✅ Multiple systemd processes running ($systemd_processes)"
    else
        log_warning "⚠️  Only $systemd_processes systemd process(es) found"
    fi
    
    log_success "Runtime validation completed for $instance_name"
    return 0
}

# Main validation function
main() {
    local scenario="${1:-}"
    local mode="${2:-config}"
    
    echo "================================="
    echo "Molecule systemd Validation Tool"
    echo "ADR-0013 Compliance Checker"
    echo "================================="
    
    if [[ "$mode" == "config" ]]; then
        log_info "Running configuration validation mode"
        
        if [[ -n "$scenario" ]]; then
            # Validate specific scenario
            local molecule_file="molecule/$scenario/molecule.yml"
            validate_molecule_config "$molecule_file"
        else
            # Validate all scenarios
            local scenarios=(default modular validation rhel8 idempotency)
            local all_passed=true
            
            for scenario in "${scenarios[@]}"; do
                local molecule_file="molecule/$scenario/molecule.yml"
                if [[ -f "$molecule_file" ]]; then
                    echo
                    if ! validate_molecule_config "$molecule_file"; then
                        all_passed=false
                    fi
                else
                    log_warning "Scenario $scenario not found, skipping"
                fi
            done
            
            echo
            if [[ "$all_passed" == "true" ]]; then
                log_success "🎉 All Molecule configurations are ADR-0013 compliant!"
            else
                log_error "❌ Some configurations need updates for ADR-0013 compliance"
                exit 1
            fi
        fi
        
    elif [[ "$mode" == "runtime" ]]; then
        log_info "Running runtime validation mode"
        
        if [[ -z "$scenario" ]]; then
            log_error "Scenario name required for runtime validation"
            echo "Usage: $0 <scenario> runtime"
            exit 1
        fi
        
        # Get instance names for the scenario
        local instances
        instances=$(molecule list -s "$scenario" --format=yaml | grep -E "^  - instance:" | cut -d: -f2 | tr -d ' ' || echo "")
        
        if [[ -z "$instances" ]]; then
            log_error "No instances found for scenario: $scenario"
            log_info "Make sure to run 'molecule create -s $scenario' first"
            exit 1
        fi
        
        local all_passed=true
        for instance in $instances; do
            echo
            if ! validate_systemd_runtime "$instance"; then
                all_passed=false
            fi
        done
        
        echo
        if [[ "$all_passed" == "true" ]]; then
            log_success "🎉 All systemd runtime validations passed!"
        else
            log_error "❌ Some runtime validations failed"
            exit 1
        fi
        
    else
        echo "Usage: $0 [scenario] [mode]"
        echo
        echo "Modes:"
        echo "  config  - Validate Molecule configuration files (default)"
        echo "  runtime - Validate systemd functionality in running containers"
        echo
        echo "Examples:"
        echo "  $0                    # Validate all scenario configurations"
        echo "  $0 default            # Validate default scenario configuration"
        echo "  $0 default runtime    # Validate default scenario runtime"
        echo
        echo "For runtime validation, ensure containers are created first:"
        echo "  molecule create -s <scenario>"
        echo "  $0 <scenario> runtime"
        exit 1
    fi
}

# Run main function
main "$@"
