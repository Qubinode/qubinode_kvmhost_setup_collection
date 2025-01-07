# Build stage
FROM quay.io/centos/centos:stream9 as builder

# Install required packages
RUN dnf install -y \
    ansible \
    python3-pip \
    libvirt-devel \
    && dnf clean all

# Install Ansible Galaxy requirements
COPY requirements.yml /requirements.yml
RUN ansible-galaxy install -r /requirements.yml

# Copy collection files
COPY . /qubinode-installer
WORKDIR /qubinode-installer

# Final stage
FROM quay.io/centos/centos:stream9

# Copy installed packages and collection
COPY --from=builder /usr /usr
COPY --from=builder /qubinode-installer /qubinode-installer

# Set working directory
WORKDIR /qubinode-installer

# Default command
ENTRYPOINT ["ansible-playbook"]
CMD ["-h"]
