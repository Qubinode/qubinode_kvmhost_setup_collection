# RHEL Compatibility Matrix Report
**Generated**: 2025-07-12 14:13:13
**Project**: Qubinode KVM Host Setup Collection

## Compatibility Summary

| Role | RHEL 8 | RHEL 9 | RHEL 10 | Notes |
|------|--------|--------|---------|-------|
| kvmhost_setup | ✅ | ✅ | ✅ | Full/Full/Full |
| kvmhost_base | ✅ | ✅ | ✅ | Full/Full/Full |
| kvmhost_networking | ✅ | ✅ | ✅ | Full/Full/Full |
| kvmhost_libvirt | ✅ | ✅ | ✅ | Full/Full/Full |
| kvmhost_storage | ✅ | ✅ | ✅ | Full/Full/Full |
| kvmhost_cockpit | ✅ | ✅ | ✅ | Full/Full/Full |
| kvmhost_user_config | ✅ | ✅ | ✅ | Full/Full/Full |

## Detailed Analysis
### kvmhost_setup
*KVM Host setup role for setup*

| Feature | RHEL 8 | RHEL 9 | RHEL 10 |
|---------|--------|--------|---------|
| enable_cockpit | ✅ | ✅ | ✅ |
| configure_shell | ✅ | ✅ | ✅ |
| enable_libvirt_admin_user | ✅ | ✅ | ✅ |
| enable_kvm_performance_optimization | ✅ | ✅ | ✅ |
| kvm_enable_cpu_isolation | ✅ | ✅ | ✅ |
| kvm_enable_ksm | ✅ | ✅ | ✅ |
| kvm_enable_nested_virtualization | ✅ | ✅ | ✅ |
| kvm_enable_performance_monitoring | ✅ | ✅ | ✅ |
| bridge_interface | ✅ | ✅ | ✅ |
| build_user_home_dir | ✅ | ✅ | ✅ |
| cockpit_setup | ✅ | ✅ | ✅ |
| configure_remote_user | ✅ | ✅ | ✅ |
| libvirt_setup | ✅ | ✅ | ✅ |
| main | ✅ | ✅ | ✅ |
| networks | ✅ | ✅ | ✅ |
| rhpds_instance | ✅ | ✅ | ✅ |
| rocky_linux | ✅ | ✅ | ✅ |
| storage_pool | ✅ | ✅ | ✅ |
| user_libvirt | ✅ | ✅ | ✅ |
| user_shell_configs | ✅ | ✅ | ✅ |
| validate | ✅ | ✅ | ✅ |
| verify_variables | ✅ | ✅ | ✅ |
| rhel_version_detection | ✅ | ✅ | ✅ |
| kvm_host_validation | ✅ | ✅ | ✅ |
| performance_optimization | ✅ | ✅ | ✅ |
| kvm_feature_detection | ✅ | ✅ | ✅ |

### kvmhost_base
*KVM Host setup role for base*

| Feature | RHEL 8 | RHEL 9 | RHEL 10 |
|---------|--------|--------|---------|
| enable_epel | ✅ | ✅ | ✅ |
| epel_installation_method | ✅ | ✅ | ✅ |
| base_services_enabled | ✅ | ✅ | ✅ |
| main | ✅ | ✅ | ✅ |
| os_detection | ✅ | ✅ | ✅ |
| validate_os | ✅ | ✅ | ✅ |
| packages | ✅ | ✅ | ✅ |
| services | ✅ | ✅ | ✅ |
| system_prep | ✅ | ✅ | ✅ |

### kvmhost_networking
*KVM Host setup role for networking*

| Feature | RHEL 8 | RHEL 9 | RHEL 10 |
|---------|--------|--------|---------|
| network_validation_enabled | ✅ | ✅ | ✅ |
| configure_firewall_for_bridge | ✅ | ✅ | ✅ |
| enable_network_debugging | ✅ | ✅ | ✅ |
| main | ✅ | ✅ | ✅ |
| preflight | ✅ | ✅ | ✅ |
| interface_detection | ✅ | ✅ | ✅ |
| bridge_config | ✅ | ✅ | ✅ |
| network_validation | ✅ | ✅ | ✅ |

### kvmhost_libvirt
*KVM Host setup role for libvirt*

| Feature | RHEL 8 | RHEL 9 | RHEL 10 |
|---------|--------|--------|---------|
| kvmhost_libvirt_enabled | ✅ | ✅ | ✅ |
| kvmhost_libvirt_storage_enabled | ✅ | ✅ | ✅ |
| kvmhost_libvirt_networks_enabled | ✅ | ✅ | ✅ |
| kvmhost_libvirt_user_access_enabled | ✅ | ✅ | ✅ |
| enable_libvirt_admin_user | ✅ | ✅ | ✅ |
| kvmhost_libvirt_validation_enabled | ✅ | ✅ | ✅ |
| main | ✅ | ✅ | ✅ |
| validation | ✅ | ✅ | ✅ |
| services | ✅ | ✅ | ✅ |
| storage | ✅ | ✅ | ✅ |
| networks | ✅ | ✅ | ✅ |
| create_network | ✅ | ✅ | ✅ |
| user_access | ✅ | ✅ | ✅ |

### kvmhost_storage
*KVM Host setup role for storage*

| Feature | RHEL 8 | RHEL 9 | RHEL 10 |
|---------|--------|--------|---------|
| kvmhost_storage_enabled | ✅ | ✅ | ✅ |
| kvmhost_storage_lvm_enabled | ✅ | ✅ | ✅ |
| kvmhost_storage_pools_enabled | ✅ | ✅ | ✅ |
| kvmhost_storage_performance_enabled | ✅ | ✅ | ✅ |
| kvmhost_storage_monitoring_enabled | ✅ | ✅ | ✅ |
| kvmhost_storage_backup_enabled | ✅ | ✅ | ✅ |
| kvmhost_storage_snapshot_enabled | ✅ | ✅ | ✅ |
| kvmhost_storage_validation_enabled | ✅ | ✅ | ✅ |
| main | ✅ | ✅ | ✅ |
| validation | ✅ | ✅ | ✅ |
| lvm_setup | ✅ | ✅ | ✅ |
| advanced_pools | ✅ | ✅ | ✅ |
| performance | ✅ | ✅ | ✅ |
| monitoring | ✅ | ✅ | ✅ |
| backup | ✅ | ✅ | ✅ |

### kvmhost_cockpit
*KVM Host setup role for cockpit*

| Feature | RHEL 8 | RHEL 9 | RHEL 10 |
|---------|--------|--------|---------|
| kvmhost_cockpit_enabled | ✅ | ✅ | ✅ |
| kvmhost_cockpit_service_enabled | ✅ | ✅ | ✅ |
| kvmhost_cockpit_socket_enabled | ✅ | ✅ | ✅ |
| kvmhost_cockpit_ssl_enabled | ✅ | ✅ | ✅ |
| kvmhost_cockpit_firewall_enabled | ✅ | ✅ | ✅ |
| kvmhost_cockpit_monitoring_enabled | ✅ | ✅ | ✅ |
| kvmhost_cockpit_remote_access_enabled | ✅ | ✅ | ✅ |
| enable_cockpit | ✅ | ✅ | ✅ |
| main | ✅ | ✅ | ✅ |

### kvmhost_user_config
*KVM Host setup role for user_config*

| Feature | RHEL 8 | RHEL 9 | RHEL 10 |
|---------|--------|--------|---------|
| kvmhost_user_config_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_shell_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_starship_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_ssh_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_ssh_agent_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_permissions_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_sudo_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_tools_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_dotfiles_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_git_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_environment_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_security_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_backup_enabled | ✅ | ✅ | ✅ |
| kvmhost_user_config_validation_enabled | ✅ | ✅ | ✅ |
| configure_ssh | ✅ | ✅ | ✅ |
| main | ✅ | ✅ | ✅ |
