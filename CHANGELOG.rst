Will be updated by antsibull-changelog. Do not edit this manually!

See https://github.com/ansible-community/antsibull-changelog/blob/main/docs/changelogs.rst for information on how to use antsibull-changelog.

Check out ``changelogs/config.yaml`` for its configuration. You need to change at least the ``title`` field in there.

=================================================
Qubinode KVM Host Setup Collection Release Notes
=================================================

.. contents:: Topics

v0.10.5
=======

Release Summary
---------------
Bug fix release addressing critical issues discovered during CentOS Stream 10 testing and preparing for Ansible 2.24 compatibility.

Bugfixes
--------
- Fixed broken conditional syntax in gpg_verification.yml causing deployment failures
- Fixed handler case sensitivity mismatch preventing libvirtd restarts
- Removed trailing spaces and fixed line length issues for ansible-lint compliance

Minor Changes
-------------
- Added passlib>=1.7.4 to requirements.txt and documented in README.md
- Migrated all deprecated ansible_* variables to ansible_facts dictionary format for Ansible 2.24 compatibility
- Updated 16 task files across kvmhost_setup and kvmhost_base roles with future-proof variable syntax

Known Issues
------------
- None

v1.0.0
======

Release Summary
-------------
Initial stable release of the Qubinode KVM Host Setup Collection with improved documentation, testing, and containerization support.

Major Changes
------------
- Implemented multi-platform testing for Rocky Linux 8 and 9
- Added containerization support with multi-stage builds
- Enhanced CI/CD pipeline with security scanning
- Consolidated documentation structure

Minor Changes
------------
- Added retry mechanism for k9s installation
- Improved error handling in setup tasks
- Fixed Galaxy API endpoint issues
- Removed strict version constraints for better compatibility

Breaking Changes / Porting Guide
------------------------------
- None

Bugfixes
--------
- Fixed k9s installation timeout issues
- Resolved Galaxy API access problems in CI pipeline
- Corrected version constraint issues with community.general collection

Known Issues
-----------
- Performance benchmarks pending implementation
- Edge case scenarios need additional testing
- Container image signing not yet implemented

New Plugins
----------
None

New Modules
----------
None

New Playbooks
------------
None

New Roles
---------
None
