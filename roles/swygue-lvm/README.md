Role Name
=========

Create pv, vg, lv, filesystems then mounts and configures /etc/fstab.

Requirements
------------



Role Variables
--------------
```
device: vdb
vgname: satdata

logical_volumes:
  - name: pgsql
    size: 10g
    mount_dir: /var/lib/pgsql
    fstype: xfs
  - name: mongodb
    size: 50g
    mount_dir: /var/lib/mongodb
    fstype: xfs
```

Dependencies
------------


Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: swygue-lvm }

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).