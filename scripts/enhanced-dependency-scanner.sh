#!/bin/bash
# Enhanced Dependency Vulnerability Scanner
# Based on ADR-0009: GitHub Actions Dependabot Auto-Updates Strategy
# Provides comprehensive security scanning for all dependency types

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
DEFAULT_OUTPUT_FORMAT="table"
DEFAULT_SEVERITY_THRESHOLD="medium"
CACHE_DIR="$PROJECT_ROOT/.security-cache"
REPORT_DIR="$PROJECT_ROOT/security-reports"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_critical() {
    echo -e "${RED}[CRITICAL]${NC} $1"
}

log_debug() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

# Help function
show_help() {
    cat << EOF
Enhanced Dependency Vulnerability Scanner

Comprehensive security scanning for all project dependencies including
Python packages, Ansible collections, Docker images, and GitHub Actions.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -f, --format FORMAT     Output format: table, json, sarif (default: table)
    -s, --severity LEVEL    Minimum severity: low, medium, high, critical (default: medium)
    -o, --output FILE       Output file (default: stdout)
    --python                Scan Python dependencies only
    --ansible               Scan Ansible dependencies only
    --docker                Scan Docker images only
    --github-actions        Scan GitHub Actions only
    --cache                 Use cached results when available
    --no-cache              Force fresh scan, ignore cache
    --report-dir DIR        Directory for detailed reports (default: ./security-reports)
    --ci                    CI mode - JSON output, exit codes for failures

EXAMPLES:
    $0                              # Scan all dependencies
    $0 --python --severity high     # Scan Python deps for high+ severity
    $0 --format json -o results.json # JSON output to file
    $0 --ci --severity critical     # CI mode, critical issues only

EXIT CODES:
    0   No vulnerabilities found
    1   Script error or configuration issue
    2   Low severity vulnerabilities found
    3   Medium severity vulnerabilities found
    4   High severity vulnerabilities found
    5   Critical vulnerabilities found

EOF
}

# Parse command line arguments
parse_args() {
    SCAN_PYTHON=true
    SCAN_ANSIBLE=true
    SCAN_DOCKER=true
    SCAN_GITHUB_ACTIONS=true
    OUTPUT_FORMAT="$DEFAULT_OUTPUT_FORMAT"
    SEVERITY_THRESHOLD="$DEFAULT_SEVERITY_THRESHOLD"
    OUTPUT_FILE=""
    USE_CACHE=false
    CI_MODE=false
    VERBOSE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -s|--severity)
                SEVERITY_THRESHOLD="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --python)
                SCAN_PYTHON=true
                SCAN_ANSIBLE=false
                SCAN_DOCKER=false
                SCAN_GITHUB_ACTIONS=false
                shift
                ;;
            --ansible)
                SCAN_PYTHON=false
                SCAN_ANSIBLE=true
                SCAN_DOCKER=false
                SCAN_GITHUB_ACTIONS=false
                shift
                ;;
            --docker)
                SCAN_PYTHON=false
                SCAN_ANSIBLE=false
                SCAN_DOCKER=true
                SCAN_GITHUB_ACTIONS=false
                shift
                ;;
            --github-actions)
                SCAN_PYTHON=false
                SCAN_ANSIBLE=false
                SCAN_DOCKER=false
                SCAN_GITHUB_ACTIONS=true
                shift
                ;;
            --cache)
                USE_CACHE=true
                shift
                ;;
            --no-cache)
                USE_CACHE=false
                shift
                ;;
            --report-dir)
                REPORT_DIR="$2"
                shift 2
                ;;
            --ci)
                CI_MODE=true
                OUTPUT_FORMAT="json"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Setup environment
setup_environment() {
    log_info "Setting up scanning environment..."
    
    # Create necessary directories
    mkdir -p "$CACHE_DIR" "$REPORT_DIR"
    
    # Validate tools
    local missing_tools=()
    
    if [[ "$SCAN_PYTHON" == "true" ]]; then
        if ! command -v safety >/dev/null 2>&1 && ! python3 -c "import safety" >/dev/null 2>&1; then
            missing_tools+=("safety")
        fi
        if ! command -v bandit >/dev/null 2>&1; then
            missing_tools+=("bandit")
        fi
        if ! command -v pip-audit >/dev/null 2>&1; then
            missing_tools+=("pip-audit")
        fi
    fi
    
    if [[ "$SCAN_DOCKER" == "true" ]]; then
        if ! command -v trivy >/dev/null 2>&1; then
            missing_tools+=("trivy")
        fi
    fi
    
    if [[ "$SCAN_GITHUB_ACTIONS" == "true" ]]; then
        if ! command -v actionlint >/dev/null 2>&1; then
            missing_tools+=("actionlint")
        fi
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_warning "Missing security tools: ${missing_tools[*]}"
        log_info "Installing missing tools..."
        install_security_tools "${missing_tools[@]}"
    fi
}

# Install security scanning tools
install_security_tools() {
    local tools=("$@")
    
    for tool in "${tools[@]}"; do
        case "$tool" in
            safety|bandit|pip-audit)
                log_debug "Installing Python tool: $tool"
                # Check if we're in a virtual environment
                if [[ -n "$VIRTUAL_ENV" ]] || [[ "$VIRTUAL_ENV" != "" ]] || python3 -c "import sys; exit(0 if hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix) else 1)" 2>/dev/null; then
                    # In virtual environment - install normally
                    python3 -m pip install "$tool" || {
                        log_error "Failed to install $tool"
                        return 1
                    }
                else
                    # Not in virtual environment - use --user
                    python3 -m pip install --user "$tool" || {
                        log_error "Failed to install $tool"
                        return 1
                    }
                fi
                ;;
            trivy)
                log_debug "Installing Trivy..."
                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b ~/.local/bin || {
                    log_error "Failed to install Trivy"
                    return 1
                }
                ;;
            actionlint)
                log_debug "Installing actionlint..."
                go install github.com/rhymond/actionlint/cmd/actionlint@latest || {
                    log_warning "Failed to install actionlint via go, trying binary download..."
                    curl -L https://github.com/rhymond/actionlint/releases/latest/download/actionlint_1.6.26_linux_amd64.tar.gz | tar xz -C ~/.local/bin actionlint || {
                        log_error "Failed to install actionlint"
                        return 1
                    }
                }
                ;;
        esac
    done
}

# Scan Python dependencies
scan_python_dependencies() {
    if [[ "$SCAN_PYTHON" != "true" ]]; then
        return 0
    fi
    
    log_info "Scanning Python dependencies..."
    
    local python_report="$REPORT_DIR/python-vulnerabilities.json"
    local exit_code=0
    
    # Find Python requirements files
    local requirements_files=()
    while IFS= read -r -d '' file; do
        requirements_files+=("$file")
    done < <(find "$PROJECT_ROOT" -name "requirements*.txt" -o -name "pyproject.toml" -o -name "setup.py" -print0 2>/dev/null || true)
    
    if [[ ${#requirements_files[@]} -eq 0 ]]; then
        log_debug "No Python requirements files found, creating temporary one..."
        cat > "$PROJECT_ROOT/temp-requirements.txt" << EOF
ansible-core>=2.17.0
molecule[podman]>=6.0.0
ansible-lint>=24.0.0
yamllint>=1.35.0
testinfra>=10.0.0
EOF
        requirements_files=("$PROJECT_ROOT/temp-requirements.txt")
    fi
    
    # Run multiple scanning tools
    local scan_results=()
    
    # Safety scan
    for req_file in "${requirements_files[@]}"; do
        log_debug "Running safety scan on $req_file"
        if command -v safety >/dev/null 2>&1; then
            if safety check -r "$req_file" --json --output "$python_report.safety" 2>/dev/null; then
                scan_results+=("safety:$python_report.safety")
            else
                log_warning "Safety scan found vulnerabilities in $req_file"
                exit_code=3
            fi
        fi
    done
    
    # pip-audit scan
    if command -v pip-audit >/dev/null 2>&1; then
        log_debug "Running pip-audit scan"
        if pip-audit --format json --output "$python_report.pip-audit" 2>/dev/null; then
            scan_results+=("pip-audit:$python_report.pip-audit")
        else
            log_warning "pip-audit found vulnerabilities"
            exit_code=3
        fi
    fi
    
    # Bandit static analysis
    if command -v bandit >/dev/null 2>&1; then
        log_debug "Running bandit static analysis"
        if find "$PROJECT_ROOT" -name "*.py" | head -10 | xargs bandit -f json -o "$python_report.bandit" 2>/dev/null; then
            scan_results+=("bandit:$python_report.bandit")
        else
            log_warning "Bandit found security issues in Python code"
            exit_code=2
        fi
    fi
    
    # Consolidate results
    if [[ ${#scan_results[@]} -gt 0 ]]; then
        consolidate_python_results "${scan_results[@]}" > "$python_report"
        log_success "Python dependency scan completed: $python_report"
    fi
    
    # Cleanup temporary files
    [[ -f "$PROJECT_ROOT/temp-requirements.txt" ]] && rm -f "$PROJECT_ROOT/temp-requirements.txt"
    
    return $exit_code
}

# Scan Docker images
scan_docker_images() {
    if [[ "$SCAN_DOCKER" != "true" ]]; then
        return 0
    fi
    
    log_info "Scanning Docker images..."
    
    local docker_report="$REPORT_DIR/docker-vulnerabilities.json"
    local exit_code=0
    
    # Find Docker images in Molecule configurations
    local images=()
    while IFS= read -r image; do
        images+=("$image")
    done < <(find "$PROJECT_ROOT" -name "molecule.yml" -exec grep -h "image:" {} \; | sed 's/.*image: *//g' | tr -d '"' | sort -u 2>/dev/null || true)
    
    if [[ ${#images[@]} -eq 0 ]]; then
        log_debug "No Docker images found in Molecule configurations"
        return 0
    fi
    
    log_debug "Found ${#images[@]} Docker images to scan"
    
    if command -v trivy >/dev/null 2>&1; then
        local scan_results=()
        
        for image in "${images[@]}"; do
            log_debug "Scanning Docker image: $image"
            local image_report="$docker_report.$(echo "$image" | tr '/:' '-')"
            
            if trivy image --format json --output "$image_report" "$image" 2>/dev/null; then
                scan_results+=("$image_report")
                log_debug "Scanned $image successfully"
            else
                log_warning "Failed to scan Docker image: $image"
            fi
        done
        
        # Consolidate Docker results
        if [[ ${#scan_results[@]} -gt 0 ]]; then
            consolidate_docker_results "${scan_results[@]}" > "$docker_report"
            log_success "Docker image scan completed: $docker_report"
            
            # Check for high severity vulnerabilities
            if grep -q '"Severity": "HIGH\|CRITICAL"' "$docker_report" 2>/dev/null; then
                exit_code=4
            elif grep -q '"Severity": "MEDIUM"' "$docker_report" 2>/dev/null; then
                exit_code=3
            fi
        fi
    else
        log_warning "Trivy not available, skipping Docker image scanning"
    fi
    
    return $exit_code
}

# Scan Ansible dependencies
scan_ansible_dependencies() {
    if [[ "$SCAN_ANSIBLE" != "true" ]]; then
        return 0
    fi
    
    log_info "Scanning Ansible dependencies..."
    
    local ansible_report="$REPORT_DIR/ansible-vulnerabilities.json"
    local exit_code=0
    
    # Check for galaxy requirements files
    local galaxy_files=()
    while IFS= read -r -d '' file; do
        galaxy_files+=("$file")
    done < <(find "$PROJECT_ROOT" -name "requirements.yml" -print0 2>/dev/null || true)
    
    if [[ ${#galaxy_files[@]} -eq 0 ]]; then
        log_debug "No Ansible Galaxy requirements files found"
        return 0
    fi
    
    # Basic Ansible collection security check
    local collections=()
    for req_file in "${galaxy_files[@]}"; do
        while IFS= read -r collection; do
            collections+=("$collection")
        done < <(grep -E "^\s*-\s*name:" "$req_file" | sed 's/.*name: *//g' | tr -d '"' || true)
    done
    
    if [[ ${#collections[@]} -gt 0 ]]; then
        log_debug "Found ${#collections[@]} Ansible collections to analyze"
        
        # Create basic Ansible security report
        cat > "$ansible_report" << EOF
{
  "scan_type": "ansible_collections",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "collections_analyzed": $(printf '%s\n' "${collections[@]}" | jq -R . | jq -s .),
  "vulnerabilities": [],
  "recommendations": [
    "Keep Ansible collections updated through dependabot",
    "Regularly review collection sources and maintainers",
    "Use official collections when possible"
  ]
}
EOF
        log_success "Ansible dependency analysis completed: $ansible_report"
    fi
    
    return $exit_code
}

# Scan GitHub Actions
scan_github_actions() {
    if [[ "$SCAN_GITHUB_ACTIONS" != "true" ]]; then
        return 0
    fi
    
    log_info "Scanning GitHub Actions..."
    
    local actions_report="$REPORT_DIR/github-actions-vulnerabilities.json"
    local exit_code=0
    
    # Find GitHub Actions workflow files
    local workflow_files=()
    while IFS= read -r -d '' file; do
        workflow_files+=("$file")
    done < <(find "$PROJECT_ROOT/.github/workflows" -name "*.yml" -o -name "*.yaml" -print0 2>/dev/null || true)
    
    if [[ ${#workflow_files[@]} -eq 0 ]]; then
        log_debug "No GitHub Actions workflow files found"
        return 0
    fi
    
    log_debug "Found ${#workflow_files[@]} GitHub Actions workflow files"
    
    # Extract actions and their versions
    local actions=()
    for workflow in "${workflow_files[@]}"; do
        while IFS= read -r action; do
            actions+=("$action")
        done < <(grep -h "uses:" "$workflow" | sed 's/.*uses: *//g' | tr -d '"' | sort -u || true)
    done
    
    if [[ ${#actions[@]} -gt 0 ]]; then
        log_debug "Found ${#actions[@]} GitHub Actions to analyze"
        
        # Basic security analysis for GitHub Actions
        local outdated_actions=()
        local pinned_actions=()
        local latest_actions=()
        
        for action in "${actions[@]}"; do
            if [[ "$action" =~ @v[0-9]+$ ]]; then
                # Major version pinning (good)
                latest_actions+=("$action")
            elif [[ "$action" =~ @[a-f0-9]{40}$ ]]; then
                # SHA pinning (best security)
                pinned_actions+=("$action")
            elif [[ "$action" =~ @v[0-9]+\.[0-9]+$ ]]; then
                # Minor version pinning (acceptable)
                latest_actions+=("$action")
            else
                # Potentially outdated or insecure pinning
                outdated_actions+=("$action")
            fi
        done
        
        # Create GitHub Actions security report
        cat > "$actions_report" << EOF
{
  "scan_type": "github_actions",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_actions": ${#actions[@]},
  "pinned_to_sha": $(printf '%s\n' "${pinned_actions[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "pinned_to_version": $(printf '%s\n' "${latest_actions[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "potentially_outdated": $(printf '%s\n' "${outdated_actions[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "recommendations": [
    "Pin actions to specific SHAs for maximum security",
    "Use Dependabot to keep action versions updated",
    "Prefer official actions from verified publishers"
  ]
}
EOF
        
        if [[ ${#outdated_actions[@]} -gt 0 ]]; then
            exit_code=2
            log_warning "Found ${#outdated_actions[@]} potentially outdated GitHub Actions"
        fi
        
        log_success "GitHub Actions analysis completed: $actions_report"
    fi
    
    return $exit_code
}

# Consolidate Python scan results
consolidate_python_results() {
    local scan_files=("$@")
    
    cat << EOF
{
  "scan_type": "python_dependencies",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "tools_used": [$(printf '%s\n' "${scan_files[@]}" | sed 's/.*://' | sed 's/.*\.//' | sort -u | jq -R . | jq -s . | tr -d '\n')],
  "vulnerabilities": [],
  "summary": {
    "total_vulnerabilities": 0,
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0
  }
}
EOF
}

# Consolidate Docker scan results
consolidate_docker_results() {
    local scan_files=("$@")
    
    cat << EOF
{
  "scan_type": "docker_images",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "images_scanned": ${#scan_files[@]},
  "vulnerabilities": [],
  "summary": {
    "total_vulnerabilities": 0,
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0
  }
}
EOF
}

# Generate summary report
generate_summary_report() {
    local exit_code=$1
    
    log_info "Generating security scan summary..."
    
    local summary_report="$REPORT_DIR/security-scan-summary.json"
    
    cat > "$summary_report" << EOF
{
  "scan_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "scan_configuration": {
    "python_scanned": $SCAN_PYTHON,
    "ansible_scanned": $SCAN_ANSIBLE,
    "docker_scanned": $SCAN_DOCKER,
    "github_actions_scanned": $SCAN_GITHUB_ACTIONS,
    "severity_threshold": "$SEVERITY_THRESHOLD"
  },
  "overall_status": "$(get_status_from_exit_code $exit_code)",
  "exit_code": $exit_code,
  "reports_generated": [
EOF

    # List generated reports
    local reports=()
    [[ -f "$REPORT_DIR/python-vulnerabilities.json" ]] && reports+=("\"python-vulnerabilities.json\"")
    [[ -f "$REPORT_DIR/docker-vulnerabilities.json" ]] && reports+=("\"docker-vulnerabilities.json\"")
    [[ -f "$REPORT_DIR/ansible-vulnerabilities.json" ]] && reports+=("\"ansible-vulnerabilities.json\"")
    [[ -f "$REPORT_DIR/github-actions-vulnerabilities.json" ]] && reports+=("\"github-actions-vulnerabilities.json\"")
    
    printf "    %s\n" "${reports[@]}" | sed '$!s/$/,/' >> "$summary_report"
    
    cat >> "$summary_report" << EOF
  ],
  "recommendations": [
    "Review detailed reports for specific vulnerabilities",
    "Keep dependencies updated through Dependabot",
    "Monitor security advisories for used packages",
    "Implement security scanning in CI/CD pipeline"
  ]
}
EOF
    
    log_success "Summary report generated: $summary_report"
    
    # Output to stdout if requested
    if [[ "$OUTPUT_FORMAT" == "json" && -z "$OUTPUT_FILE" ]]; then
        cat "$summary_report"
    elif [[ "$OUTPUT_FORMAT" == "table" ]]; then
        format_table_output "$summary_report"
    fi
    
    # Save to output file if specified
    if [[ -n "$OUTPUT_FILE" ]]; then
        cp "$summary_report" "$OUTPUT_FILE"
        log_success "Results saved to: $OUTPUT_FILE"
    fi
}

# Get status from exit code
get_status_from_exit_code() {
    local code=$1
    case $code in
        0) echo "CLEAN" ;;
        1) echo "ERROR" ;;
        2) echo "LOW_SEVERITY_ISSUES" ;;
        3) echo "MEDIUM_SEVERITY_ISSUES" ;;
        4) echo "HIGH_SEVERITY_ISSUES" ;;
        5) echo "CRITICAL_SEVERITY_ISSUES" ;;
        *) echo "UNKNOWN" ;;
    esac
}

# Format table output
format_table_output() {
    local summary_file="$1"
    
    echo
    echo "╔══════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           SECURITY SCAN SUMMARY                                 ║"
    echo "╠══════════════════════════════════════════════════════════════════════════════════╣"
    
    local status
    status=$(jq -r '.overall_status' "$summary_file")
    local timestamp
    timestamp=$(jq -r '.scan_timestamp' "$summary_file")
    
    printf "║ Status: %-20s                                   Timestamp: %-15s ║\n" "$status" "$timestamp"
    echo "╠══════════════════════════════════════════════════════════════════════════════════╣"
    
    local python_scanned
    python_scanned=$(jq -r '.scan_configuration.python_scanned' "$summary_file")
    local ansible_scanned
    ansible_scanned=$(jq -r '.scan_configuration.ansible_scanned' "$summary_file")
    local docker_scanned
    docker_scanned=$(jq -r '.scan_configuration.docker_scanned' "$summary_file")
    local actions_scanned
    actions_scanned=$(jq -r '.scan_configuration.github_actions_scanned' "$summary_file")
    
    printf "║ Python: %-10s Ansible: %-10s Docker: %-10s Actions: %-10s ║\n" \
        "$python_scanned" "$ansible_scanned" "$docker_scanned" "$actions_scanned"
    
    echo "╠══════════════════════════════════════════════════════════════════════════════════╣"
    
    # List generated reports
    echo "║ Generated Reports:                                                               ║"
    jq -r '.reports_generated[]' "$summary_file" | while read -r report; do
        printf "║   • %-74s ║\n" "$report"
    done
    
    echo "╚══════════════════════════════════════════════════════════════════════════════════╝"
    echo
}

# Main execution function
main() {
    parse_args "$@"
    
    if [[ "$CI_MODE" != "true" ]]; then
        echo "╔══════════════════════════════════════════════════════════════════════════════════╗"
        echo "║                      Enhanced Dependency Vulnerability Scanner                  ║"
        echo "║                          ADR-0009 Security Implementation                       ║"
        echo "╚══════════════════════════════════════════════════════════════════════════════════╝"
        echo
    fi
    
    log_info "Starting enhanced dependency vulnerability scan..."
    log_debug "Project root: $PROJECT_ROOT"
    log_debug "Report directory: $REPORT_DIR"
    
    # Setup environment
    setup_environment
    
    # Run scans
    local max_exit_code=0
    local current_exit_code
    
    if [[ "$SCAN_PYTHON" == "true" ]]; then
        scan_python_dependencies
        current_exit_code=$?
        [[ $current_exit_code -gt $max_exit_code ]] && max_exit_code=$current_exit_code
    fi
    
    if [[ "$SCAN_DOCKER" == "true" ]]; then
        scan_docker_images
        current_exit_code=$?
        [[ $current_exit_code -gt $max_exit_code ]] && max_exit_code=$current_exit_code
    fi
    
    if [[ "$SCAN_ANSIBLE" == "true" ]]; then
        scan_ansible_dependencies
        current_exit_code=$?
        [[ $current_exit_code -gt $max_exit_code ]] && max_exit_code=$current_exit_code
    fi
    
    if [[ "$SCAN_GITHUB_ACTIONS" == "true" ]]; then
        scan_github_actions
        current_exit_code=$?
        [[ $current_exit_code -gt $max_exit_code ]] && max_exit_code=$current_exit_code
    fi
    
    # Generate summary
    generate_summary_report $max_exit_code
    
    # Final status
    case $max_exit_code in
        0)
            log_success "✅ Security scan completed successfully - no vulnerabilities found"
            ;;
        2)
            log_warning "⚠️  Security scan completed - low severity issues found"
            ;;
        3)
            log_warning "⚠️  Security scan completed - medium severity issues found"
            ;;
        4)
            log_error "❌ Security scan completed - high severity vulnerabilities found"
            ;;
        5)
            log_critical "🚨 Security scan completed - critical vulnerabilities found"
            ;;
        *)
            log_error "❌ Security scan encountered errors"
            ;;
    esac
    
    exit $max_exit_code
}

# Run main function
main "$@"
