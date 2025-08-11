# Supported Platforms Reference

Complete reference for platform compatibility, system requirements, and feature support across different operating systems and environments.

## 🖥️ Platform Support Matrix

### Operating System Support

| Platform | Version | Support Level | Features | Notes |
|----------|---------|---------------|----------|-------|
| **RHEL** | 8.4+ | ✅ Full Support | All features | Production recommended |
| **RHEL** | 9.0+ | ✅ Full Support | All features | Production recommended |
| **RHEL** | 10.0+ | ✅ Full Support | All features | Latest platform |
| **Rocky Linux** | 8.4+ | ✅ Full Support | All features | Community alternative |
| **Rocky Linux** | 9.0+ | ✅ Full Support | All features | Community alternative |
| **AlmaLinux** | 8.4+ | ✅ Full Support | All features | Community alternative |
| **AlmaLinux** | 9.0+ | ✅ Full Support | All features | Community alternative |
| **CentOS Stream** | 9 | ⚠️ Limited Support | Core features | Testing only |

### Environment Support

| Environment | Support Level | Features Available | Container Awareness | Use Case |
|-------------|---------------|-------------------|-------------------|----------|
| **Physical Hosts** | ✅ Full Support | All features including KVM optimization | N/A | Production deployment |
| **Virtual Machines** | ✅ Supported | Limited optimization features | Nested virt detection | Development/testing |
| **Containers** | ✅ Testing Only | Container-appropriate tasks only | Advanced detection | CI/CD testing |

## 🔧 Hardware Requirements

### Minimum Requirements

#### CPU Requirements
- **Architecture**: x86_64 (Intel/AMD)
- **Virtualization**: Intel VT-x or AMD-V support
- **Cores**: 2 cores minimum (4+ recommended)
- **Features**: Hardware virtualization extensions enabled in BIOS

#### Memory Requirements
- **Minimum**: 8GB RAM
- **Recommended**: 16GB RAM for production
- **Optimal**: 32GB+ for multiple VMs
- **Considerations**: Additional RAM needed for each VM

#### Storage Requirements
- **Minimum**: 100GB available disk space
- **Recommended**: 500GB+ for production
- **Type**: SSD recommended for better performance
- **Partitioning**: Separate partition for `/var/lib/libvirt/images` recommended

#### Network Requirements
- **Connectivity**: Stable network connection
- **Bandwidth**: Sufficient for package downloads and VM traffic
- **Interfaces**: At least one network interface for bridge creation
- **DNS**: Proper DNS resolution configured

### Recommended Hardware

#### Production Environment
```yaml
cpu:
  cores: 8+
  threads: 16+
  features: ["vmx", "ept", "vpid"]  # Intel
  features: ["svm", "npt", "nrips"]  # AMD

memory:
  total: 64GB+
  hugepages: 25% of total memory
  
storage:
  system_disk: 
    size: 500GB+
    type: SSD
  vm_storage:
    size: 2TB+
    type: NVMe SSD (preferred)
    
network:
  interfaces: 2+ (management + VM traffic)
  speed: 1Gbps+ (10Gbps preferred)
```

#### Development Environment
```yaml
cpu:
  cores: 4+
  threads: 8+
  
memory:
  total: 16GB+
  
storage:
  system_disk:
    size: 200GB+
    type: SSD
    
network:
  interfaces: 1+
  speed: 100Mbps+
```

## 💻 Software Requirements

### Ansible Requirements

#### Ansible Core
- **Minimum Version**: 2.13.0
- **Recommended Version**: 2.17.x (latest stable)
- **Installation**: 
  ```bash
  pip install ansible-core>=2.13.0
  ```

#### Required Collections
```yaml
collections:
  - community.libvirt: ">=1.3.0"
  - ansible.posix: ">=1.5.0"
  - community.general: ">=7.0.0"
```

#### Python Requirements
- **Minimum Version**: Python 3.9
- **Recommended Version**: Python 3.11
- **Required Modules**:
  ```bash
  pip install libvirt-python lxml netaddr
  ```

### System Software

#### Required Packages (Auto-installed)
```yaml
base_packages:
  - curl
  - wget
  - git
  - vim
  - unzip
  - tar

kvm_packages:
  - qemu-kvm
  - libvirt-daemon
  - libvirt-daemon-driver-qemu
  - libvirt-client
  - virt-install
  - virt-viewer

network_packages:
  - NetworkManager
  - bridge-utils
  - net-tools

storage_packages:
  - lvm2
  - parted
```

#### Optional Packages
```yaml
optional_packages:
  - cockpit
  - cockpit-machines
  - cockpit-podman
  - htop
  - iotop
  - tcpdump
```

## 🔍 Feature Compatibility Matrix

### Core Features by Platform

| Feature | RHEL 8 | RHEL 9 | RHEL 10 | Rocky 8/9 | AlmaLinux 8/9 |
|---------|--------|--------|---------|-----------|---------------|
| **Base System Setup** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **KVM/Libvirt** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Network Bridges** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Storage Pools** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Cockpit Web UI** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Performance Optimization** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Container Testing** | ✅ | ✅ | ✅ | ✅ | ✅ |

### Advanced Features

| Feature | RHEL 8 | RHEL 9 | RHEL 10 | Notes |
|---------|--------|--------|---------|-------|
| **Nested Virtualization** | ✅ | ✅ | ✅ | CPU dependent |
| **SR-IOV** | ✅ | ✅ | ✅ | Hardware dependent |
| **DPDK** | ✅ | ✅ | ✅ | Advanced networking |
| **GPU Passthrough** | ✅ | ✅ | ✅ | Hardware dependent |
| **NUMA Optimization** | ✅ | ✅ | ✅ | Multi-socket systems |

## 🐳 Container Environment Support

### Container Detection
The collection automatically detects container environments and adapts behavior:

```yaml
container_detection_criteria:
  - virtualization_type: "container"
  - environment_variables: ["container", "CONTAINER"]
  - filesystem_analysis: "/proc/1/cgroup"
  - selinux_context: "container_t"
```

### Container-Specific Behavior
- **Hardware Tasks**: Automatically skipped
- **Service Management**: Adapted for container constraints
- **Network Configuration**: Limited to container-appropriate tasks
- **Storage**: Uses container-compatible storage options

### Supported Container Runtimes
- **Podman**: Preferred for testing
- **Docker**: Supported for testing
- **Kubernetes**: Limited support for testing scenarios

## 🔒 Security and Compliance

### Security Features by Platform

| Security Feature | RHEL 8 | RHEL 9 | RHEL 10 | Implementation |
|------------------|--------|--------|---------|----------------|
| **SELinux** | ✅ | ✅ | ✅ | Enforcing mode supported |
| **Firewalld** | ✅ | ✅ | ✅ | Automatic configuration |
| **FIPS Mode** | ✅ | ✅ | ✅ | Compatible when enabled |
| **Secure Boot** | ⚠️ | ✅ | ✅ | RHEL 9+ full support |

### Compliance Standards
- **STIG**: Security Technical Implementation Guide compliance
- **CIS**: Center for Internet Security benchmarks
- **NIST**: National Institute of Standards and Technology guidelines

## 📊 Performance Characteristics

### Performance by Platform

| Platform | Boot Time | Memory Overhead | Storage Performance | Network Performance |
|----------|-----------|-----------------|-------------------|-------------------|
| **RHEL 8** | ~30s | ~2GB | Good | Good |
| **RHEL 9** | ~25s | ~1.8GB | Better | Better |
| **RHEL 10** | ~20s | ~1.5GB | Best | Best |
| **Rocky/Alma** | ~30s | ~2GB | Good | Good |

### Optimization Features
- **Hugepages**: Automatic configuration
- **CPU Isolation**: NUMA-aware optimization
- **I/O Scheduling**: Optimal scheduler selection
- **Network Tuning**: Bridge and interface optimization

## 🔄 Upgrade Paths

### Supported Upgrade Scenarios

| From | To | Support Level | Migration Guide |
|------|----|--------------|-----------------|
| RHEL 8 | RHEL 9 | ✅ Full Support | [System Migration](../how-to-guides/migrate-systems.md) |
| RHEL 9 | RHEL 10 | ✅ Full Support | [System Migration](../how-to-guides/migrate-systems.md) |
| CentOS 8 | Rocky/Alma 8 | ✅ Full Support | [Distribution Migration](../how-to-guides/migrate-distributions.md) |
| CentOS 8 | Rocky/Alma 9 | ✅ Full Support | [Distribution Migration](../how-to-guides/migrate-distributions.md) |

### Collection Version Compatibility

| Collection Version | Ansible Version | Python Version | Platform Support |
|-------------------|-----------------|----------------|------------------|
| 0.9.x | 2.13+ | 3.9+ | RHEL 8/9/10, Rocky 8/9, Alma 8/9 |
| 0.8.x | 2.12+ | 3.8+ | RHEL 8/9, Rocky 8/9, Alma 8/9 |
| 0.7.x | 2.11+ | 3.8+ | RHEL 8/9, Rocky 8/9 |

## 🧪 Testing Platform Support

### Test Coverage by Platform

| Platform | Unit Tests | Integration Tests | System Tests | Container Tests |
|----------|------------|-------------------|--------------|-----------------|
| **RHEL 8** | ✅ | ✅ | ✅ | ✅ |
| **RHEL 9** | ✅ | ✅ | ✅ | ✅ |
| **RHEL 10** | ✅ | ✅ | ✅ | ✅ |
| **Rocky Linux** | ✅ | ✅ | ✅ | ✅ |
| **AlmaLinux** | ✅ | ✅ | ✅ | ✅ |

### Container Test Images
```yaml
test_images:
  rhel8: "registry.redhat.io/ubi8-init:latest"
  rhel9: "registry.redhat.io/ubi9-init:latest"
  rhel10: "registry.redhat.io/ubi10-init:latest"
  rocky8: "docker.io/rockylinux/rockylinux:8-ubi-init"
  rocky9: "docker.io/rockylinux/rockylinux:9-ubi-init"
  alma8: "docker.io/almalinux/almalinux:8-ubi-init"
  alma9: "docker.io/almalinux/almalinux:9-ubi-init"
```

## 🔗 Related Documentation

- **Installation**: [System Requirements](system-requirements.md)
- **Migration**: [System Migration Guide](../how-to-guides/migrate-systems.md)
- **Testing**: [Container Testing](../how-to-guides/developer/container-testing.md)
- **Compatibility**: [Feature Matrix](feature-matrix.md)

---

*This reference provides complete platform compatibility information. For installation guidance, see tutorials. For migration procedures, check how-to guides.*
