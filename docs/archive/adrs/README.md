# Architectural Decision Records (ADRs) Index

This directory contains the architectural decision records for the Qubinode KVM Host Setup Collection project.

## ADR List

| ADR | Title | Status | Date | Category |
|-----|-------|--------|------|----------|
| [ADR-0001](adr-0001-use-dnf-module-for-epel-repository-installation.md) | Use DNF Module for EPEL Repository Installation | Implemented | 2024-07-11 | Deployment |
| [ADR-0002](adr-0002-ansible-role-based-modular-architecture.md) | Ansible Role-Based Modular Architecture | Implemented | 2024-07-11 | Architecture |
| [ADR-0003](adr-0003-kvm-virtualization-platform-selection.md) | KVM Virtualization Platform Selection | Implemented | 2024-07-11 | Infrastructure |
| [ADR-0004](adr-0004-idempotent-task-design-pattern.md) | Idempotent Task Design Pattern | Implemented | 2024-07-11 | Process |
| [ADR-0005](adr-0005-molecule-testing-framework-integration.md) | Molecule Testing Framework Integration | Implemented | 2024-07-11 | Testing |
| [ADR-0006](adr-0006-configuration-management-patterns.md) | Configuration Management Patterns | Implemented | 2024-07-11 | Architecture |
| [ADR-0007](adr-0007-network-architecture-decisions.md) | Network Architecture Decisions | Implemented | 2024-07-11 | Infrastructure |
| [ADR-0008](adr-0008-rhel-9-and-rhel-10-support-strategy.md) | RHEL 9 and RHEL 10 Support Strategy | Implemented | 2024-07-11 | Compatibility |
| [ADR-0009](adr-0009-github-actions-dependabot-auto-updates-strategy.md) | GitHub Actions Dependabot Auto-Updates Strategy | Implemented | 2024-07-11 | DevOps |
| [ADR-0010](adr-0010-end-user-repeatability-and-solution-reproducibility-strategy.md) | End-User Repeatability and Solution Reproducibility Strategy | Implemented | 2024-07-11 | Quality |
| [ADR-0011](adr-0011-local-molecule-testing-validation-before-cicd.md) | Local Molecule Testing Validation Before CI/CD | Implemented | 2025-01-12 | Testing |
| [ADR-0012](adr-0012-init-container-vs-regular-container-molecule-testing.md) | Init Container vs Regular Container Molecule Testing | Implemented | 2024-07-11 | Testing |
| [ADR-0013](adr-0013-molecule-systemd-configuration-best-practices.md) | Molecule Systemd Configuration Best Practices | Implemented | 2024-07-11 | Testing |
| [ADR-0014](../adr/ADR-0014-ANSIBLE-GALAXY-AUTOMATED-RELEASE-STRATEGY.md) | Ansible Galaxy Automated Release Strategy | Implemented | 2025-01-09 | DevOps |
| [ADR-0015](adr-0015-remote-desktop-architecture.md) | Remote Desktop Architecture Decision (VNC to RDP Migration) | Accepted (Phase 1 Implemented) | 2025-11-14 | Security |
| [ADR-0016](adr-0016-modular-libvirt-daemons-rhel10.md) | Modular Libvirt Daemons for RHEL 10 | Implemented | 2025-01-21 | Infrastructure |
| [ADR-0017](adr-0017-ansible-core-version-support-policy.md) | ansible-core Version Support Policy | Implemented | 2026-01-22 | CI/CD |
| [ADR-0018](adr-0018-ci-third-party-repo-gpg-strategy.md) | CI/CD Third-Party Repository GPG Verification Strategy | Implemented | 2026-01-22 | CI/CD |

## ADR Categories

### Architecture
- **ADR-0002**: Establishes the modular role-based structure for organizing Ansible automation
- **ADR-0006**: Defines configuration management patterns and variable hierarchy

### Infrastructure
- **ADR-0003**: Defines KVM as the virtualization platform for hosting workloads
- **ADR-0007**: Establishes bridge-based networking architecture for VM connectivity
- **ADR-0016**: Implements modular libvirt daemons for RHEL 10 with socket-activated services

### Deployment
- **ADR-0001**: Standardizes package management approach using DNF module

### Process
- **ADR-0004**: Ensures all automation tasks follow idempotent design principles

### Testing
- **ADR-0005**: Integrates Molecule framework for automated role testing
- **ADR-0011**: Establishes local Molecule testing validation before CI/CD with pre-commit hooks
- **ADR-0012**: Defines init container usage for systemd-enabled Molecule testing
- **ADR-0013**: Documents Molecule systemd configuration best practices

### Compatibility
- **ADR-0008**: Defines multi-version support strategy for RHEL 8, 9, and 10

### Security
- **ADR-0015**: Establishes secure remote desktop migration strategy from VNC/X11 to RDP/Wayland for RHEL 10 (Phase 2 blocked by SELinux bug BZ 2271661)

### DevOps
- **ADR-0009**: Implements automated dependency management with GitHub Dependabot
- **ADR-0014**: Establishes automated release strategy for Ansible Galaxy deployment

### CI/CD
- **ADR-0017**: Establishes ansible-core version support policy (2.18-2.19) for RHEL 9/10 compatibility
- **ADR-0018**: Defines strategy for handling third-party repository GPG verification in CI environments

### Quality
- **ADR-0010**: Establishes comprehensive end-user repeatability and solution reproducibility standards

## Status Summary

| Status | Count | Description |
|--------|-------|-------------|
| **Implemented** | 17 | Decision fully implemented in codebase |
| **Accepted (Partial)** | 1 | ADR-0015 Phase 1 complete, Phase 2 blocked by external dependency |
| **Deprecated** | 0 | No deprecated ADRs |

> **Last Review**: 2026-01-25
> **Overall Compliance Score**: 9.0/10

## Usage

Each ADR follows the NYGARD template format with the following sections:
- **Status**: Current state of the decision
- **Context**: Background and problem being addressed
- **Decision**: The actual architectural decision made
- **Alternatives Considered**: Other options that were evaluated
- **Consequences**: Positive and negative impacts of the decision
- **Implementation**: How the decision is being implemented
- **Evidence**: Supporting artifacts and references

## Contributing

When adding new ADRs:
1. Use the next sequential number (ADR-0019, ADR-0020, etc.)
2. Follow the established naming convention: `adr-NNNN-brief-descriptive-title.md`
3. Use the NYGARD template format for consistency
4. Update this index file to include the new ADR
5. Add appropriate tags for categorization

## References

- [Architectural Decision Records](https://adr.github.io/)
- [NYGARD ADR Template](https://github.com/joelparkerhenderson/architecture-decision-record/blob/main/templates/decision-record-template-by-michael-nygard/index.md)
- [ADR Best Practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/)
