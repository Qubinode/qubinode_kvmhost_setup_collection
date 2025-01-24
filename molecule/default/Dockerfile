FROM quay.io/centos/centos:stream9

RUN dnf install -y dnf-plugins-core epel-release && \
    dnf config-manager --set-enabled crb && \
    dnf -y update && \
    dnf install -y \
    systemd \
    python3-pip \
    libvirt \
    libvirt-daemon-driver-qemu \
    libvirt-client \
    qemu-kvm \
    virt-install \
    python3-libvirt \
    systemd-container \
    procps-ng \
    iproute && \
    dnf clean all

RUN mkdir -p /var/run/libvirt/common /var/run/libvirt/qemu /var/lib/libvirt/qemu /var/lib/libvirt/images /run/libvirt && \
    chown -R root:libvirt /var/run/libvirt /var/lib/libvirt /run/libvirt && \
    chmod -R g+rwx /var/run/libvirt /var/lib/libvirt /run/libvirt

RUN systemctl enable virtqemud.socket virtlogd.socket

CMD ["/usr/sbin/init"]