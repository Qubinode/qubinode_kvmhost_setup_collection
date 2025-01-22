#!/bin/bash
set -euo pipefail

# Colors for output
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
  if [ $1 -eq 0 ]; then
    echo -e "${GREEN}[✓] $2${NC}"
  else
    echo -e "${RED}[✗] $2${NC}"
    exit 1
  fi
}

# Install base packages
echo -e "${YELLOW}[i] Installing base packages...${NC}"
sudo dnf install -y @"Virtualization Host" podman podman-docker gcc python3-devel \
    firewalld policycoreutils-python-utils nmap-ncat criu dlv gdb
print_status $? "Base packages installed"

# Configure Libvirt
echo -e "${YELLOW}[i] Configuring Libvirt...${NC}"
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER
sudo sed -i 's/^#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/' /etc/libvirt/libvirtd.conf
sudo sed -i 's/^#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/' /etc/libvirt/libvirtd.conf
print_status $? "Libvirt configured"

# Firewall Rules
echo -e "${YELLOW}[i] Configuring firewall...${NC}"
sudo systemctl start firewalld && systemctl status firewalld
sudo firewall-cmd --permanent --add-service=libvirt
sudo firewall-cmd --permanent --add-port=16509-16514/tcp
sudo firewall-cmd --reload
print_status $? "Firewall rules applied"

# SELinux Configuration
echo -e "${YELLOW}[i] Configuring SELinux...${NC}"
sudo semanage fcontext -a -t virt_image_t "/var/lib/libvirt/images(/.*)?"
sudo semanage fcontext -a -t container_file_t "/var/lib/containers(/.*)?"
sudo restorecon -Rv /var/lib/libvirt/images /var/lib/containers
sudo setsebool -P virt_use_nfs 1
print_status $? "SELinux configured"

# Podman Storage
echo -e "${YELLOW}[i] Configuring container storage...${NC}"
sudo mkdir -p /var/lib/containers/storage
sudo chmod 755 /var/lib/containers
print_status $? "Container storage ready"

# Python Environment
echo -e "${YELLOW}[i] Setting up Python dependencies...${NC}"
python3 -m pip install --user molecule molecule-plugins[podman] libvirt-python \
    ansible-lint==6.22.1 yamllint==1.35.1 pre-commit==3.6.1 pytest-ansible==4.1.0
print_status $? "Python dependencies installed"

# Debug Configuration
echo -e "${YELLOW}[i] Configuring debug environment...${NC}"
mkdir -p ~/.config/containers
echo -e "[containers]\nlog_level = 'debug'\n" > ~/.config/containers/containers.conf
cat << EOF > ansible_debug.cfg
[defaults]
stdout_callback = debug
retry_files_enabled = False
enable_task_debugger = True

[privilege_escalation]
become_allow_same_user = True
EOF
echo "export MOLECULE_PARALLEL=True" >> ~/.bashrc
echo "export MOLECULE_DESTROY=never" >> ~/.bashrc
print_status $? "Debug configuration applied"

# Ansible Collections
echo -e "${YELLOW}[i] Installing Ansible collections...${NC}"
ansible-galaxy collection install -f containers.podman community.libvirt
print_status $? "Collections installed"

echo -e "\n${GREEN}Setup complete! Log out and back in for group changes to take effect.${NC}"
