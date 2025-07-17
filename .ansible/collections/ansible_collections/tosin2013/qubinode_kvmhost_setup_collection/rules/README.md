# Qubinode Architectural Rules

This directory contains the architectural rules derived from the ADRs (Architectural Decision Records) for the Qubinode KVM Host Setup Collection project.

## Files

- **`architectural-rules.json`** - Machine-readable JSON format for tool integration
- **`architectural-rules.yaml`** - Human-readable YAML format for documentation

## Rule Categories

### 🚀 **High Priority Rules (8 rules)**
- **Deployment** (1): Package management and installation patterns
- **Architecture** (2): System design and organization patterns  
- **Infrastructure** (2): Platform and technology selection
- **Process** (1): Development workflow and task design
- **Testing** (1): Quality assurance and validation
- **Compatibility** (1): Multi-version support strategies
- **Quality** (1): Repeatability and reproducibility standards

### 🔧 **Medium Priority Rules (1 rule)**
- **DevOps** (1): CI/CD automation and dependency management

## Rule Summary

| Rule ID | Name | Category | Severity | Source ADR |
|---------|------|----------|----------|------------|
| ADR001-DNF-MODULE | Use DNF Module for EPEL Repository Installation | deployment | error | ADR-0001 |
| ADR002-MODULAR-ROLES | Ansible Role-Based Modular Architecture | architecture | error | ADR-0002 |
| ADR003-KVM-PLATFORM | KVM Virtualization Platform Selection | infrastructure | error | ADR-0003 |
| ADR004-IDEMPOTENT-TASKS | Idempotent Task Design Pattern | process | error | ADR-0004 |
| ADR005-MOLECULE-TESTING | Molecule Testing Framework Integration | testing | error | ADR-0005 |
| ADR006-CONFIG-MANAGEMENT | Configuration Management Patterns | architecture | error | ADR-0006 |
| ADR007-BRIDGE-NETWORKING | Bridge-Based Network Architecture | infrastructure | warning | ADR-0007 |
| ADR008-RHEL-SUPPORT | RHEL 8/9/10 Multi-Version Support Strategy | compatibility | error | ADR-0008 |
| ADR009-DEPENDABOT-AUTOMATION | GitHub Actions Dependabot Auto-Updates Strategy | devops | warning | ADR-0009 |
| ADR010-REPEATABILITY | End-User Repeatability and Solution Reproducibility | quality | error | ADR-0010 |

## Usage

### Validation with MCP Tools
```bash
# Validate a specific file against rules
mcp_adr-analysis_validate_rules \
  --filePath="roles/kvmhost_setup/tasks/main.yml" \
  --rules="$(cat rules/architectural-rules.json)"
```

### Integration with CI/CD
The rules can be integrated into GitHub Actions workflows for automated validation:

```yaml
- name: Validate Architectural Rules
  run: |
    # Parse architectural rules and validate code
    python scripts/validate-rules.py \
      --rules-file rules/architectural-rules.json \
      --target-dir roles/
```

### Development Guidelines
Each rule includes:
- **Pattern**: Regex pattern for automated detection
- **Message**: Clear guidance for developers
- **Severity**: Error (must fix) or Warning (should fix)
- **Source**: Traceability to originating ADR

## Rule Dependencies

Some rules have dependencies on others:
- **ADR002-MODULAR-ROLES** requires **ADR006-CONFIG-MANAGEMENT**
- **ADR005-MOLECULE-TESTING** validates **ADR002-MODULAR-ROLES**
- **ADR010-REPEATABILITY** enhances **ADR004-IDEMPOTENT-TASKS**

## Maintenance

Rules should be updated when:
- ADRs are modified or added
- New architectural patterns emerge
- Validation patterns need refinement
- Tool integration requirements change

## Related Documentation

- [ADRs Directory](../docs/adrs/README.md) - Source architectural decisions
- [Research Documentation](../docs/research/README.md) - Implementation guidance
- [Implementation Roadmap](../docs/research/research-tracking-rhel-9-10-2024-07-11.md) - Current project status
