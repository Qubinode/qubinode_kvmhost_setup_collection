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
         - { role: swygue_lvm }

License
-------

GPLv2

Author Information
------------------

* Tosin Akinosho - [tosin2013](https://github.com/tosin2013)
* Rodrique Heron - [flyemsafe](https://github.com/flyemsafe)
* Abnerson Malivert - [amalivert](https://github.com/amalivert)