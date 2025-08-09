#!/bin/bash

# =============================================================================
# Emergency Container Cleanup - The "Emergency Response Team"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This script provides emergency cleanup of stuck Molecule containers that can block
# CI/CD pipelines, acting as a last-resort recovery mechanism for container issues.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: Container Discovery - Identifies all Molecule-related containers
# 2. [PHASE 2]: Graceful Shutdown - Attempts to stop containers normally
# 3. [PHASE 3]: Forced Removal - Forcibly removes unresponsive containers
# 4. [PHASE 4]: Network Cleanup - Removes orphaned Molecule networks
# 5. [PHASE 5]: Image Cleanup - Prunes unused container images to free space
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Cleans: Containers created by molecule test runs in CI/CD pipelines
# - Targets: Rocky, AlmaLinux, RHEL containers used in testing scenarios
# - Prevents: Resource exhaustion on GitHub Actions runners
# - Enables: Recovery from stuck container states that block new test runs
# - Integrates: With GitHub Actions workflows as emergency recovery step
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - EMERGENCY: Designed for crisis situations when normal cleanup fails
# - COMPREHENSIVE: Removes containers, networks, and unused images
# - SAFETY: Uses multiple identification methods to ensure complete cleanup
# - AUTOMATION: Can be run manually or integrated into CI/CD recovery workflows
# - RESOURCE RECOVERY: Frees up system resources for subsequent test runs
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Container Names: Add patterns for new test container names
# - Additional Cleanup: Add cleanup for new resource types (volumes, secrets)
# - Safety Checks: Add validation to prevent cleanup of non-test containers
# - Logging: Enhance output for better troubleshooting and audit trails
# - Integration: Add hooks for notification systems or monitoring tools
#
# 🚨 IMPORTANT FOR LLMs: This is a DESTRUCTIVE script that forcibly removes containers.
# Only use when normal cleanup methods fail. It will remove ALL Molecule-related
# containers, including any with unsaved data. Always verify the environment first.

# Emergency cleanup script for stuck molecule containers
# Run this on the GitHub Actions runner if containers are stuck

echo "🚨 Emergency cleanup of stuck molecule containers..."

# Stop and remove all molecule-related containers
echo "🛑 Stopping all molecule containers..."
for container in $(podman ps -q --filter "label=molecule" 2>/dev/null || true); do
    echo "Stopping container: $container"
    podman stop "$container" 2>/dev/null || true
done

# Remove all molecule containers (running or stopped)
echo "🗑️ Removing all molecule containers..."
for container in $(podman ps -aq --filter "label=molecule" 2>/dev/null || true); do
    echo "Removing container: $container"
    podman rm -f "$container" 2>/dev/null || true
done

# Remove containers by name pattern (fallback)
echo "🗑️ Removing containers by name pattern..."
for name in rocky-9 alma-9 rhel-9 rhel-10; do
    container=$(podman ps -aq --filter "name=$name" 2>/dev/null || true)
    if [[ -n "$container" ]]; then
        echo "Removing $name container: $container"
        podman rm -f "$container" 2>/dev/null || true
    fi
done

# Clean up any molecule-specific networks
echo "🌐 Cleaning up molecule networks..."
for network in $(podman network ls --filter "name=molecule" --format "{{.Name}}" 2>/dev/null || true); do
    echo "Removing network: $network"
    podman network rm "$network" 2>/dev/null || true
done

# Clean up unused images
echo "🖼️ Cleaning up unused images..."
podman image prune -f 2>/dev/null || true

# Show final status
echo "📊 Final container status:"
podman ps -a

echo "✅ Emergency cleanup completed!"
