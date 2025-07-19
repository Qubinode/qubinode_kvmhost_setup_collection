#!/bin/bash
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
