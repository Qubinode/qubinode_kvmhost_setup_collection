#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[✓] $2${NC}"
    else
        echo -e "${RED}[✗] $2${NC}"
        exit 1
    fi
}

# Function to print info
print_info() {
    echo -e "${YELLOW}[i] $1${NC}"
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[✗] Please run as root${NC}"
    exit 1
fi

print_info "Validating libvirt environment for molecule tests..."

# Check if libvirt is installed
if ! command -v virsh &> /dev/null; then
    print_info "Installing libvirt packages..."
    dnf install -y libvirt libvirt-client qemu-kvm virt-manager virt-install
fi
print_status $? "Libvirt packages installed"

# Add current user to libvirt group
SUDO_USER=$(logname)
print_info "Adding user ${SUDO_USER} to libvirt group..."
usermod -aG libvirt ${SUDO_USER}
print_status $? "User added to libvirt group"

# Enable and start libvirt socket and service
print_info "Configuring libvirt services..."
systemctl enable --now libvirtd.socket
systemctl enable --now libvirtd.service
systemctl enable --now virtqemud.socket
systemctl enable --now virtqemud.service

# Wait for socket creation
print_info "Waiting for libvirt socket..."
for i in {1..10}; do
    if [ -S "/var/run/libvirt/libvirt-sock" ]; then
        break
    fi
    sleep 1
done

# Check if socket exists
if [ ! -S "/var/run/libvirt/libvirt-sock" ]; then
    print_info "Socket not found, attempting to create it..."
    systemctl restart libvirtd
    sleep 5
fi

if [ ! -S "/var/run/libvirt/libvirt-sock" ]; then
    print_status 1 "Failed to create libvirt socket"
fi

# Set socket permissions and SELinux context
print_info "Setting socket permissions and SELinux context..."
if [ -x "$(command -v getenforce)" ]; then
    # Temporarily set SELinux to permissive mode
    SELINUX_STATUS=$(getenforce)
    if [ "$SELINUX_STATUS" = "Enforcing" ]; then
        setenforce 0
        chmod 770 /var/run/libvirt/libvirt-sock
        chown root:libvirt /var/run/libvirt/libvirt-sock
        chcon -t virtd_t /var/run/libvirt/libvirt-sock
        setenforce 1
    else
        chmod 770 /var/run/libvirt/libvirt-sock
        chown root:libvirt /var/run/libvirt/libvirt-sock
        chcon -t virtd_t /var/run/libvirt/libvirt-sock
    fi
else
    chmod 770 /var/run/libvirt/libvirt-sock
    chown root:libvirt /var/run/libvirt/libvirt-sock
fi
print_status $? "Socket permissions and SELinux context set"

# Check if podman is installed
if ! command -v podman &> /dev/null; then
    print_info "Installing podman..."
    dnf install -y podman
fi
print_status $? "Podman is installed"

# Check if python3-libvirt is installed
if ! rpm -q python3-libvirt &> /dev/null; then
    print_info "Installing python3-libvirt..."
    dnf install -y python3-libvirt
fi
print_status $? "Python3-libvirt is installed"

# Check if ansible-galaxy is available
if ! command -v ansible-galaxy &> /dev/null; then
    print_info "Installing ansible..."
    dnf install -y ansible-core
fi
print_status $? "Ansible is installed"

# Install required Ansible collection
print_info "Installing community.libvirt collection..."
ansible-galaxy collection install community.libvirt &> /dev/null
print_status $? "Community.libvirt collection is installed"

# Test libvirt connection
print_info "Testing libvirt connection..."
sudo -u ${SUDO_USER} virsh list --all &> /dev/null
print_status $? "Can connect to libvirt"

# Verify podman can access libvirt socket
print_info "Testing podman access to libvirt socket..."
podman run --rm \
    --privileged \
    -v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
    registry.access.redhat.com/ubi9/ubi-init:latest \
    ls -l /var/run/libvirt/libvirt-sock &> /dev/null
print_status $? "Podman can access libvirt socket"

echo -e "\n${GREEN}Environment validation completed successfully!${NC}"
echo -e "${YELLOW}You can now run: molecule test${NC}"
echo -e "${YELLOW}Note: You may need to log out and back in for group changes to take effect${NC}"