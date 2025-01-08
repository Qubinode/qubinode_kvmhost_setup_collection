# Development Decisions

## Improving Production Readiness

This document outlines the decisions made to improve the production readiness of the codebase.

### EPEL Repository Installation

- **Initial Issue:** The Ansible task for installing the EPEL repository was failing due to a GPG key validation error. This was because the task was using the `yum` module with a direct URL, which doesn't automatically handle GPG key verification.
- **Solution:** The task was modified to use the `dnf` module to install the `epel-release` package. The `dnf` module automatically handles GPG key verification for packages from known repositories. This change was implemented in `roles/kvmhost_setup/tasks/rhpds_instance.yml`.

### Duplicate Molecule Configuration

- **Issue:** A duplicate Molecule configuration directory (`molecule/default copy/`) was present in the repository.
- **Solution:** The duplicate directory was removed using the `rm -rf` command.

### Ansible Task Review

- The Ansible tasks related to EPEL installation were reviewed to ensure they are efficient and follow best practices. The `epel-release` package is installed correctly, and the `roles/kvmhost_setup/tasks/setup/packages.yml` file correctly enables the EPEL repository and installs necessary packages.

## Future Considerations

- Further review of Ansible roles for potential areas of improvement in terms of efficiency and security.
- Implementation of more comprehensive testing and validation strategies.
