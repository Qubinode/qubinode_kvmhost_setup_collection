#!/bin/bash

# =============================================================================
# Ansible Collection Update Checker - The "Collection Guardian"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script monitors Ansible collections for updates since Dependabot doesn't
# natively support Ansible Galaxy dependencies, filling the automation gap.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Collection Discovery - Finds all requirements.yml files
# 2. [PHASE 2]: Version Checking - Compares current vs latest versions
# 3. [PHASE 3]: Update Detection - Identifies collections needing updates
# 4. [PHASE 4]: PR Creation - Creates update PRs when needed
# 5. [PHASE 5]: Notification - Reports update status and recommendations
# 6. [PHASE 6]: Integration - Integrates with existing automation workflows

set -euo pipefail

# 📊 GLOBAL VARIABLES
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEMP_DIR="/tmp/ansible-updates-$$"
UPDATE_NEEDED=false

# 🎨 Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Cleanup function
cleanup() {
    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Create temp directory
mkdir -p "$TEMP_DIR"

# Function to get latest version of a collection
get_latest_version() {
    local collection="$1"
    local latest_version

    # Split collection name into namespace and name
    local namespace="${collection%%.*}"
    local name="${collection#*.}"

    # Query Ansible Galaxy API for latest version (try multiple API endpoints)
    latest_version=$(curl -s "https://galaxy.ansible.com/api/v3/collections/${namespace}/${name}/" | \
        jq -r '.highest_version.version' 2>/dev/null)

    # If that fails, try the v2 API
    if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
        latest_version=$(curl -s "https://galaxy.ansible.com/api/v2/collections/${namespace}/${name}/" | \
            jq -r '.latest_version.version' 2>/dev/null)
    fi

    # If still no result, try the search API
    if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
        latest_version=$(curl -s "https://galaxy.ansible.com/api/v3/collections/?name=${name}&namespace=${namespace}" | \
            jq -r '.data[0].highest_version.version' 2>/dev/null)
    fi

    # Default to unknown if all attempts fail
    if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
        latest_version="unknown"
    fi

    echo "$latest_version"
}

# Function to compare versions
version_greater() {
    local version1="$1"
    local version2="$2"
    
    # Remove >= prefix if present
    version1="${version1#>=}"
    version2="${version2#>=}"
    
    # Simple version comparison (works for most semantic versions)
    if [[ "$version1" == "$version2" ]]; then
        return 1  # Equal, not greater
    fi
    
    # Use sort -V for version comparison
    if [[ "$(printf '%s\n%s\n' "$version1" "$version2" | sort -V | head -n1)" == "$version1" ]]; then
        return 1  # version1 is less than version2
    else
        return 0  # version1 is greater than version2
    fi
}

# Function to check collections in a requirements file
check_requirements_file() {
    local req_file="$1"
    local updates_found=false
    
    log_info "Checking $req_file..."
    
    if [[ ! -f "$req_file" ]]; then
        log_warning "Requirements file not found: $req_file"
        return
    fi
    
    # Extract collections from YAML (simple parsing)
    local collections
    collections=$(yq eval '.collections[].name' "$req_file" 2>/dev/null || echo "")
    
    if [[ -z "$collections" ]]; then
        log_info "No collections found in $req_file"
        return
    fi
    
    echo "📦 Collections in $req_file:"
    
    while IFS= read -r collection; do
        if [[ -n "$collection" && "$collection" != "null" ]]; then
            local current_version latest_version
            
            # Get current version requirement
            current_version=$(yq eval ".collections[] | select(.name == \"$collection\") | .version" "$req_file" 2>/dev/null || echo "")
            
            # Get latest version from Galaxy
            latest_version=$(get_latest_version "$collection")
            
            if [[ "$latest_version" == "unknown" ]]; then
                log_warning "  $collection: Could not fetch latest version"
                continue
            fi
            
            # Clean up version strings for comparison
            current_clean="${current_version#>=}"
            
            echo "  📋 $collection:"
            echo "    Current: $current_version"
            echo "    Latest:  $latest_version"
            
            # Check if update is needed
            if [[ -n "$current_clean" ]] && version_greater "$latest_version" "$current_clean"; then
                log_warning "    🔄 UPDATE AVAILABLE: $current_version → $latest_version"
                updates_found=true
                UPDATE_NEEDED=true
                
                # Store update info
                echo "$collection,$current_version,$latest_version,$req_file" >> "$TEMP_DIR/updates.csv"
            else
                log_success "    ✅ Up to date"
            fi
            
            echo
        fi
    done <<< "$collections"
    
    if [[ "$updates_found" == "true" ]]; then
        log_warning "Updates available in $req_file"
    else
        log_success "All collections up to date in $req_file"
    fi
}

# Function to create update PR
create_update_pr() {
    local updates_file="$TEMP_DIR/updates.csv"
    
    if [[ ! -f "$updates_file" ]]; then
        log_info "No updates to process"
        return
    fi
    
    log_info "Creating update PR..."
    
    # Create branch name
    local branch_name="ansible-collections-update-$(date +%Y%m%d-%H%M%S)"
    
    # Create new branch
    git checkout -b "$branch_name"
    
    # Process updates
    local pr_body="## 📦 Ansible Collections Updates\n\nThis PR updates Ansible collections to their latest versions:\n\n"
    
    while IFS=',' read -r collection current_version latest_version req_file; do
        log_info "Updating $collection in $req_file"
        
        # Update the requirements file
        yq eval "(.collections[] | select(.name == \"$collection\") | .version) = \">=$latest_version\"" -i "$req_file"
        
        pr_body+="\n- **$collection**: $current_version → >=$latest_version (in $req_file)"
        
    done < "$updates_file"
    
    # Add changes
    git add requirements.yml roles/kvmhost_setup/collection/requirements.yml
    
    # Commit changes
    git commit -m "deps: Update Ansible collections to latest versions

🔄 Automated update of Ansible collections:
$(cat "$updates_file" | while IFS=',' read -r collection current latest file; do
    echo "- $collection: $current → >=$latest"
done)

🤖 This update ensures we have the latest security fixes and features
from Ansible Galaxy collections."
    
    # Push branch
    git push origin "$branch_name"
    
    # Create PR using gh CLI
    if command -v gh &> /dev/null; then
        gh pr create \
            --title "deps: Update Ansible collections to latest versions" \
            --body "$pr_body" \
            --label "dependencies,ansible" \
            --assignee "@me"
        
        log_success "PR created successfully!"
    else
        log_warning "GitHub CLI not available. Please create PR manually for branch: $branch_name"
    fi
}

# Function to install yq if not available
install_yq() {
    log_info "Installing yq..."

    # Detect OS and install yq accordingly
    if command -v dnf &> /dev/null; then
        # RHEL/CentOS/Fedora with dnf
        log_info "Installing yq via dnf..."
        sudo dnf install -y yq || {
            log_warning "dnf install failed, trying direct download..."
            install_yq_direct
        }
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS with yum
        log_info "Installing yq via yum..."
        sudo yum install -y yq || {
            log_warning "yum install failed, trying direct download..."
            install_yq_direct
        }
    elif command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        log_info "Installing yq via apt..."
        sudo apt-get update && sudo apt-get install -y yq || {
            log_warning "apt install failed, trying direct download..."
            install_yq_direct
        }
    else
        log_info "Package manager not detected, using direct download..."
        install_yq_direct
    fi
}

# Function to install yq directly from GitHub
install_yq_direct() {
    log_info "Installing yq from GitHub releases..."

    # Create local bin directory if it doesn't exist
    mkdir -p "$HOME/.local/bin"

    # Download yq binary
    curl -L "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" \
        -o "$HOME/.local/bin/yq"

    # Make executable
    chmod +x "$HOME/.local/bin/yq"

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        log_info "Added $HOME/.local/bin to PATH for this session"
    fi

    # Verify installation
    if command -v yq &> /dev/null; then
        log_success "yq installed successfully to $HOME/.local/bin/yq"
    else
        log_error "Failed to install yq"
        exit 1
    fi
}

# Function to install jq if not available
install_jq() {
    log_info "Installing jq..."

    if command -v dnf &> /dev/null; then
        sudo dnf install -y jq
    elif command -v yum &> /dev/null; then
        sudo yum install -y jq
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y jq
    else
        log_error "Cannot install jq - unsupported package manager"
        exit 1
    fi
}

# Main execution
main() {
    log_info "🔍 Checking Ansible collection updates..."

    # Check and install required tools
    if ! command -v yq &> /dev/null; then
        log_warning "yq not found, attempting to install..."
        install_yq
    fi

    if ! command -v jq &> /dev/null; then
        log_warning "jq not found, attempting to install..."
        install_jq
    fi

    # Verify tools are now available
    if ! command -v yq &> /dev/null; then
        log_error "yq is still not available after installation attempt"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_error "jq is still not available after installation attempt"
        exit 1
    fi

    log_success "All required tools are available"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Check main requirements file
    check_requirements_file "requirements.yml"
    
    # Check collection-specific requirements
    check_requirements_file "roles/kvmhost_setup/collection/requirements.yml"
    
    # Summary
    echo
    log_info "📊 Update Summary:"
    if [[ "$UPDATE_NEEDED" == "true" ]]; then
        log_warning "Updates are available for Ansible collections"
        
        # Show summary
        if [[ -f "$TEMP_DIR/updates.csv" ]]; then
            echo
            log_info "Available updates:"
            while IFS=',' read -r collection current latest file; do
                echo "  🔄 $collection: $current → $latest (in $file)"
            done < "$TEMP_DIR/updates.csv"
        fi
        
        # Ask if user wants to create PR
        if [[ "${1:-}" == "--create-pr" ]]; then
            create_update_pr
        else
            echo
            log_info "To create an update PR, run: $0 --create-pr"
        fi
        
        exit 1  # Exit with error code to indicate updates needed
    else
        log_success "All Ansible collections are up to date!"
        exit 0
    fi
}

# Show usage
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
🔍 Ansible Collection Update Checker

Usage: $0 [OPTIONS]

OPTIONS:
    --create-pr    Create a PR with available updates
    --help, -h     Show this help message

EXAMPLES:
    $0                 # Check for updates
    $0 --create-pr     # Check and create PR if updates available

This script checks Ansible collections in requirements.yml files
against the latest versions available on Ansible Galaxy.
EOF
    exit 0
fi

# Execute main function
main "$@"
