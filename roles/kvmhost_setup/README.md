![Ansible Lint](https://github.com/Qubinode/qubinode_kvmhost_setup/workflows/Ansible%20Lint/badge.svg?branch=dev)

Qubinode kvmhost setup role 
=========
KVM Host Setup for RHEL Qubinode servers

Requirements
------------

* Ansible 

Role Variables
--------------

| variable  | definition |
| ------------- | ------------- |
| project_dir | location of code and qcow iamge | 
| required_rpm_pakcages | list of packages that will be installed |
| libvirt_services | libvirt services |
| libvirt_host_networks | dictionary variable that creates libvirt network xml file. must set the name, mode, and bridge key |
| kvm_host_ipaddr | default value is ansible_default_ipv4.address  |
| kvm_host_ip | default value is ansible_default_ipv4.address |
| kvm_host_interface | default value is ansible_default_ipv4.interface |
| kvm_host_gw | default value is ansible_default_ipv4.gateway |
| kvm_host_macaddr | default value is ansible_default_ipv4.mac |
| kvm_host_netmask | default value is ansible_default_ipv4.netmask |
| kvm_host_mask_prefix | default value is ansible_default_ipv4.gateway |
| kvm_host_bootproto | default value is dhcp |
| kvm_bridge_type | default value is Bridge |
| storage_nic | default value is false |
| libvirt_disk | default value is false |
| qubinode_bridge_name | default qubibr0 name of bridge network |
| qubinode_bridge_fact | name of bridge to check ansible_qubibr0.active for active status |
| qcow_rhel_name | name of default qcow image |
| admin_user | ssh username for kvm server |
| kvm_host_domain | default value is "lab.example" |
| kvm_host_dns_server | default value is  "1.1.1.1"  |
| dns_servers | default value is"{{ dns_server }}" and 8.8.8.8 |
| kvm_host_libvirt_dir | default value is /var/lib/libvirt/images |
| configure_bridge | set to false to skip creating a bridge interface |
| configure_shell | Configure the user bash shell login prompt |
| cockpit_packages | default packages for cockpit |
| cicd_test | set to true to test in container |



Dependencies
------------



Example Playbook
----------------

    ---
    - name: Ensure that Libvirt is configured
      hosts: localhost
      vars: 
        kvm_host_ipaddr: '192.168.1.4'
        kvm_host_interface: 'eno1'
        kvm_host_gw: '192.168.1.1'
        kvm_host_netmask: 255.255.255.0
        kvm_host_mask_prefix: 24
        admin_user: admin
        vm_libvirt_net: qubinet
        cicd_test: true
      roles:
        - role: qubinode_kvmhost_setup

          

License
-------

BSD

Author Information
------------------

* Rodrique Heron - [flyemsafe](https://github.com/flyemsafe)
* Abnerson Malivert - [amalivert](https://github.com/amalivert)