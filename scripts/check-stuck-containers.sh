#!/bin/bash
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
