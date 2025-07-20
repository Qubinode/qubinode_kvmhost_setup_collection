#!/bin/bash
# RHEL 10 Virtualization Package Availability Checker
# This script checks if RHEL 10 virtualization packages are available

set -euo pipefail

# Configuration
RHEL10_IMAGE="${RHEL10_IMAGE:-registry.redhat.io/ubi10-init:latest}"
PACKAGES=("libvirt" "qemu-kvm" "virt-manager" "libvirt-daemon-kvm" "virt-install" "libguestfs-tools" "cockpit" "NetworkManager")
OUTPUT_FILE="${1:-rhel10-package-status.json}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 RHEL 10 Virtualization Package Availability Checker${NC}"
echo -e "${BLUE}=================================================${NC}"
echo "Image: $RHEL10_IMAGE"
echo "Date: $(date)"
echo "Output: $OUTPUT_FILE"
echo ""

# Initialize counters
AVAILABLE_COUNT=0
TOTAL_PACKAGES=${#PACKAGES[@]}
AVAILABLE_PACKAGES=()
UNAVAILABLE_PACKAGES=()

# JSON output initialization
cat > "$OUTPUT_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "image": "$RHEL10_IMAGE",
  "total_packages": $TOTAL_PACKAGES,
  "packages": {
EOF

# Check each package with detailed error reporting
FIRST_PACKAGE=true
for package in "${PACKAGES[@]}"; do
    echo -n "Checking $package: "

    # Add comma for JSON formatting (except first entry)
    if [ "$FIRST_PACKAGE" = true ]; then
        FIRST_PACKAGE=false
    else
        echo "," >> "$OUTPUT_FILE"
    fi

    # Capture detailed error information
    ERROR_OUTPUT=$(podman run --rm "$RHEL10_IMAGE" dnf list available "$package" 2>&1)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ AVAILABLE${NC}"
        AVAILABLE_PACKAGES+=("$package")
        ((AVAILABLE_COUNT++))
        echo -n "    \"$package\": {\"available\": true, \"status\": \"available\", \"details\": \"Package found in repositories\"}" >> "$OUTPUT_FILE"
    else
        echo -e "${RED}❌ Not available${NC}"
        UNAVAILABLE_PACKAGES+=("$package")

        # Analyze the error to provide specific issue details
        if echo "$ERROR_OUTPUT" | grep -q "No matching packages"; then
            ISSUE_DETAIL="Package not found in any available repositories"
        elif echo "$ERROR_OUTPUT" | grep -q "Error:"; then
            ISSUE_DETAIL="Repository error: $(echo "$ERROR_OUTPUT" | grep "Error:" | head -1 | sed 's/Error: //')"
        elif echo "$ERROR_OUTPUT" | grep -q "subscription-manager"; then
            ISSUE_DETAIL="Subscription/repository access issue - container mode limitations"
        else
            ISSUE_DETAIL="Unknown availability issue"
        fi

        echo -n "    \"$package\": {\"available\": false, \"status\": \"not_available\", \"issue\": \"$ISSUE_DETAIL\", \"error_output\": \"$(echo "$ERROR_OUTPUT" | tr '\n' ' ' | sed 's/"/\\"/g')\"}" >> "$OUTPUT_FILE"
    fi
done

# Complete JSON output
cat >> "$OUTPUT_FILE" << EOF

  },
  "summary": {
    "available_count": $AVAILABLE_COUNT,
    "unavailable_count": $((TOTAL_PACKAGES - AVAILABLE_COUNT)),
    "percentage_available": $(( (AVAILABLE_COUNT * 100) / TOTAL_PACKAGES )),
    "ready_for_production": $([ $AVAILABLE_COUNT -ge 6 ] && echo "true" || echo "false"),
    "ready_for_pr": $([ $AVAILABLE_COUNT -ge 3 ] && echo "true" || echo "false")
  },
  "available_packages": [$(printf '"%s",' "${AVAILABLE_PACKAGES[@]}" | sed 's/,$//')]
  "unavailable_packages": [$(printf '"%s",' "${UNAVAILABLE_PACKAGES[@]}" | sed 's/,$//')]
}
EOF

# Generate detailed repository analysis
echo ""
echo -e "${BLUE}🔍 Repository Analysis:${NC}"
REPO_INFO=$(podman run --rm "$RHEL10_IMAGE" dnf repolist -v 2>/dev/null | grep -E "(Repo-id|Repo-pkgs|Repo-size)" || echo "Repository information unavailable")
echo "$REPO_INFO"

echo ""
echo -e "${BLUE}📊 Package Analysis Summary:${NC}"
echo -e "Available packages: ${GREEN}$AVAILABLE_COUNT${NC}/${TOTAL_PACKAGES}"
echo -e "Percentage: ${YELLOW}$(( (AVAILABLE_COUNT * 100) / TOTAL_PACKAGES ))%${NC}"

if [ ${#UNAVAILABLE_PACKAGES[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ Unavailable Packages and Issues:${NC}"
    for package in "${UNAVAILABLE_PACKAGES[@]}"; do
        echo -e "  • ${RED}$package${NC}: Not found in UBI repositories"
    done
    echo ""
    echo -e "${YELLOW}💡 Common Reasons for Package Unavailability:${NC}"
    echo -e "  • UBI containers only include minimal package sets"
    echo -e "  • Virtualization packages require full RHEL subscription"
    echo -e "  • Packages may be in different repositories not available in containers"
    echo -e "  • Some packages are only available on physical/VM systems"
fi

if [ $AVAILABLE_COUNT -ge 6 ]; then
    echo -e "Status: ${GREEN}🎉 Ready for production deployment!${NC}"
    exit 0
elif [ $AVAILABLE_COUNT -ge 3 ]; then
    echo -e "Status: ${YELLOW}⚡ Ready for PR creation (partial support)${NC}"
    exit 0
else
    echo -e "Status: ${RED}⏳ Waiting for more packages...${NC}"
    exit 1
fi
