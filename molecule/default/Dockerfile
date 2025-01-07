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
    python3 -m pip install "ansible>=2.13,<2.16" molecule podman
