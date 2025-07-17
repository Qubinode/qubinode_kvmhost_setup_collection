# Architectural Decision Records (ADRs) Index

This directory contains the architectural decision records for the Qubinode KVM Host Setup Collection project.

## ADR List

| ADR | Title | Status | Date | Category |
|-----|-------|--------|------|----------|
| [ADR-0001](adr-0001-use-dnf-module-for-epel-repository-installation.md) | Use DNF Module for EPEL Repository Installation | Accepted | 2024-07-11 | Deployment |
| [ADR-0002](adr-0002-ansible-role-based-modular-architecture.md) | Ansible Role-Based Modular Architecture | Accepted | 2024-07-11 | Architecture |
| [ADR-0003](adr-0003-kvm-virtualization-platform-selection.md) | KVM Virtualization Platform Selection | Accepted | 2024-07-11 | Infrastructure |
| [ADR-0004](adr-0004-idempotent-task-design-pattern.md) | Idempotent Task Design Pattern | Accepted | 2024-07-11 | Process |
| [ADR-0005](adr-0005-molecule-testing-framework-integration.md) | Molecule Testing Framework Integration | Accepted | 2024-07-11 | Testing |
| [ADR-0006](adr-0006-configuration-management-patterns.md) | Configuration Management Patterns | Accepted | 2024-07-11 | Architecture |
| [ADR-0007](adr-0007-network-architecture-decisions.md) | Network Architecture Decisions | Accepted | 2024-07-11 | Infrastructure |
| [ADR-0008](adr-0008-rhel-9-and-rhel-10-support-strategy.md) | RHEL 9 and RHEL 10 Support Strategy | Accepted | 2024-07-11 | Compatibility |
| [ADR-0009](adr-0009-github-actions-dependabot-auto-updates-strategy.md) | GitHub Actions Dependabot Auto-Updates Strategy | Accepted | 2024-07-11 | DevOps |
| [ADR-0010](adr-0010-end-user-repeatability-and-solution-reproducibility-strategy.md) | End-User Repeatability and Solution Reproducibility Strategy | Accepted | 2024-07-11 | Quality |
| [ADR-0011](adr-0011-local-molecule-testing-validation-before-cicd.md) | Local Molecule Testing Validation Before CI/CD | Proposed | 2025-01-12 | Testing |

## ADR Categories

### Architecture
- **ADR-0002**: Establishes the modular role-based structure for organizing Ansible automation
- **ADR-0006**: Defines configuration management patterns and variable hierarchy

### Infrastructure  
- **ADR-0003**: Defines KVM as the virtualization platform for hosting workloads
- **ADR-0007**: Establishes bridge-based networking architecture for VM connectivity

### Deployment
- **ADR-0001**: Standardizes package management approach using DNF module

### Process
- **ADR-0004**: Ensures all automation tasks follow idempotent design principles

### Testing
- **ADR-0005**: Integrates Molecule framework for automated role testing
- **ADR-0011**: Establishes local Molecule testing validation before CI/CD to prevent failures and improve developer experience

### Compatibility
- **ADR-0008**: Defines multi-version support strategy for RHEL 8, 9, and 10

### DevOps
- **ADR-0009**: Implements automated dependency management with GitHub Dependabot

### Quality
- **ADR-0010**: Establishes comprehensive end-user repeatability and solution reproducibility standards

## Status Summary
- **Accepted**: 10 ADRs
- **Proposed**: 1 ADR  
- **Deprecated**: 0 ADRs

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
1. Use the next sequential number (ADR-0006, ADR-0007, etc.)
2. Follow the established naming convention: `adr-NNNN-brief-descriptive-title.md`
3. Use the NYGARD template format for consistency
4. Update this index file to include the new ADR
5. Add appropriate tags for categorization

## References

- [Architectural Decision Records](https://adr.github.io/)
- [NYGARD ADR Template](https://github.com/joelparkerhenderson/architecture-decision-record/blob/main/templates/decision-record-template-by-michael-nygard/index.md)
- [ADR Best Practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/)
