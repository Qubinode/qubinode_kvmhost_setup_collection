FROM docker.io/rockylinux/rockylinux:9-ubi-init

# Install required packages
RUN dnf install -y sudo python3 python3-pip openssh-clients podman slirp4netns && \
    dnf clean all

# Create molecule user
RUN useradd -m -s /bin/bash molecule && \
    echo "molecule ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/molecule && \
    chmod 0440 /etc/sudoers.d/molecule

# Install Ansible and dependencies
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install "ansible-core>=2.18.0" molecule podman requests && \
    ansible-galaxy collection install ansible.posix community.general community.libvirt fedora.linux_system_roles ansible.netcommon && \
    ansible-galaxy role install linux-system-roles.network || true
