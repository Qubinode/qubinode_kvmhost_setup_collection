# Global Variables Reference

Complete reference for collection-wide variables that affect multiple roles or the overall behavior of the Qubinode KVM Host Setup Collection.

## 🌐 Collection-Wide Variables

### Core System Variables

#### `admin_user`
- **Type**: string
- **Required**: Yes
- **Default**: `""` (must be set)
- **Description**: Primary administrative user for KVM host management
- **Used by**: All roles
- **Example**: `admin_user: "kvmadmin"`

#### `cicd_test`
- **Type**: boolean
- **Required**: No
- **Default**: `false`
- **Description**: Set to true when running in containers or CI/CD environments
- **Used by**: All roles (affects hardware-specific tasks)
- **Example**: `cicd_test: true`

#### `domain`
- **Type**: string
- **Required**: No
- **Default**: `"example.com"`
- **Description**: Default domain name for the environment
- **Used by**: kvmhost_setup, kvmhost_libvirt, kvmhost_networking
- **Example**: `domain: "lab.company.com"`

### Network Configuration Variables

#### `kvm_host_ipaddr` / `kvm_host_ip`
- **Type**: string
- **Required**: Yes
- **Default**: `ansible_default_ipv4.address`
- **Description**: Primary IP address of the KVM host
- **Used by**: kvmhost_setup, kvmhost_networking
- **Example**: `kvm_host_ipaddr: "192.168.1.100"`

#### `kvm_host_interface`
- **Type**: string
- **Required**: Yes
- **Default**: `ansible_default_ipv4.interface`
- **Description**: Primary network interface name
- **Used by**: kvmhost_setup, kvmhost_networking
- **Example**: `kvm_host_interface: "ens3"`

#### `kvm_host_gw`
- **Type**: string
- **Required**: Yes
- **Default**: `ansible_default_ipv4.gateway`
- **Description**: Network gateway IP address
- **Used by**: kvmhost_setup, kvmhost_networking
- **Example**: `kvm_host_gw: "192.168.1.1"`

#### `kvm_host_netmask`
- **Type**: string
- **Required**: Yes
- **Default**: `ansible_default_ipv4.netmask`
- **Description**: Network subnet mask
- **Used by**: kvmhost_setup, kvmhost_networking
- **Example**: `kvm_host_netmask: "255.255.255.0"`

#### `kvm_host_mask_prefix`
- **Type**: integer
- **Required**: Yes
- **Default**: `24`
- **Description**: CIDR prefix length for network
- **Used by**: kvmhost_setup, kvmhost_networking
- **Example**: `kvm_host_mask_prefix: 24`

#### `qubinode_bridge_name`
- **Type**: string
- **Required**: No
- **Default**: `"qubibr0"`
- **Description**: Name of the primary bridge interface
- **Used by**: kvmhost_setup, kvmhost_networking, kvmhost_libvirt
- **Example**: `qubinode_bridge_name: "kvmbr0"`

### Storage Configuration Variables

#### `kvm_host_libvirt_dir`
- **Type**: string
- **Required**: No
- **Default**: `"/var/lib/libvirt/images"`
- **Description**: Directory for storing VM disk images
- **Used by**: kvmhost_setup, kvmhost_libvirt, kvmhost_storage
- **Example**: `kvm_host_libvirt_dir: "/data/vms"`

#### `libvirt_pool_name`
- **Type**: string
- **Required**: No
- **Default**: `"default"`
- **Description**: Name of the default libvirt storage pool
- **Used by**: kvmhost_setup, kvmhost_libvirt, kvmhost_storage
- **Example**: `libvirt_pool_name: "vm-storage"`

#### `create_libvirt_storage`
- **Type**: boolean
- **Required**: No
- **Default**: `true`
- **Description**: Whether to configure libvirt storage pools
- **Used by**: kvmhost_setup, kvmhost_storage
- **Example**: `create_libvirt_storage: false`

### Feature Toggle Variables

#### `lib_virt_setup`
- **Type**: boolean
- **Required**: No
- **Default**: `true`
- **Description**: Enable libvirt and KVM configuration
- **Used by**: kvmhost_setup, kvmhost_libvirt
- **Example**: `lib_virt_setup: false`

#### `enable_cockpit`
- **Type**: boolean
- **Required**: No
- **Default**: `true`
- **Description**: Enable Cockpit web interface installation
- **Used by**: kvmhost_setup, kvmhost_cockpit
- **Example**: `enable_cockpit: false`

#### `configure_shell`
- **Type**: boolean
- **Required**: No
- **Default**: `true`
- **Description**: Configure user shell environment and prompt
- **Used by**: kvmhost_setup, kvmhost_user_config
- **Example**: `configure_shell: false`

#### `configure_bridge`
- **Type**: boolean
- **Required**: No
- **Default**: `true`
- **Description**: Create network bridge interface
- **Used by**: kvmhost_setup, kvmhost_networking
- **Example**: `configure_bridge: false`

### DNS Configuration Variables

#### `kvm_host_dns_server`
- **Type**: string
- **Required**: No
- **Default**: `"1.1.1.1"`
- **Description**: Primary DNS server for the KVM host
- **Used by**: kvmhost_setup, kvmhost_networking
- **Example**: `kvm_host_dns_server: "8.8.8.8"`

#### `dns_forwarder`
- **Type**: string
- **Required**: No
- **Default**: `"1.1.1.1"`
- **Description**: DNS forwarder for libvirt networks
- **Used by**: kvmhost_setup, kvmhost_libvirt
- **Example**: `dns_forwarder: "192.168.1.1"`

#### `search_domains`
- **Type**: list
- **Required**: No
- **Default**: `["{{ domain }}"]`
- **Description**: DNS search domains
- **Used by**: kvmhost_setup, kvmhost_libvirt
- **Example**: 
```yaml
search_domains:
  - "lab.company.com"
  - "company.com"
```

## 🔧 Complex Data Structures

### `libvirt_host_networks`
Complete network configuration for libvirt:

```yaml
libvirt_host_networks:
  - name: "{{ vm_libvirt_net | default('qubinet') }}"
    create: true
    mode: bridge                    # bridge, nat, isolated
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

### `libvirt_host_storage_pools`
Storage pool configuration:

```yaml
libvirt_host_storage_pools:
  - name: default
    state: active
    autostart: true
    path: "{{ kvm_host_libvirt_dir }}"
    type: dir                       # dir, lvm, nfs, iscsi
```

## 🎯 Variable Validation

### Required Variable Validation
The collection validates that required variables are set:

```yaml
required_variables:
  - admin_user
  - kvm_host_ipaddr
  - kvm_host_interface
  - kvm_host_gw
  - kvm_host_netmask
  - kvm_host_mask_prefix
```

### Variable Type Validation
Variables are validated for correct types and formats:

```yaml
validation_rules:
  kvm_host_ipaddr:
    type: ipv4_address
    required: true
  kvm_host_mask_prefix:
    type: integer
    min: 1
    max: 32
  admin_user:
    type: string
    min_length: 1
    pattern: "^[a-zA-Z][a-zA-Z0-9_-]*$"
```

## 🔄 Variable Precedence

Variables are resolved in this order (highest to lowest precedence):

1. **Extra vars** (`-e` command line)
2. **Task vars** (in tasks)
3. **Block vars** (in blocks)
4. **Role vars** (`vars/main.yml`)
5. **Play vars** (in playbook)
6. **Host vars** (inventory host_vars)
7. **Group vars** (inventory group_vars)
8. **Role defaults** (`defaults/main.yml`)

### Example Variable Override
```yaml
# In inventory group_vars/all.yml
admin_user: "production-admin"
kvm_host_domain: "prod.company.com"

# In playbook
- hosts: kvm_hosts
  vars:
    enable_cockpit: false  # Override default
  roles:
    - tosin2013.qubinode_kvmhost_setup_collection.kvmhost_setup
```

## 🔒 Security-Sensitive Variables

### Variables Requiring Secure Handling

#### `xrdp_remote_user_password`
- **Type**: string
- **Default**: `"CHANGE_ME_IN_PRODUCTION"`
- **Security**: Should be vaulted in production
- **Example**: 
```yaml
# Use Ansible Vault
xrdp_remote_user_password: "{{ vault_xrdp_password }}"
```

#### SSH and Access Variables
- Store SSH keys and passwords in Ansible Vault
- Use separate vault files for different environments
- Never commit sensitive values to version control

## 📊 Variable Categories by Role

### kvmhost_base Variables
- System configuration flags
- Package management settings
- EPEL repository configuration
- Service management settings

### kvmhost_networking Variables
- Bridge configuration
- Network interface settings
- Firewall configuration
- Validation settings

### kvmhost_libvirt Variables
- Libvirt service configuration
- Storage pool settings
- Network configuration
- User access settings

### kvmhost_storage Variables
- Storage pool definitions
- LVM configuration
- Performance settings
- Backup configuration

### kvmhost_cockpit Variables
- Web interface settings
- SSL configuration
- Module enablement
- Authentication settings

### kvmhost_user_config Variables
- User account management
- Shell configuration
- SSH settings
- Development tools

## 🔗 Related Documentation

- **Role-Specific Variables**: [Role Variables](role-variables.md)
- **Default Values**: [Default Values](default-values.md)
- **Variable Validation**: [Variable Validation](variable-validation.md)
- **Examples**: [Variable Examples](../playbooks/variable-examples.md)

---

*This reference covers collection-wide variables. For role-specific variables, see the individual role documentation.*
