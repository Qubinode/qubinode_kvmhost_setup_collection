#!/bin/bash

# =============================================================================
# Migration Template Generator - The "Upgrade Path Architect"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script generates comprehensive migration documentation templates,
# helping users navigate upgrade paths and system transitions systematically.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Migration Analysis - Analyzes current and target system states
# 2. [PHASE 2]: Path Planning - Plans optimal migration paths and sequences
# 3. [PHASE 3]: Template Generation - Creates structured migration templates
# 4. [PHASE 4]: Risk Assessment - Identifies migration risks and mitigation strategies
# 5. [PHASE 5]: Validation Planning - Creates validation and rollback procedures
# 6. [PHASE 6]: Documentation Creation - Generates comprehensive migration guides
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Generates: Migration templates for system upgrades and transitions
# - Implements: ADR-0010 End-User Repeatability Strategy requirements
# - Creates: Structured documentation in docs/migration-templates/
# - Supports: Version upgrades, platform migrations, and configuration changes
# - Provides: Step-by-step migration procedures with validation checkpoints
# - Enables: Repeatable and reliable system transitions
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - SYSTEMATIC: Creates structured, repeatable migration procedures
# - COMPREHENSIVE: Covers all aspects of system migration and transition
# - RISK-AWARE: Includes risk assessment and mitigation strategies
# - VALIDATION: Incorporates validation and rollback procedures
# - USER-FOCUSED: Generates documentation optimized for end-user consumption
# - TEMPLATE-BASED: Creates reusable templates for different migration types
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Migration Types: Add templates for new types of system migrations
# - Template Formats: Add new output formats or template structures
# - Risk Analysis: Enhance risk assessment and mitigation planning
# - Validation: Add new validation procedures and checkpoint templates
# - Integration: Add integration with migration management tools
# - Automation: Add automated migration template generation
#
# 🚨 IMPORTANT FOR LLMs: Migration templates guide critical system changes.
# Ensure templates are accurate, comprehensive, and include proper validation
# and rollback procedures. Incorrect migration guidance can cause system failures.

# Migration Path Documentation Generator
# Part of ADR-0010: End-User Repeatability Strategy
# Creates structured migration documentation templates

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
Migration Path Documentation Generator

USAGE:
    $0 [OPTIONS] --source SOURCE_PLATFORM --target TARGET_PLATFORM

OPTIONS:
    -h, --help              Show this help message
    -s, --source            Source platform (e.g., rhel8, centos8, rocky8)
    -t, --target            Target platform (e.g., rhel9, rocky9, alma9)
    -o, --output-dir        Output directory [default: docs/migration-guides/]
    --template-type         Template type (assessment, planning, execution, rollback, all) [default: all]
    --include-validation    Include validation steps and checklists
    --custom-requirements   Include custom requirement sections

EXAMPLES:
    $0 -s rhel8 -t rhel9                           # RHEL 8 to RHEL 9 migration
    $0 -s centos8 -t rocky9 --include-validation   # CentOS 8 to Rocky 9 with validation
    $0 --template-type assessment                   # Generate only assessment template
    $0 --source all --target all                   # Generate all migration combinations

SUPPORTED PLATFORMS:
    - rhel8, rhel9, rhel10
    - rocky8, rocky9
    - alma8, alma9, almalinux8, almalinux9
    - centos8, centos9
    - fedora37, fedora38, fedora39, fedora40

TEMPLATE TYPES:
    - assessment: Pre-migration environment assessment
    - planning: Detailed migration planning checklist
    - execution: Step-by-step migration procedures
    - rollback: Rollback plans and recovery procedures
    - all: Generate complete migration documentation set

EOF
}

# Parse command line arguments
SOURCE_PLATFORM=""
TARGET_PLATFORM=""
OUTPUT_DIR="docs/migration-guides"
TEMPLATE_TYPE="all"
INCLUDE_VALIDATION=false
CUSTOM_REQUIREMENTS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--source)
            SOURCE_PLATFORM="$2"
            shift 2
            ;;
        -t|--target)
            TARGET_PLATFORM="$2"
            shift 2
            ;;
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --template-type)
            TEMPLATE_TYPE="$2"
            shift 2
            ;;
        --include-validation)
            INCLUDE_VALIDATION=true
            shift
            ;;
        --custom-requirements)
            CUSTOM_REQUIREMENTS=true
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

# Validate input parameters
validate_parameters() {
    log_info "Validating parameters..."
    
    if [[ -z "$SOURCE_PLATFORM" ]]; then
        log_error "Source platform is required. Use -s or --source"
        exit 1
    fi
    
    if [[ -z "$TARGET_PLATFORM" ]]; then
        log_error "Target platform is required. Use -t or --target"
        exit 1
    fi
    
    # Normalize platform names
    case "$SOURCE_PLATFORM" in
        rhel8|redhat8|el8) SOURCE_PLATFORM="rhel8" ;;
        rhel9|redhat9|el9) SOURCE_PLATFORM="rhel9" ;;
        rhel10|redhat10|el10) SOURCE_PLATFORM="rhel10" ;;
        rocky8) SOURCE_PLATFORM="rocky8" ;;
        rocky9) SOURCE_PLATFORM="rocky9" ;;
        alma8|almalinux8) SOURCE_PLATFORM="alma8" ;;
        alma9|almalinux9) SOURCE_PLATFORM="alma9" ;;
        centos8) SOURCE_PLATFORM="centos8" ;;
        centos9) SOURCE_PLATFORM="centos9" ;;
        all) SOURCE_PLATFORM="all" ;;
        *)
            log_error "Unsupported source platform: $SOURCE_PLATFORM"
            exit 1
            ;;
    esac
    
    case "$TARGET_PLATFORM" in
        rhel8|redhat8|el8) TARGET_PLATFORM="rhel8" ;;
        rhel9|redhat9|el9) TARGET_PLATFORM="rhel9" ;;
        rhel10|redhat10|el10) TARGET_PLATFORM="rhel10" ;;
        rocky8) TARGET_PLATFORM="rocky8" ;;
        rocky9) TARGET_PLATFORM="rocky9" ;;
        alma8|almalinux8) TARGET_PLATFORM="alma8" ;;
        alma9|almalinux9) TARGET_PLATFORM="alma9" ;;
        centos8) TARGET_PLATFORM="centos8" ;;
        centos9) TARGET_PLATFORM="centos9" ;;
        all) TARGET_PLATFORM="all" ;;
        *)
            log_error "Unsupported target platform: $TARGET_PLATFORM"
            exit 1
            ;;
    esac
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    log_success "Parameters validated"
}

# Get platform display name
get_platform_display_name() {
    local platform="$1"
    case "$platform" in
        rhel8) echo "Red Hat Enterprise Linux 8" ;;
        rhel9) echo "Red Hat Enterprise Linux 9" ;;
        rhel10) echo "Red Hat Enterprise Linux 10" ;;
        rocky8) echo "Rocky Linux 8" ;;
        rocky9) echo "Rocky Linux 9" ;;
        alma8) echo "AlmaLinux 8" ;;
        alma9) echo "AlmaLinux 9" ;;
        centos8) echo "CentOS 8" ;;
        centos9) echo "CentOS 9" ;;
        *) echo "$platform" ;;
    esac
}

# Get migration complexity level
get_migration_complexity() {
    local source="$1"
    local target="$2"
    
    # Define complexity matrix
    case "$source-$target" in
        # Same major version, different distro - Medium
        rhel8-rocky8|rhel8-alma8|rocky8-alma8|alma8-rocky8) echo "Medium" ;;
        rhel9-rocky9|rhel9-alma9|rocky9-alma9|alma9-rocky9) echo "Medium" ;;
        
        # Major version upgrade within same family - Medium to High
        rhel8-rhel9|rocky8-rocky9|alma8-alma9) echo "Medium" ;;
        
        # Major version upgrade with distro change - High
        rhel8-rocky9|rhel8-alma9|rocky8-rhel9|alma8-rhel9) echo "High" ;;
        rhel8-rhel10|rocky8-rhel10|alma8-rhel10) echo "High" ;;
        
        # CentOS migrations - High (EOL concerns)
        centos8-*|*-centos8) echo "High" ;;
        
        # RHEL 9 to 10 - Medium (well supported)
        rhel9-rhel10|rocky9-rhel10|alma9-rhel10) echo "Medium" ;;
        
        # Downgrades - Critical
        rhel9-rhel8|rhel10-rhel9|rocky9-rocky8|alma9-alma8) echo "Critical" ;;
        
        *) echo "Medium" ;;
    esac
}

# Generate assessment template
generate_assessment_template() {
    local source="$1"
    local target="$2"
    local output_file="$3"
    
    local source_display=$(get_platform_display_name "$source")
    local target_display=$(get_platform_display_name "$target")
    local complexity=$(get_migration_complexity "$source" "$target")
    
    cat > "$output_file" << EOF
# Migration Assessment: $source_display → $target_display

**Assessment Date**: $(date)  
**Migration Complexity**: $complexity  
**Assessment Status**: 🔄 In Progress  

## Executive Summary

### Migration Overview
- **Source Platform**: $source_display
- **Target Platform**: $target_display  
- **Migration Type**: $(if [[ "$source" == rhel* && "$target" == rhel* ]]; then echo "In-place OS upgrade"; else echo "Cross-distribution migration"; fi)
- **Expected Downtime**: TBD (Complete after assessment)
- **Risk Level**: $complexity

### Key Decision Points
- [ ] **Business Justification**: Document why migration is needed
- [ ] **Timeline Requirements**: Define hard deadlines and business windows
- [ ] **Resource Allocation**: Confirm team availability and skill requirements
- [ ] **Budget Approval**: Estimate costs for licensing, hardware, and labor

## Current Environment Assessment

### System Inventory
- [ ] **Total KVM Hosts**: ___
- [ ] **Virtual Machines**: ___
- [ ] **Storage Capacity**: ___ TB
- [ ] **Network Configuration**: Document current bridge setup
- [ ] **Performance Baselines**: Record current metrics

### Software Inventory
\`\`\`bash
# Run this assessment script on each host
cat > assess-current-environment.sh << 'ASSESS_EOF'
#!/bin/bash
echo "=== System Assessment Report ==="
echo "Host: \$(hostname)"
echo "OS: \$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo "Kernel: \$(uname -r)"
echo "Ansible: \$(ansible --version | head -1)"
echo ""
echo "=== KVM Environment ==="
echo "Libvirt: \$(libvirtd --version 2>/dev/null || echo 'Not installed')"
echo "VMs: \$(virsh list --all | wc -l)"
echo "Storage Pools: \$(virsh pool-list | wc -l)"
echo "Networks: \$(virsh net-list | wc -l)"
echo ""
echo "=== Hardware ==="
echo "CPU: \$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
echo "Memory: \$(free -h | grep Mem | awk '{print \$2}')"
echo "Storage: \$(df -h / | tail -1 | awk '{print \$4" available"}')"
echo "Virtualization: \$(lscpu | grep Virtualization | cut -d: -f2 | xargs || echo 'None detected')"
ASSESS_EOF
chmod +x assess-current-environment.sh
\`\`\`

### Compatibility Assessment

#### Qubinode Collection Compatibility
| Component | Current Version | Target Compatibility | Status | Notes |
|-----------|----------------|---------------------|---------|-------|
| kvmhost_base | Current | $(if [[ "$target" =~ (rhel9|rhel10|rocky9|alma9) ]]; then echo "✅ Supported"; else echo "⚠️ Check required"; fi) | 🔄 Review | |
| kvmhost_networking | Current | $(if [[ "$target" =~ (rhel9|rhel10|rocky9|alma9) ]]; then echo "✅ Supported"; else echo "⚠️ Check required"; fi) | 🔄 Review | |  
| kvmhost_libvirt | Current | $(if [[ "$target" =~ (rhel9|rhel10|rocky9|alma9) ]]; then echo "✅ Supported"; else echo "⚠️ Check required"; fi) | 🔄 Review | |
| kvmhost_storage | Current | $(if [[ "$target" =~ (rhel9|rhel10|rocky9|alma9) ]]; then echo "✅ Supported"; else echo "⚠️ Check required"; fi) | 🔄 Review | |
| kvmhost_cockpit | Current | $(if [[ "$target" =~ (rhel9|rhel10|rocky9|alma9) ]]; then echo "✅ Supported"; else echo "⚠️ Check required"; fi) | 🔄 Review | |
| kvmhost_user_config | Current | $(if [[ "$target" =~ (rhel9|rhel10|rocky9|alma9) ]]; then echo "✅ Supported"; else echo "⚠️ Check required"; fi) | 🔄 Review | |

#### Application Compatibility
- [ ] **Virtual Machine OS Versions**: List all guest OS versions
- [ ] **Custom Applications**: Document any custom KVM management tools
- [ ] **Monitoring Tools**: Verify compatibility with target platform
- [ ] **Backup Solutions**: Confirm backup/restore tools work on target

### Risk Assessment

#### High-Risk Areas
$(if [[ "$complexity" == "Critical" ]]; then
echo "- 🔴 **CRITICAL**: Downgrade migration - high risk of data loss
- 🔴 **CRITICAL**: Extensive testing required before proceeding"
elif [[ "$complexity" == "High" ]]; then
echo "- 🟡 **HIGH**: Cross-distribution migration complexity
- 🟡 **HIGH**: Potential configuration incompatibilities"
else
echo "- 🟢 **MEDIUM**: Standard migration complexity
- 🟢 **MEDIUM**: Well-documented migration path"
fi)

- [ ] **Network Configuration**: Bridge setup may require updates
- [ ] **Storage Migration**: LVM and filesystem compatibility
- [ ] **VM Compatibility**: Guest OS support on target platform
- [ ] **Performance Impact**: Potential performance changes

#### Mitigation Strategies
- [ ] **Full Environment Backup**: Complete system and VM backups
- [ ] **Test Environment**: Set up identical test environment
- [ ] **Rollback Plan**: Detailed rollback procedures documented
- [ ] **Staged Migration**: Plan phased migration approach

### Prerequisites Validation

#### Infrastructure Requirements
- [ ] **Hardware Compatibility**: Verify target OS hardware support
- [ ] **Network Requirements**: Document network dependencies
- [ ] **Storage Requirements**: Confirm sufficient space for migration
- [ ] **Backup Requirements**: Verify backup capacity for full environment

#### Team Readiness
- [ ] **Training Requirements**: Identify platform-specific training needs
- [ ] **Skill Assessment**: Verify team has required expertise
- [ ] **Resource Availability**: Confirm team availability during migration
- [ ] **Escalation Procedures**: Define support escalation paths

## Migration Planning Recommendations

### Recommended Approach
$(case "$complexity" in
    "Critical")
        echo "**RECOMMENDATION**: ⚠️ **DO NOT PROCEED** without extensive testing and business approval
**ALTERNATIVE**: Consider fresh installation with data migration instead of in-place upgrade"
        ;;
    "High")
        echo "**RECOMMENDATION**: 📋 **STAGED MIGRATION** - migrate non-critical systems first
**TIMELINE**: Plan 2-4 week migration window with extensive testing phase"
        ;;
    "Medium")
        echo "**RECOMMENDATION**: 📈 **PHASED APPROACH** - group systems by criticality
**TIMELINE**: Plan 1-2 week migration window with standard testing"
        ;;
    *)
        echo "**RECOMMENDATION**: ✅ **STANDARD MIGRATION** - follow established procedures
**TIMELINE**: Plan 3-5 day migration window"
        ;;
esac)

### Next Steps
1. [ ] **Complete Assessment**: Fill in all TBD items above
2. [ ] **Stakeholder Review**: Present findings to business stakeholders
3. [ ] **Go/No-Go Decision**: Formal approval to proceed
4. [ ] **Detailed Planning**: Generate migration plan using planning template
5. [ ] **Test Environment**: Set up test environment for validation

---

**Assessment Completed By**: _______________  
**Review Date**: _______________  
**Approval Status**: ⏳ Pending Review  

**Generated by**: Qubinode Migration Tools  
**Template Version**: 1.0  
**Last Updated**: $(date)
EOF

    log_success "Assessment template generated: $output_file"
}

# Generate planning template
generate_planning_template() {
    local source="$1"
    local target="$2"
    local output_file="$3"
    
    local source_display=$(get_platform_display_name "$source")
    local target_display=$(get_platform_display_name "$target")
    local complexity=$(get_migration_complexity "$source" "$target")
    
    cat > "$output_file" << EOF
# Migration Plan: $source_display → $target_display

**Plan Created**: $(date)  
**Migration Complexity**: $complexity  
**Plan Status**: 📋 Draft  

## Migration Overview

### Project Details
- **Project Name**: KVM Host Migration - $source_display to $target_display
- **Project Manager**: _______________
- **Technical Lead**: _______________
- **Migration Window**: _______________ to _______________
- **Expected Duration**: _____ hours
- **Rollback Window**: _____ hours after completion

### Success Criteria
- [ ] All KVM hosts successfully migrated to $target_display
- [ ] All virtual machines operational on target platform
- [ ] Network connectivity and performance maintained
- [ ] Storage systems accessible and functional
- [ ] Cockpit web interface operational
- [ ] User access and permissions preserved
- [ ] Performance baselines met or exceeded

## Pre-Migration Checklist

### Environment Preparation
- [ ] **Backup Verification**: Confirm all backups are current and tested
- [ ] **Change Freeze**: Implement change freeze 48 hours before migration
- [ ] **Communication**: Notify all stakeholders of migration schedule
- [ ] **Test Environment**: Validate migration procedures in test environment
- [ ] **Documentation**: Review and update all system documentation

### Technical Readiness
- [ ] **Ansible Environment**: Update to latest compatible version
- [ ] **Qubinode Collection**: Update to version supporting target platform
- [ ] **Network Configuration**: Document and validate bridge configurations
- [ ] **Storage Preparation**: Verify LVM configurations and free space
- [ ] **VM Inventory**: Complete inventory of all virtual machines

### Team Readiness
- [ ] **Skill Verification**: Confirm team familiarity with target platform
- [ ] **Tool Access**: Verify access to all required tools and credentials
- [ ] **Communication Channels**: Establish communication channels for migration day
- [ ] **Escalation Contacts**: Document escalation procedures and contacts

## Migration Sequence

### Phase 1: Infrastructure Migration (Hours 1-4)
$(if [[ "$complexity" == "Critical" ]]; then
echo "⚠️ **CRITICAL MIGRATION** - Each step requires explicit approval"
fi)

#### Step 1.1: Pre-Migration Validation
\`\`\`bash
# Run comprehensive pre-migration checks
ansible-playbook -i inventory pre-migration-validation.yml \\
  --extra-vars "source_platform=$source target_platform=$target"
\`\`\`
- [ ] System health checks passed
- [ ] Network connectivity verified
- [ ] Storage systems accessible
- [ ] Virtual machines running normally

#### Step 1.2: System Backup
\`\`\`bash
# Create full system backups
ansible-playbook -i inventory backup-systems.yml \\
  --extra-vars "backup_type=full migration_date=\$(date +%Y%m%d)"
\`\`\`
- [ ] Host system configurations backed up
- [ ] Virtual machine definitions exported
- [ ] Storage pool configurations saved
- [ ] Network configurations documented

#### Step 1.3: VM Graceful Shutdown
\`\`\`bash
# Gracefully shutdown all VMs
ansible-playbook -i inventory shutdown-vms.yml \\
  --extra-vars "shutdown_timeout=300"
\`\`\`
- [ ] All VMs shut down gracefully
- [ ] VM status verified
- [ ] Storage unmounted cleanly

### Phase 2: OS Migration (Hours 4-8)
$(if [[ "$source" == centos* ]]; then
echo "**CentOS Migration Note**: Special handling required for EOL platform"
fi)

#### Step 2.1: Repository Configuration
\`\`\`bash
# Configure target platform repositories
$(case "$target" in
    rhel*)
        echo "# Register with Red Hat Subscription Manager
subscription-manager register --username=\$RHEL_USERNAME --password=\$RHEL_PASSWORD
subscription-manager attach --auto"
        ;;
    rocky*)
        echo "# Configure Rocky Linux repositories
dnf install -y https://dl.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/r/rocky-release-9.*.rpm"
        ;;
    alma*)
        echo "# Configure AlmaLinux repositories  
dnf install -y https://repo.almalinux.org/almalinux/9/BaseOS/x86_64/os/Packages/almalinux-release-9.*.rpm"
        ;;
esac)
\`\`\`
- [ ] Repository configuration completed
- [ ] GPG keys imported
- [ ] Repository metadata updated

#### Step 2.2: Package Migration
\`\`\`bash
# Migrate packages to target platform
$(if [[ "$complexity" == "Critical" ]]; then
echo "# ⚠️ CRITICAL: This is a risky operation - ensure backups are current
# Consider fresh installation instead of upgrade"
else
echo "# Update system packages for target platform
dnf system-upgrade download --releasever=$(echo $target | grep -o '[0-9]*')
dnf system-upgrade reboot"
fi)
\`\`\`
- [ ] Package download completed
- [ ] Dependencies resolved
- [ ] System rebooted successfully
- [ ] New OS version verified

### Phase 3: Service Restoration (Hours 8-12)

#### Step 3.1: Qubinode Collection Update
\`\`\`bash
# Update Qubinode collection for target platform
ansible-galaxy collection install community.qubinode:>=2.0.0
ansible-playbook -i inventory kvmhost-setup.yml \\
  --extra-vars "target_os=$target force_update=true"
\`\`\`
- [ ] Collection updated
- [ ] Host configuration updated
- [ ] Services restarted

#### Step 3.2: KVM Environment Restoration
\`\`\`bash
# Restore KVM environment
ansible-playbook -i inventory restore-kvm-environment.yml \\
  --extra-vars "restore_date=\$(date +%Y%m%d)"
\`\`\`
- [ ] Libvirt services running
- [ ] Storage pools active
- [ ] Network bridges configured
- [ ] VM definitions imported

#### Step 3.3: Virtual Machine Startup
\`\`\`bash
# Start virtual machines
ansible-playbook -i inventory startup-vms.yml \\
  --extra-vars "startup_timeout=600"
\`\`\`
- [ ] VMs started successfully
- [ ] Network connectivity verified
- [ ] Services within VMs operational

### Phase 4: Validation & Testing (Hours 12-16)

#### Step 4.1: Functional Testing
- [ ] **Network Connectivity**: Verify all network bridges operational
- [ ] **Storage Access**: Confirm all storage pools accessible
- [ ] **VM Functionality**: Test critical applications in VMs
- [ ] **Cockpit Interface**: Verify web interface accessibility
- [ ] **User Access**: Confirm user authentication and permissions

#### Step 4.2: Performance Validation
\`\`\`bash
# Run performance validation tests
ansible-playbook -i inventory performance-validation.yml \\
  --extra-vars "baseline_file=pre-migration-baseline.json"
\`\`\`
- [ ] CPU performance within 5% of baseline
- [ ] Memory utilization normal
- [ ] Storage I/O performance acceptable
- [ ] Network throughput maintained

#### Step 4.3: Integration Testing
- [ ] **Backup Systems**: Verify backup operations
- [ ] **Monitoring**: Confirm monitoring systems operational
- [ ] **External Connectivity**: Test connections to external systems
- [ ] **User Workflows**: Validate end-user scenarios

## Post-Migration Activities

### Immediate Tasks (Within 24 hours)
- [ ] **Documentation Update**: Update system documentation
- [ ] **Monitoring**: Monitor system stability
- [ ] **User Communication**: Notify users of completion
- [ ] **Support Readiness**: Ensure support team ready for issues

### Follow-up Tasks (Within 1 week)
- [ ] **Performance Review**: Analyze performance metrics
- [ ] **Lessons Learned**: Document lessons learned
- [ ] **Process Improvement**: Update migration procedures
- [ ] **Training**: Provide platform-specific training if needed

## Risk Management

### Identified Risks
| Risk | Probability | Impact | Mitigation | Owner |
|------|-------------|---------|------------|-------|
| $(if [[ "$complexity" == "Critical" ]]; then echo "Data Loss | High | Critical | Full backup + test restore | Tech Lead"; else echo "Service Downtime | Medium | High | Staged migration + rollback plan | Tech Lead"; fi) |
| Network Issues | Low | Medium | Pre-validate network config | Network Admin |
| VM Compatibility | Medium | Medium | Test in lab environment | Systems Admin |
| Performance Degradation | Low | Medium | Performance baseline validation | Performance Lead |

### Rollback Procedures
$(if [[ "$complexity" == "Critical" ]]; then
echo "**CRITICAL**: Rollback may not be possible - ensure comprehensive backups"
else
echo "**Rollback Trigger**: Any critical system failure or >20% performance degradation"
fi)

1. [ ] **Stop Migration**: Halt all migration activities
2. [ ] **Assessment**: Evaluate scope of rollback required
3. [ ] **System Restore**: Restore from pre-migration backups
4. [ ] **Service Verification**: Verify all services operational
5. [ ] **Communication**: Notify stakeholders of rollback

## Communication Plan

### Stakeholder Notifications
- [ ] **24 hours before**: Final migration reminder
- [ ] **Migration start**: Confirm migration beginning
- [ ] **Phase completions**: Update on major milestone completion
- [ ] **Issues**: Immediate notification of any problems
- [ ] **Completion**: Confirm successful completion

### Status Reporting
- **Frequency**: Every 2 hours during migration window
- **Method**: Email + Slack/Teams channel
- **Escalation**: Issues requiring >1 hour to resolve

---

**Plan Approved By**: _______________  
**Date**: _______________  
**Next Review**: _______________  

**Generated by**: Qubinode Migration Tools  
**Template Version**: 1.0  
**Last Updated**: $(date)
EOF

    log_success "Planning template generated: $output_file"
}

# Generate execution template
generate_execution_template() {
    local source="$1"
    local target="$2"
    local output_file="$3"
    
    local source_display=$(get_platform_display_name "$source")
    local target_display=$(get_platform_display_name "$target")
    
    cat > "$output_file" << EOF
# Migration Execution Guide: $source_display → $target_display

**Execution Date**: $(date)  
**Migration Lead**: _______________  
**Status**: 🚀 Ready to Execute  

## Pre-Execution Checklist

### Final Validation (T-1 Hour)
- [ ] **Team Assembly**: All team members present and ready
- [ ] **Communication**: Stakeholders notified of start time
- [ ] **Backups**: Final backup verification completed
- [ ] **Test Environment**: Migration procedures validated in test
- [ ] **Rollback Readiness**: Rollback procedures tested and ready

### Go/No-Go Decision
- [ ] **Business Approval**: Final business approval obtained
- [ ] **Technical Readiness**: All technical prerequisites met
- [ ] **Risk Assessment**: Acceptable risk level confirmed
- [ ] **Weather Check**: No adverse conditions (if applicable)

**Final Go/No-Go Decision**: ⏳ Pending  
**Decision Made By**: _______________  
**Time**: _______________  

## Step-by-Step Execution

### Step 1: Migration Initiation (T+0 minutes)
\`\`\`bash
# Start migration logging
exec > >(tee -a migration-\$(date +%Y%m%d-%H%M%S).log)
exec 2>&1

echo "=== MIGRATION START ==="
echo "Date: \$(date)"
echo "Source: $source_display"
echo "Target: $target_display"
echo "Operator: \$(whoami)"
\`\`\`

**Checkpoint 1.1**: Migration logging started  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 2: Environment Freeze (T+5 minutes)
\`\`\`bash
# Implement change freeze
ansible-playbook -i inventory freeze-environment.yml
\`\`\`

**Checkpoint 2.1**: Environment frozen  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 3: Final Backup (T+10 minutes)
\`\`\`bash
# Create final pre-migration backup
ansible-playbook -i inventory final-backup.yml \\
  --extra-vars "backup_label=pre-migration-final"
\`\`\`

**Checkpoint 3.1**: Final backup completed  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**Backup Size**: _____ GB  
**Backup Location**: _______________  

### Step 4: Virtual Machine Shutdown (T+30 minutes)
\`\`\`bash
# Graceful VM shutdown
for vm in \$(virsh list --name); do
  echo "Shutting down \$vm..."
  virsh shutdown "\$vm"
done

# Wait for clean shutdown
sleep 60

# Verify all VMs are shut down
virsh list --all
\`\`\`

**Checkpoint 4.1**: All VMs shut down  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**VMs Processed**: _____  

### Step 5: System Migration (T+45 minutes)
$(if [[ "$source" == centos* ]]; then
echo "# Special CentOS migration procedure
\`\`\`bash
# CentOS EOL migration - requires special handling
dnf remove centos-release centos-repos
$(case "$target" in
    rhel*) echo "# Install RHEL repositories
rpm -ivh https://dl.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/r/rocky-release-9.*.rpm" ;;
    rocky*) echo "# Install Rocky repositories  
rpm -ivh https://dl.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/r/rocky-release-9.*.rpm" ;;
    alma*) echo "# Install AlmaLinux repositories
rpm -ivh https://repo.almalinux.org/almalinux/9/BaseOS/x86_64/os/Packages/almalinux-release-9.*.rpm" ;;
esac)
\`\`\`"
else
echo "# Standard OS migration procedure
\`\`\`bash
# OS upgrade process
dnf system-upgrade download --releasever=$(echo $target | grep -o '[0-9]*')
dnf system-upgrade reboot
\`\`\`"
fi)

**Checkpoint 5.1**: OS migration initiated  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

**Checkpoint 5.2**: System rebooted  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

**Checkpoint 5.3**: New OS verified  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**OS Version**: _______________  

### Step 6: Qubinode Collection Update (T+90 minutes)
\`\`\`bash
# Update Ansible environment
python3 -m pip install --upgrade ansible-core

# Update Qubinode collection
ansible-galaxy collection install community.qubinode --force

# Apply updated configuration
ansible-playbook -i inventory site.yml \\
  --extra-vars "migration_mode=true target_platform=$target"
\`\`\`

**Checkpoint 6.1**: Ansible updated  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

**Checkpoint 6.2**: Collection updated  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

**Checkpoint 6.3**: Configuration applied  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 7: Service Restoration (T+120 minutes)
\`\`\`bash
# Restart essential services
systemctl restart libvirtd
systemctl restart NetworkManager

# Verify service status
systemctl status libvirtd NetworkManager cockpit
\`\`\`

**Checkpoint 7.1**: Services restarted  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 8: Storage and Network Restoration (T+135 minutes)
\`\`\`bash
# Restore storage pools
virsh pool-autostart default
virsh pool-start default

# Restore network bridges
for bridge in \$(ip link show type bridge | grep -o 'br[0-9]*'); do
  ip link set \$bridge up
done
\`\`\`

**Checkpoint 8.1**: Storage pools active  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

**Checkpoint 8.2**: Network bridges up  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 9: Virtual Machine Startup (T+150 minutes)
\`\`\`bash
# Start VMs in order of priority
for vm in \$(virsh list --name --inactive); do
  echo "Starting \$vm..."
  virsh start "\$vm"
  sleep 30  # Allow VM to initialize
done
\`\`\`

**Checkpoint 9.1**: VMs started  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**VMs Started**: _____  

### Step 10: Validation Testing (T+180 minutes)
\`\`\`bash
# Run validation tests
ansible-playbook -i inventory post-migration-validation.yml
\`\`\`

**Checkpoint 10.1**: Validation completed  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**Test Results**: _____ passed, _____ failed  

## Issue Tracking

### Issues Encountered
| Time | Issue | Severity | Resolution | Status |
|------|--------|----------|------------|---------|
| ___:___ | _____________ | ⚠️/🔴 | _____________ | ⏳/✅ |

### Decision Log
| Time | Decision | Rationale | Approved By |
|------|----------|-----------|-------------|
| ___:___ | _____________ | _____________ | _____________ |

## Communication Updates

### Status Updates Sent
- [ ] **T+30**: Migration started
- [ ] **T+60**: VM shutdown completed
- [ ] **T+120**: OS migration completed
- [ ] **T+180**: Services restored
- [ ] **T+240**: Validation completed
- [ ] **Final**: Migration completed

## Final Verification

### Success Criteria Validation
- [ ] **Platform Migration**: System running $target_display
- [ ] **Service Availability**: All services operational
- [ ] **VM Functionality**: All VMs running and accessible
- [ ] **Network Connectivity**: All network bridges functional
- [ ] **Storage Access**: All storage pools accessible
- [ ] **Performance**: Performance within acceptable range
- [ ] **User Access**: User authentication and access working

### Performance Metrics
| Metric | Pre-Migration | Post-Migration | Variance |
|--------|---------------|----------------|----------|
| CPU Load | _____ | _____ | _____% |
| Memory Usage | _____ | _____ | _____% |
| Storage I/O | _____ | _____ | _____% |
| Network Throughput | _____ | _____ | _____% |

---

**Migration Completed**: ___:___  
**Total Duration**: _____ hours  
**Final Status**: ⏳ In Progress / ✅ Success / ❌ Failed  

**Execution Lead**: _______________  
**Sign-off**: _______________  
**Date**: _______________  

**Generated by**: Qubinode Migration Tools  
**Template Version**: 1.0
EOF

    log_success "Execution template generated: $output_file"
}

# Generate rollback template
generate_rollback_template() {
    local source="$1"
    local target="$2"
    local output_file="$3"
    
    local source_display=$(get_platform_display_name "$source")
    local target_display=$(get_platform_display_name "$target")
    
    cat > "$output_file" << 'EOF'
# Rollback Plan: ROLLBACK_TARGET → ROLLBACK_SOURCE

**Rollback Plan Created**: DATE_PLACEHOLDER  
**Migration Target**: MIGRATION_SOURCE → MIGRATION_TARGET  
**Rollback Scenario**: Emergency restoration to $source_display  

## Rollback Triggers

### Automatic Rollback Conditions
- [ ] **System Failure**: Any critical system component failure
- [ ] **Performance Degradation**: >25% performance decrease from baseline
- [ ] **Service Outage**: Any service unavailable for >30 minutes
- [ ] **Data Corruption**: Any indication of data loss or corruption
- [ ] **Security Breach**: Any security incident during migration

### Manual Rollback Conditions
- [ ] **Business Decision**: Stakeholder decision to abort migration
- [ ] **Timeline Overrun**: Migration exceeding planned window by >4 hours
- [ ] **Resource Exhaustion**: Team unable to continue due to fatigue/issues
- [ ] **Unexpected Complexity**: Discovery of unanticipated migration complexities

## Rollback Readiness

### Prerequisites (Verify before migration)
- [ ] **Full Backup**: Complete system backup with verified restore capability
- [ ] **VM Snapshots**: All VM configurations and data backed up
- [ ] **Configuration Backup**: All network, storage, and service configurations saved
- [ ] **Documentation**: Current system documentation up to date
- [ ] **Test Restore**: Rollback procedure tested in lab environment

### Rollback Window
- **Optimal Window**: Within 4 hours of migration start
- **Acceptable Window**: Within 12 hours of migration start  
- **Extended Window**: Up to 24 hours (requires additional approval)
- **Critical Window**: Beyond 24 hours (may require data recovery)

## Rollback Procedures

### Step 1: Rollback Decision (T+0 minutes)
\`\`\`bash
# Document rollback decision
echo "=== ROLLBACK INITIATED ==="
echo "Date: \$(date)"
echo "Decision Maker: $ROLLBACK_APPROVER"
echo "Trigger: $ROLLBACK_REASON"
echo "Migration Status at Rollback: $MIGRATION_STATUS"
\`\`\`

**Checkpoint R1.1**: Rollback decision documented  
**Time**: ___:___  
**Approved By**: _______________  
**Reason**: _______________  

### Step 2: Emergency Communications (T+5 minutes)
\`\`\`bash
# Notify stakeholders immediately
cat > rollback-notification.txt << 'EOF'
URGENT: Migration Rollback Initiated

Migration: $source_display → $target_display
Rollback Started: \$(date)
Reason: [TO BE FILLED]
Expected Duration: 2-4 hours
Status Updates: Every 30 minutes

Technical Contact: [TO BE FILLED]
Business Contact: [TO BE FILLED]
EOF
\`\`\`

**Checkpoint R2.1**: Stakeholders notified  
**Time**: ___:___  
**Notification Method**: _______________  

### Step 3: Environment Stabilization (T+10 minutes)
\`\`\`bash
# Stop all migration activities
pkill -f "ansible-playbook"
pkill -f "dnf system-upgrade"

# Prevent further changes
systemctl stop NetworkManager
systemctl stop libvirtd
\`\`\`

**Checkpoint R3.1**: Migration processes stopped  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 4: System Assessment (T+15 minutes)
\`\`\`bash
# Assess current system state
echo "=== SYSTEM STATE ASSESSMENT ==="
echo "OS Version: \$(cat /etc/os-release | grep VERSION_ID)"
echo "Kernel: \$(uname -r)"
echo "Boot Status: \$(systemctl is-system-running)"
echo "Disk Usage: \$(df -h /)"
echo "Memory: \$(free -h)"
echo "Network: \$(ip route show default)"
\`\`\`

**Checkpoint R4.1**: System state documented  
**Time**: ___:___  
**Assessment**: _______________  

### Step 5: Boot Environment Restoration (T+30 minutes)
$(if [[ "$source" == centos* ]]; then
echo "# CentOS restoration - may require installation media
\`\`\`bash
# Restore boot environment to CentOS
grub2-editenv - unset boot_success
grub2-reboot 0  # Boot to original kernel
\`\`\`"
else
echo "# Standard boot environment restoration
\`\`\`bash
# Restore previous kernel/OS
grub2-set-default 1  # Previous kernel entry
grub2-reboot 1
\`\`\`"
fi)

**Checkpoint R5.1**: Boot environment restored  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 6: System Reboot to Original OS (T+45 minutes)
\`\`\`bash
# Reboot to original system
echo "Rebooting to original OS..."
shutdown -r now
\`\`\`

**Checkpoint R6.1**: System rebooted  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

**Checkpoint R6.2**: Original OS booted  
**Time**: ___:___  
**OS Version**: _______________  

### Step 7: Service Restoration (T+60 minutes)
\`\`\`bash
# Restore original services
systemctl start NetworkManager
systemctl start libvirtd
systemctl start cockpit

# Verify service status
systemctl status NetworkManager libvirtd cockpit
\`\`\`

**Checkpoint R7.1**: Services restored  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 8: Configuration Restoration (T+75 minutes)
\`\`\`bash
# Restore original configurations
if [[ -f /backup/pre-migration/network-config.backup ]]; then
  cp /backup/pre-migration/network-config.backup /etc/NetworkManager/
fi

if [[ -f /backup/pre-migration/libvirt-config.backup ]]; then
  cp /backup/pre-migration/libvirt-config.backup /etc/libvirt/
fi
\`\`\`

**Checkpoint R8.1**: Configurations restored  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  

### Step 9: Virtual Machine Restoration (T+90 minutes)
\`\`\`bash
# Restore VM definitions
if [[ -d /backup/pre-migration/vm-definitions/ ]]; then
  for vm_xml in /backup/pre-migration/vm-definitions/*.xml; do
    virsh define "\$vm_xml"
  done
fi

# Start VMs
for vm in \$(virsh list --name --inactive); do
  virsh start "\$vm"
done
```

**Checkpoint R9.1**: VMs restored and started  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**VMs Restored**: _____  

### Step 10: Validation and Testing (T+120 minutes)
\`\`\`bash
# Validate rollback success
ansible-playbook -i inventory rollback-validation.yml
\`\`\`

**Checkpoint R10.1**: Rollback validation completed  
**Time**: ___:___  
**Status**: ⏳ / ✅ / ❌  
**Validation Results**: _______________  

## Data Recovery Procedures

### If Data Loss Detected
1. **Immediate Action**: Stop all write operations
2. **Assessment**: Determine scope of data loss
3. **Recovery**: Restore from most recent backup
4. **Validation**: Verify data integrity
5. **Communication**: Notify stakeholders of data recovery

### Backup Restoration
\`\`\`bash
# Restore from backup if needed
tar -xzf /backup/pre-migration/full-system-backup.tar.gz -C /
\`\`\`

## Post-Rollback Activities

### Immediate Tasks (Within 1 hour)
- [ ] **System Monitoring**: Monitor system stability
- [ ] **Performance Check**: Verify performance baselines
- [ ] **User Access**: Confirm user access restored
- [ ] **Service Verification**: Test all critical services

### Communication Tasks
- [ ] **Stakeholder Update**: Notify completion of rollback
- [ ] **User Communication**: Inform users of service restoration
- [ ] **Management Report**: Provide executive summary
- [ ] **Technical Debrief**: Schedule technical post-mortem

### Documentation Tasks
- [ ] **Incident Report**: Document rollback reasons and process
- [ ] **Lessons Learned**: Capture lessons for future migrations
- [ ] **Process Updates**: Update migration procedures based on learnings
- [ ] **Timeline Analysis**: Analyze actual vs. planned timeline

## Success Criteria for Rollback

### Technical Success
- [ ] **Original OS**: System running original $source_display
- [ ] **Service Availability**: All services operational
- [ ] **VM Functionality**: All VMs running normally
- [ ] **Network Connectivity**: Network bridges functional
- [ ] **Storage Access**: Storage pools accessible
- [ ] **Performance**: Performance at baseline levels

### Business Success
- [ ] **Service Continuity**: Business operations resumed
- [ ] **Data Integrity**: No data loss detected
- [ ] **User Satisfaction**: Users able to perform normal tasks
- [ ] **Timeline Met**: Rollback completed within planned window

## Risk Assessment Post-Rollback

### Identified Issues
| Issue | Impact | Resolution Required | Timeline |
|-------|---------|-------------------|----------|
| _____________ | _____ | _____________ | _____ |

### Recommendations for Future Migration
1. **Additional Testing**: Extend test environment validation
2. **Staging Approach**: Consider smaller test groups
3. **Timeline Adjustment**: Allow more time for migration
4. **Training Needs**: Additional team training identified
5. **Tool Updates**: Migration tools need enhancement

---

**Rollback Completed**: ___:___  
**Total Rollback Duration**: _____ hours  
**Final Status**: ⏳ In Progress / ✅ Success / ❌ Failed  

**Rollback Lead**: _______________  
**Business Approval**: _______________  
**Technical Sign-off**: _______________  
**Date**: _______________  

**Generated by**: Qubinode Migration Tools  
**Template Version**: 1.0
EOF

    log_success "Rollback template generated: $output_file"
}

# Main execution function
main() {
    log_info "🚀 Starting Migration Path Documentation Generation"
    
    validate_parameters
    
    local output_prefix="$OUTPUT_DIR/${SOURCE_PLATFORM}-to-${TARGET_PLATFORM}"
    
    # Generate templates based on type
    case "$TEMPLATE_TYPE" in
        "assessment")
            generate_assessment_template "$SOURCE_PLATFORM" "$TARGET_PLATFORM" "${output_prefix}-assessment.md"
            ;;
        "planning")
            generate_planning_template "$SOURCE_PLATFORM" "$TARGET_PLATFORM" "${output_prefix}-planning.md"
            ;;
        "execution")
            generate_execution_template "$SOURCE_PLATFORM" "$TARGET_PLATFORM" "${output_prefix}-execution.md"
            ;;
        "rollback")
            generate_rollback_template "$SOURCE_PLATFORM" "$TARGET_PLATFORM" "${output_prefix}-rollback.md"
            ;;
        "all")
            generate_assessment_template "$SOURCE_PLATFORM" "$TARGET_PLATFORM" "${output_prefix}-assessment.md"
            generate_planning_template "$SOURCE_PLATFORM" "$TARGET_PLATFORM" "${output_prefix}-planning.md"
            generate_execution_template "$SOURCE_PLATFORM" "$TARGET_PLATFORM" "${output_prefix}-execution.md"
            generate_rollback_template "$SOURCE_PLATFORM" "$TARGET_PLATFORM" "${output_prefix}-rollback.md"
            ;;
        *)
            log_error "Unknown template type: $TEMPLATE_TYPE"
            exit 1
            ;;
    esac
    
    log_success "✅ Migration documentation generation completed!"
    log_info "📁 Output directory: $OUTPUT_DIR"
    log_info "📋 Templates generated for: $(get_platform_display_name "$SOURCE_PLATFORM") → $(get_platform_display_name "$TARGET_PLATFORM")"
    
    echo ""
    echo "=== NEXT STEPS ==="
    echo "1. Review generated templates for accuracy"
    echo "2. Customize templates for your environment"
    echo "3. Test migration procedures in lab environment"
    echo "4. Schedule migration windows with stakeholders"
    echo "5. Execute migration following documented procedures"
}

# Execute main function
main "$@"
