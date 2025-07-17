Will be updated by antsibull-changelog. Do not edit this manually!

See https://github.com/ansible-community/antsibull-changelog/blob/main/docs/changelogs.rst for information on how to use antsibull-changelog.

Check out ``changelogs/config.yaml`` for its configuration. You need to change at least the ``title`` field in there.

=================================================
Qubinode KVM Host Setup Collection Release Notes
=================================================

.. contents:: Topics

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
