# ADR-0001: Use DNF Module for EPEL Repository Installation

## Status
Implemented

> **Review Note (2026-01-25)**: ADR compliance review confirmed full implementation with
> 9/10 compliance score. DNF module approach is actively used in production code.

## Context
The Ansible task for installing the EPEL repository was failing due to a GPG key validation error when using the yum module with a direct URL, which doesn't automatically handle GPG key verification. This was causing deployment failures and reducing the reliability of the automation process.

## Decision
Modified the task to use the dnf module to install the epel-release package instead of using yum with direct URL installation. The change was implemented in `roles/kvmhost_setup/tasks/rhpds_instance.yml`.

## Alternatives Considered
1. **Continue using yum module** but manually handle GPG key verification - Would require additional complexity and error handling
2. **Use rpm command directly** with GPG key handling - Less Ansible-native approach
3. **Download and install EPEL repository manually** with custom GPG key management - More complex and less maintainable

## Consequences

### Positive
- The dnf module automatically handles GPG key verification for packages from known repositories
- Eliminates GPG key validation errors during EPEL installation
- Improves reliability of the automation process
- Better security compliance with automatic key verification
- More robust package installation process

### Negative
- Requires dnf to be available on target systems (standard on RHEL 8+/Rocky Linux)
- Slight dependency on newer package management tooling

## Implementation
- Updated `roles/kvmhost_setup/tasks/rhpds_instance.yml` to use dnf module
- Verified EPEL installation works reliably without errors
- Tested on target RHEL-based systems

## Date
2024-07-11

## Tags
ansible, package-management, epel, dnf, deployment
