# kvmhost_setup Role Reference

Complete reference documentation for the main orchestration role in the Qubinode KVM Host Setup Collection.

## 📋 Role Overview

**Purpose**: Main orchestration role that coordinates all KVM host setup tasks
**Type**: Orchestration role
**Dependencies**: All other collection roles
**Minimum Ansible**: 2.13.0

## 🔧 Variables Reference

### Core Configuration Variables

#### Basic Setup
| Variable | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `cicd_test` | boolean | `false` | No | Set to true when host is virtual or running in a container |
| `lib_virt_setup` | boolean | `true` | No | Set to true to enable libvirt and KVM |
| `enable_cockpit` | boolean | `true` | No | Set to true to enable Cockpit web interface |
| `configure_shell` | boolean | `true` | No | Configure the user bash shell login prompt |

#### Network Configuration
| Variable | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `kvm_host_ipaddr` | string | `ansible_default_ipv4.address` | Yes | KVM host IP address |
| `kvm_host_ip` | string | `ansible_default_ipv4.address` | Yes | KVM host IP address (alias) |
| `kvm_host_interface` | string | `ansible_default_ipv4.interface` | Yes | Primary network interface |
| `kvm_host_gw` | string | `ansible_default_ipv4.gateway` | Yes | Network gateway |
| `kvm_host_netmask` | string | `ansible_default_ipv4.netmask` | Yes | Network netmask |
| `kvm_host_mask_prefix` | integer | `24` | Yes | CIDR prefix length |
| `kvm_host_bootproto` | string | `dhcp` | No | Boot protocol (dhcp/static) |
| `kvm_bridge_type` | string | `Bridge` | No | Bridge type |
| `qubinode_bridge_name` | string | `qubibr0` | No | Bridge network name |
| `kvm_host_domain` | string | `example.com` | No | Host domain name |
| `kvm_host_dns_server` | string | `1.1.1.1` | No | Primary DNS server |

#### Storage Configuration
| Variable | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `kvm_host_libvirt_dir` | string | `/var/lib/libvirt/images` | No | Libvirt images directory |
| `create_libvirt_storage` | boolean | `true` | No | Configure libvirt storage |
| `libvirt_images_dir` | string | `/var/lib/libvirt/images` | No | VM disk images directory |
| `libvirt_pool_name` | string | `default` | No | Default storage pool name |

#### User Configuration
| Variable | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `admin_user` | string | `""` | Yes | SSH username for KVM server |
| `enable_libvirt_admin_user` | boolean | `true` | No | Add admin_user to libvirt group |
| `kvm_host_group` | string | `libvirt` | No | Libvirt admin group |
| `shell_users` | list | `["{{ admin_user }}"]` | No | Users whose shell will be configured |

### Advanced Configuration Variables

#### Performance Optimization
| Variable | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `enable_kvm_performance_optimization` | boolean | `true` | No | Enable KVM performance optimizations |
| `kvm_hugepages_percent` | integer | `25` | No | Hugepages percentage of total memory |
| `kvm_cpu_governor` | string | `performance` | No | CPU frequency governor |
| `kvm_enable_cpu_isolation` | boolean | `true` | No | Enable CPU isolation for VMs |
| `kvm_enable_ksm` | boolean | `true` | No | Enable Kernel Same-page Merging |
| `kvm_ksm_pages_to_scan` | integer | `100` | No | KSM pages to scan |
| `kvm_ksm_sleep_millisecs` | integer | `1000` | No | KSM sleep interval |
| `kvm_enable_nested_virtualization` | boolean | `true` | No | Enable nested virtualization |
| `kvm_optimize_network_performance` | boolean | `true` | No | Enable network performance optimizations |

#### Network Performance Sysctls
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `kvm_performance_sysctls` | dict | See below | System kernel parameters for optimization |

```yaml
kvm_performance_sysctls:
  # Memory management
  vm.swappiness: 1
  vm.vfs_cache_pressure: 50
  vm.dirty_background_ratio: 5
  vm.dirty_ratio: 10
  vm.dirty_writeback_centisecs: 500
  vm.dirty_expire_centisecs: 3000
  
  # Network performance
  net.core.default_qdisc: fq_codel
  net.ipv4.tcp_congestion_control: bbr
  net.core.rmem_max: 268435456
  net.core.wmem_max: 268435456
  net.core.rmem_default: 65536
  net.core.wmem_default: 65536
  net.core.netdev_max_backlog: 5000
  
  # Bridge optimizations
  net.bridge.bridge-nf-call-ip6tables: 0
  net.bridge.bridge-nf-call-iptables: 0
  net.bridge.bridge-nf-call-arptables: 0
```

### Complex Data Structures

#### Libvirt Host Networks
```yaml
libvirt_host_networks:
  - name: "{{ vm_libvirt_net | default('qubinet') }}"
    create: true
    mode: bridge
    bridge_device: "{{ kvm_host_bridge_name | default(qubinode_bridge_name) }}"
    ifcfg_type: "{{ kvm_bridge_type }}"
    ifcfg_bootproto: "{{ kvm_host_bootproto }}"
    bridge_slave_dev: "{{ kvm_host_interface }}"
    gateway: "{{ kvm_host_gw }}"
    mask_prefix: "{{ kvm_host_mask_prefix }}"
    ipaddress: "{{ kvm_host_ip }}"
    mask: "{{ kvm_host_netmask }}"
    mac: "{{ kvm_host_macaddr }}"
```

#### Storage Pools Configuration
```yaml
libvirt_host_storage_pools:
  - name: default
    state: active
    autostart: true
    path: "{{ kvm_host_libvirt_dir }}"
```

## 🏷️ Tags Reference

### Available Tags
| Tag | Purpose | Tasks Affected |
|-----|---------|----------------|
| `always` | Always run | RHEL detection, variable validation |
| `rhel_detection` | OS detection | RHEL version detection tasks |
| `security` | Security tasks | GPG verification, security hardening |
| `gpg_verification` | GPG validation | Package GPG verification |
| `adr_0001` | ADR compliance | EPEL repository management |
| `packages` | Package management | Package installation tasks |
| `shell` | Shell configuration | User shell setup |
| `cockpit` | Cockpit setup | Web interface installation |
| `libvirt` | Libvirt setup | Virtualization configuration |
| `networking` | Network setup | Bridge and network configuration |
| `storage` | Storage setup | Storage pool configuration |
| `performance` | Performance tuning | KVM optimization tasks |
| `kvm-optimization` | KVM tuning | Performance optimization |
| `detection` | Feature detection | KVM capability detection |
| `kvm-features` | Feature validation | Hardware feature validation |

### Tag Usage Examples
```bash
# Run only networking tasks
ansible-playbook playbook.yml --tags networking

# Skip shell configuration
ansible-playbook playbook.yml --skip-tags shell

# Run security-related tasks only
ansible-playbook playbook.yml --tags security,gpg_verification
```

## 🔄 Task Flow

### Main Task Sequence
1. **RHEL Version Detection** (`rhel_version_detection.yml`)
2. **GPG Key Verification** (`gpg_verification.yml`) 
3. **Variable Validation** (`verify_variables.yml`)
4. **Package Installation** (with GPG verification)
5. **Shell Configuration** (`configure_shell.yml`) - if enabled
6. **Cockpit Setup** (`cockpit_setup.yml`) - if enabled
7. **Rocky Linux Setup** (`rocky_linux.yml`) - if Rocky Linux
8. **RHPDS Configuration** (`rhpds_instance.yml`) - if GUID set
9. **Remote User Setup** (`configure_remote_user.yml`) - if GUID set
10. **Libvirt Setup** (`libvirt_setup.yml`) - if enabled
11. **KVM Feature Detection** (`kvm_feature_detection.yml`)
12. **Performance Optimization** (`performance_optimization.yml`)

### Conditional Execution
```yaml
# Cockpit setup conditions
when: enable_cockpit|bool and ansible_distribution != "Rocky"

# Rocky Linux specific
when: enable_cockpit|bool and (ansible_distribution == "Rocky")

# RHPDS environment
when: enable_cockpit|bool and lookup('env', 'GUID', default='') != ""

# Libvirt setup
when: lib_virt_setup|bool

# Performance optimization
when: enable_kvm_performance_optimization|default(true)|bool
```

## 📤 Return Values and Facts

### Generated Facts
| Fact | Type | Description |
|------|------|-------------|
| `kvm_features_detected` | dict | Detected KVM hardware features |
| `libvirt_networks_configured` | list | Configured libvirt networks |
| `storage_pools_created` | list | Created storage pools |
| `performance_optimizations_applied` | list | Applied performance optimizations |

### Example Return Values
```yaml
kvm_features_detected:
  nested_virtualization: true
  hardware_acceleration: true
  cpu_features: ["vmx", "svm"]
  
libvirt_networks_configured:
  - name: "qubinet"
    bridge: "qubibr0"
    state: "active"
    
storage_pools_created:
  - name: "default"
    path: "/var/lib/libvirt/images"
    state: "active"
```

## 🔗 Dependencies

### Role Dependencies
This role orchestrates the following roles:
- `kvmhost_base` - Base system configuration
- `kvmhost_networking` - Network bridge setup
- `kvmhost_libvirt` - Libvirt configuration
- `kvmhost_storage` - Storage management
- `kvmhost_cockpit` - Web interface setup
- `kvmhost_user_config` - User environment

### Collection Dependencies
```yaml
collections:
  - community.libvirt
  - ansible.posix
  - community.general
```

### System Dependencies
- libvirt-daemon
- qemu-kvm
- NetworkManager
- Python 3.9+

## 📝 Usage Examples

### Basic Usage
```yaml
- hosts: kvm_hosts
  become: true
  vars:
    admin_user: "kvmadmin"
    kvm_host_ipaddr: "192.168.1.100"
    kvm_host_interface: "ens3"
  roles:
    - tosin2013.qubinode_kvmhost_setup_collection.kvmhost_setup
```

### Advanced Configuration
```yaml
- hosts: kvm_hosts
  become: true
  vars:
    # User configuration
    admin_user: "kvmadmin"
    
    # Network configuration
    kvm_host_ipaddr: "10.0.1.100"
    kvm_host_interface: "ens3"
    kvm_host_gw: "10.0.1.1"
    kvm_host_netmask: "255.255.255.0"
    kvm_host_mask_prefix: 24
    qubinode_bridge_name: "kvmbr0"
    
    # Feature toggles
    enable_cockpit: true
    configure_shell: true
    lib_virt_setup: true
    
    # Performance optimization
    enable_kvm_performance_optimization: true
    kvm_hugepages_percent: 30
    kvm_cpu_governor: "performance"
    
  roles:
    - tosin2013.qubinode_kvmhost_setup_collection.kvmhost_setup
```

### Container Testing Configuration
```yaml
- hosts: test_hosts
  become: true
  vars:
    cicd_test: true  # Disable hardware-specific features
    admin_user: "testuser"
    configure_shell: false  # Skip shell config in containers
  roles:
    - tosin2013.qubinode_kvmhost_setup_collection.kvmhost_setup
```

## 🔗 Related Documentation

- **Tutorial**: [Your First KVM Host Setup](../../tutorials/01-first-kvm-host-setup.md)
- **How-To**: [Configure KVM Host](../../how-to-guides/configure-kvm-host.md)
- **Explanation**: [Collection Architecture](../../explanations/architecture-overview.md)
- **Other Roles**: [Role Reference Index](README.md)

---

*This reference provides complete technical specifications for the kvmhost_setup role. For usage guidance, see tutorials and how-to guides.*
