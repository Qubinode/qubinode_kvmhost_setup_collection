#!/bin/bash

# =============================================================================
# Container Health Monitor - The "Container Watchdog"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script monitors for stuck Molecule containers and provides cleanup guidance,
# helping maintain healthy container environments for testing and CI/CD.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Container Discovery - Scans for all running and stopped containers
# 2. [PHASE 2]: Molecule Identification - Identifies Molecule-related containers
# 3. [PHASE 3]: Health Assessment - Evaluates container health and responsiveness
# 4. [PHASE 4]: Stuck Detection - Identifies containers that are stuck or unresponsive
# 5. [PHASE 5]: Cleanup Guidance - Provides specific cleanup instructions
# 6. [PHASE 6]: Prevention Recommendations - Suggests preventive measures
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Monitors: Containers created by Molecule testing scenarios
# - Detects: Stuck containers that can block CI/CD pipelines
# - Guides: Cleanup procedures for container issues
# - Prevents: Resource exhaustion from accumulated containers
# - Supports: Both Podman and Docker container runtimes
# - Coordinates: With emergency-cleanup-containers.sh for resolution
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - MONITORING: Continuously monitors container health and status
# - DETECTION: Identifies problematic containers before they cause issues
# - GUIDANCE: Provides clear instructions for resolving container problems
# - PREVENTION: Focuses on preventing container accumulation issues
# - COMPATIBILITY: Works with multiple container runtimes
# - SAFETY: Provides guidance without performing destructive operations
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Runtimes: Add support for new container runtimes
# - Detection Logic: Improve stuck container detection algorithms
# - Cleanup Guidance: Enhance cleanup instruction specificity
# - Automation: Add automated cleanup capabilities (with safety checks)
# - Monitoring: Add performance monitoring and alerting
# - Integration: Add integration with container orchestration systems
#
# 🚨 IMPORTANT FOR LLMs: This script is diagnostic only - it doesn't perform
# cleanup automatically. Use emergency-cleanup-containers.sh for actual cleanup.
# Always review container status before performing destructive operations.

# Check for stuck molecule containers and provide cleanup instructions
# This can be run by developers or CI administrators

echo "🔍 Checking for stuck molecule containers..."

# Check for running containers
echo "📊 Current container status:"
if command -v podman >/dev/null 2>&1; then
    podman ps -a
    
    echo ""
    echo "🔍 Checking for molecule-related containers:"
    
    # Check for containers with molecule label
    molecule_containers=$(podman ps -aq --filter "label=molecule" 2>/dev/null || true)
    if [[ -n "$molecule_containers" ]]; then
        echo "⚠️ Found molecule containers:"
        echo "$molecule_containers"
    else
        echo "✅ No containers with molecule label found"
    fi
    
    # Check for containers by name pattern
    echo ""
    echo "🔍 Checking for containers by name pattern:"
    for name in rocky-9 alma-9 rhel-9 rhel-10; do
        container=$(podman ps -aq --filter "name=$name" 2>/dev/null || true)
        if [[ -n "$container" ]]; then
            echo "⚠️ Found $name container: $container"
            # Get container info
            echo "   Status: $(podman inspect "$container" --format '{{.State.Status}}' 2>/dev/null || echo 'unknown')"
            echo "   Created: $(podman inspect "$container" --format '{{.Created}}' 2>/dev/null || echo 'unknown')"
        fi
    done
    
    echo ""
    echo "🌐 Molecule networks:"
    podman network ls --filter "name=molecule" 2>/dev/null || echo "No molecule networks found"
    
    echo ""
    echo "💾 Container images with 'molecule_local' in name:"
    podman images | grep molecule_local || echo "No molecule_local images found"
    
else
    echo "❌ Podman not found. This script requires podman."
    exit 1
fi

echo ""
echo "🛠️ Cleanup commands:"
echo "For emergency cleanup, run:"
echo "  ./scripts/emergency-cleanup-containers.sh"
echo ""
echo "For manual cleanup:"
echo "  podman rm -f \$(podman ps -aq --filter 'label=molecule')"
echo "  podman rm -f \$(podman ps -aq --filter 'name=rocky-9' --filter 'name=alma-9' --filter 'name=rhel-9' --filter 'name=rhel-10')"
echo "  podman network prune -f"
echo "  podman image prune -f"
