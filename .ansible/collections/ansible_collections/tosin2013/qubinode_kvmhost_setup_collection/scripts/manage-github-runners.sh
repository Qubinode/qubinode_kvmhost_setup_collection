#!/bin/bash

# GitHub Runner Management Script
# Manages multiple self-hosted runners for different purposes

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/runner-config.yml"
DEFAULT_RUNNER_USER="github-runner"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

# Check if yq is available for YAML parsing
check_dependencies() {
    if ! command -v yq &> /dev/null; then
        warn "yq not found, installing..."
        if [[ -f /etc/redhat-release ]]; then
            sudo yum install -y yq
        else
            sudo apt-get update && sudo apt-get install -y yq
        fi
    fi
}

# List all configured runners
list_runners() {
    info "Configured GitHub Runners:"
    echo
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        warn "No configuration file found at $CONFIG_FILE"
        return 1
    fi
    
    yq eval '.runners[] | "Name: " + .name + " | User: " + .user + " | Labels: " + (.labels | join(",")) + " | Status: " + .status' "$CONFIG_FILE"
}

# Show runner status
show_status() {
    local runner_name="${1:-}"
    
    if [[ -n "$runner_name" ]]; then
        # Show specific runner status
        local user=$(yq eval ".runners[] | select(.name == \"$runner_name\") | .user" "$CONFIG_FILE")
        if [[ "$user" == "null" ]]; then
            error "Runner '$runner_name' not found in configuration"
            return 1
        fi
        
        info "Status for runner: $runner_name"
        sudo systemctl status "github-runner-$runner_name" 2>/dev/null || \
            sudo systemctl status github-runner 2>/dev/null || \
            echo "Service not found or not running"
    else
        # Show all runners
        info "All runner services status:"
        for service in $(systemctl list-units --type=service --state=loaded github-runner* --no-legend | cut -d' ' -f1); do
            echo "📋 $service:"
            systemctl is-active "$service" && echo "  Status: Active" || echo "  Status: Inactive"
        done
    fi
}

# Start runner service
start_runner() {
    local runner_name="${1:-github-runner}"
    local service_name="github-runner"
    
    if [[ "$runner_name" != "github-runner" ]]; then
        service_name="github-runner-$runner_name"
    fi
    
    info "Starting runner service: $service_name"
    sudo systemctl start "$service_name"
    sudo systemctl enable "$service_name"
    success "Runner $runner_name started"
}

# Stop runner service
stop_runner() {
    local runner_name="${1:-github-runner}"
    local service_name="github-runner"
    
    if [[ "$runner_name" != "github-runner" ]]; then
        service_name="github-runner-$runner_name"
    fi
    
    info "Stopping runner service: $service_name"
    sudo systemctl stop "$service_name"
    success "Runner $runner_name stopped"
}

# Restart runner service
restart_runner() {
    local runner_name="${1:-github-runner}"
    stop_runner "$runner_name"
    sleep 2
    start_runner "$runner_name"
}

# Show runner logs
show_logs() {
    local runner_name="${1:-github-runner}"
    local service_name="github-runner"
    
    if [[ "$runner_name" != "github-runner" ]]; then
        service_name="github-runner-$runner_name"
    fi
    
    info "Showing logs for: $service_name"
    journalctl -u "$service_name" -f
}

# Create a new runner configuration
create_runner_config() {
    local name="$1"
    local labels="$2"
    local user="${3:-$DEFAULT_RUNNER_USER}"
    
    info "Creating runner configuration: $name"
    
    # Create config file if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
# GitHub Runner Configuration
# This file manages multiple self-hosted runners

runners: []
EOF
    fi
    
    # Add runner to config
    yq eval -i ".runners += [{\"name\": \"$name\", \"user\": \"$user\", \"labels\": $(echo "$labels" | tr ',' '\n' | yq eval -n '[inputs]'), \"status\": \"configured\", \"created\": \"$(date -Iseconds)\"}]" "$CONFIG_FILE"
    
    success "Runner $name added to configuration"
}

# Register a new runner
register_runner() {
    local repo_url="$1"
    local token="$2"
    local runner_name="${3:-$(hostname)-runner}"
    local labels="${4:-self-hosted,linux,$(uname -m),ansible}"
    
    info "Registering new runner: $runner_name"
    
    # Check if setup script exists
    local setup_script="${SCRIPT_DIR}/setup-github-runner.sh"
    if [[ ! -f "$setup_script" ]]; then
        error "Setup script not found: $setup_script"
        error "Please run the setup script first"
        return 1
    fi
    
    # Create runner configuration
    create_runner_config "$runner_name" "$labels"
    
    # Register with GitHub
    local user=$(yq eval ".runners[] | select(.name == \"$runner_name\") | .user" "$CONFIG_FILE")
    sudo -u "$user" bash << EOF
cd "/home/$user/actions-runner"
source ~/.runner-env
./config.sh \\
    --url "$repo_url" \\
    --token "$token" \\
    --name "$runner_name" \\
    --labels "$labels" \\
    --work "_work" \\
    --replace
EOF
    
    # Update configuration status
    yq eval -i "(.runners[] | select(.name == \"$runner_name\") | .status) = \"registered\"" "$CONFIG_FILE"
    yq eval -i "(.runners[] | select(.name == \"$runner_name\") | .registered) = \"$(date -Iseconds)\"" "$CONFIG_FILE"
    
    success "Runner $runner_name registered successfully"
}

# Remove a runner
remove_runner() {
    local runner_name="$1"
    local token="${2:-}"
    
    info "Removing runner: $runner_name"
    
    # Get user from config
    local user=$(yq eval ".runners[] | select(.name == \"$runner_name\") | .user" "$CONFIG_FILE")
    if [[ "$user" == "null" ]]; then
        error "Runner '$runner_name' not found in configuration"
        return 1
    fi
    
    # Stop service
    stop_runner "$runner_name" 2>/dev/null || true
    
    # Remove from GitHub if token provided
    if [[ -n "$token" ]]; then
        sudo -u "$user" bash << EOF
cd "/home/$user/actions-runner"
./config.sh remove --token "$token"
EOF
    else
        warn "No token provided, runner may still be registered on GitHub"
    fi
    
    # Remove from configuration
    yq eval -i "del(.runners[] | select(.name == \"$runner_name\"))" "$CONFIG_FILE"
    
    success "Runner $runner_name removed"
}

# Health check for all runners
health_check() {
    info "Performing health check on all runners..."
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        warn "No configuration file found"
        return 1
    fi
    
    local healthy=0
    local total=0
    
    while IFS= read -r runner_name; do
        if [[ "$runner_name" == "null" ]]; then continue; fi
        
        total=$((total + 1))
        
        echo "🔍 Checking runner: $runner_name"
        
        # Check service status
        local service_name="github-runner"
        if [[ "$runner_name" != "github-runner" ]]; then
            service_name="github-runner-$runner_name"
        fi
        
        if systemctl is-active "$service_name" &>/dev/null; then
            echo "  ✅ Service: Active"
            healthy=$((healthy + 1))
        else
            echo "  ❌ Service: Inactive"
        fi
        
        # Check user environment
        local user=$(yq eval ".runners[] | select(.name == \"$runner_name\") | .user" "$CONFIG_FILE")
        if sudo -u "$user" bash -c "source ~/.runner-env && ansible --version" &>/dev/null; then
            echo "  ✅ Ansible: Available"
        else
            echo "  ❌ Ansible: Missing or broken"
        fi
        
        # Check container runtime
        if sudo -u "$user" bash -c "podman --version" &>/dev/null; then
            echo "  ✅ Podman: Available"
        else
            echo "  ❌ Podman: Missing"
        fi
        
        echo
    done < <(yq eval '.runners[].name' "$CONFIG_FILE")
    
    echo "📊 Health Summary: $healthy/$total runners healthy"
    
    if [[ $healthy -eq $total ]]; then
        success "All runners are healthy"
        return 0
    else
        warn "Some runners need attention"
        return 1
    fi
}

# Update runner configuration
update_config() {
    info "Updating runner configurations..."
    
    # Check for updates to the setup script
    local setup_script="${SCRIPT_DIR}/setup-github-runner.sh"
    if [[ -f "$setup_script" ]]; then
        info "Running verification check..."
        bash "$setup_script" verify
    fi
    
    # Update configuration file timestamp
    yq eval -i ".last_updated = \"$(date -Iseconds)\"" "$CONFIG_FILE"
    
    success "Configuration updated"
}

# Show help
show_help() {
    cat << EOF
GitHub Runner Management Script

Usage: $0 <command> [options]

Commands:
  list                          - List all configured runners
  status [runner_name]          - Show runner service status
  start <runner_name>           - Start a runner service
  stop <runner_name>            - Stop a runner service
  restart <runner_name>         - Restart a runner service
  logs <runner_name>            - Show runner logs
  register <repo_url> <token> [name] [labels] - Register a new runner
  remove <runner_name> [token]  - Remove a runner
  health                        - Perform health check on all runners
  update                        - Update runner configurations
  help                          - Show this help

Examples:
  $0 list
  $0 status main-runner
  $0 register https://github.com/owner/repo ghs_token123 ansible-runner "self-hosted,ansible,podman"
  $0 remove ansible-runner ghs_token123
  $0 health

Configuration file: $CONFIG_FILE
EOF
}

# Main execution
main() {
    local command="${1:-help}"
    
    case "$command" in
        "list")
            check_dependencies
            list_runners
            ;;
        "status")
            show_status "${2:-}"
            ;;
        "start")
            if [[ -z "${2:-}" ]]; then
                error "Runner name required"
                exit 1
            fi
            start_runner "$2"
            ;;
        "stop")
            if [[ -z "${2:-}" ]]; then
                error "Runner name required"
                exit 1
            fi
            stop_runner "$2"
            ;;
        "restart")
            if [[ -z "${2:-}" ]]; then
                error "Runner name required"
                exit 1
            fi
            restart_runner "$2"
            ;;
        "logs")
            if [[ -z "${2:-}" ]]; then
                error "Runner name required"
                exit 1
            fi
            show_logs "$2"
            ;;
        "register")
            if [[ -z "${2:-}" || -z "${3:-}" ]]; then
                error "Repository URL and token required"
                echo "Usage: $0 register <repo_url> <token> [name] [labels]"
                exit 1
            fi
            check_dependencies
            register_runner "$2" "$3" "${4:-$(hostname)-runner}" "${5:-self-hosted,linux,$(uname -m),ansible}"
            ;;
        "remove")
            if [[ -z "${2:-}" ]]; then
                error "Runner name required"
                exit 1
            fi
            check_dependencies
            remove_runner "$2" "${3:-}"
            ;;
        "health")
            check_dependencies
            health_check
            ;;
        "update")
            check_dependencies
            update_config
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
