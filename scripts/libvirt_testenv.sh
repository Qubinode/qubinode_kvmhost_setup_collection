#!/bin/bash
# Validate virtualization support
virt-host-validate qemu

# Configure libvirt for current user
sudo usermod -aG libvirt $USER
sudo systemctl restart libvirtd

echo "Libvirt environment configured for user: $USER"
