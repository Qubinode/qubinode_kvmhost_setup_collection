# Molecule Testing Coverage Matrix

## Overview

This document summarizes the testing coverage across all Molecule scenarios for the Qubinode KVM Host Setup Collection.

## Testing Scenarios

### 1. Default Scenario (`molecule/default/`)
**Purpose**: Comprehensive functional testing across all supported distributions

**Platforms**:
- Rocky Linux 8 (`rocky-8`) - RHEL 8 compatibility
- Rocky Linux 9 (`rocky-9`) - RHEL 9 compatibility  
- AlmaLinux 9 (`alma-9`) - Additional RHEL 9 compatibility
- RHEL 9 (`rhel-9`) - Enterprise RHEL 9 testing
- CentOS Stream 9 (`centos-9`) - Community RHEL 9 compatibility
- RHEL 10 (`rhel-10`) - Future RHEL 10 compatibility

**Focus**: Full collection functionality, role integration, multi-distribution support

### 2. RHEL 8 Scenario (`molecule/rhel8/`)
**Purpose**: Focused testing for RHEL 8 specific functionality

**Platforms**:
- Rocky Linux 8 (`rhel8-test`) - RHEL 8 compatibility baseline

**Focus**: Legacy RHEL 8 support, backwards compatibility

### 3. Validation Scenario (`molecule/validation/`)
**Purpose**: Pre-flight validation and system readiness testing

**Platforms**:
- Rocky Linux 9 (`validation-test-rocky9`) - RHEL 9 baseline
- RHEL 9 (`validation-test-rhel9`) - Enterprise RHEL 9
- CentOS Stream 9 (`validation-test-centos9`) - Community RHEL 9
- RHEL 10 (`validation-test-rhel10`) - Future RHEL 10

**Focus**: System validation, prerequisite checking, environment readiness

### 4. Idempotency Scenario (`molecule/idempotency/`)
**Purpose**: ADR-0004 compliance testing - ensuring all tasks are idempotent

**Platforms**:
- Rocky Linux 9 (`idempotency-rocky9`) - RHEL 9 compatibility
- AlmaLinux 9 (`idempotency-alma9`) - Additional RHEL 9 compatibility
- RHEL 9 (`idempotency-rhel9`) - Enterprise RHEL 9
- RHEL 10 (`idempotency-rhel10`) - Future RHEL 10
- CentOS Stream 9 (`idempotency-centos9`) - Community RHEL 9

**Focus**: Idempotency compliance, ADR-0004 requirements, task reliability

## Distribution Coverage Summary

| Distribution | Version | Default | RHEL8 | Validation | Idempotency | Total Scenarios |
|-------------|---------|---------|-------|------------|-------------|-----------------|
| Rocky Linux | 8 | ✅ | ✅ | ❌ | ❌ | 2 |
| Rocky Linux | 9 | ✅ | ❌ | ✅ | ✅ | 3 |
| AlmaLinux | 9 | ✅ | ❌ | ❌ | ✅ | 2 |
| RHEL | 9 | ✅ | ❌ | ✅ | ✅ | 3 |
| RHEL | 10 | ✅ | ❌ | ✅ | ✅ | 3 |
| CentOS Stream | 9 | ✅ | ❌ | ✅ | ✅ | 3 |

**Total Platforms**: 16 across 4 scenarios
**Distribution Coverage**: 6 distributions/versions
**Comprehensive Coverage**: RHEL 9/10 focus with broad compatibility testing

## ADR Compliance

### ADR-0005: Molecule Testing Framework Integration
- ✅ **Multi-scenario testing**: 4 specialized scenarios
- ✅ **Multi-distribution matrix**: 6 distribution variants  
- ✅ **Role-specific testing**: Covers all 3 roles
- ✅ **CI/CD integration ready**: Automated pipeline compatible

### ADR-0004: Idempotent Task Design Pattern
- ✅ **Dedicated idempotency scenario**: Specialized testing
- ✅ **Multi-platform validation**: 5 platform variants
- ✅ **Automated compliance checking**: Framework integration
- ✅ **Quality metrics tracking**: Success rate monitoring

### ADR-0008: RHEL 9/10 Support Strategy
- ✅ **RHEL 9 coverage**: Native RHEL 9 + compatible distributions
- ✅ **RHEL 10 future-proofing**: Early RHEL 10 compatibility testing
- ✅ **Multi-version support**: Conditional logic validation
- ✅ **Community alternatives**: Rocky/Alma/CentOS coverage

## Testing Strategy

### Execution Order (CI/CD Pipeline)
1. **Syntax validation** - Quick YAML/Ansible syntax checks
2. **Validation scenario** - Pre-flight system readiness
3. **Default scenario** - Full functionality testing  
4. **Idempotency scenario** - Compliance and reliability
5. **RHEL8 scenario** - Legacy compatibility (if needed)

### Resource Requirements
- **Container Runtime**: Docker or Podman with systemd support
- **Privileges**: Privileged containers for system-level testing
- **Resources**: ~2GB RAM per concurrent platform
- **Storage**: Temporary container storage for testing artifacts

### Parallel Execution
- Different scenarios can run in parallel
- Platforms within scenarios run concurrently (resource permitting)
- Estimated total testing time: 15-30 minutes for full matrix

## Usage Examples

```bash
# Run all scenarios
molecule test

# Run specific scenario
molecule test -s default
molecule test -s idempotency
molecule test -s validation

# Run single platform in scenario  
molecule test -s default -- --limit rocky-9

# Debug specific failure
molecule converge -s idempotency
molecule verify -s idempotency -- --verbose
```

## Quality Gates

### Required Passing Criteria
- **Syntax**: 100% YAML/Ansible syntax compliance
- **Functional**: All platforms in default scenario pass
- **Idempotency**: 100% idempotency compliance (ADR-0004)
- **Validation**: All pre-flight checks pass

### Success Metrics
- **Distribution Coverage**: >90% of target platforms tested
- **Idempotency Rate**: 100% tasks idempotent on second run
- **Validation Success**: 95% environment readiness checks pass
- **Performance**: <30 minutes total test execution time

## Maintenance

### Regular Updates
- **Container Images**: Monthly base image updates
- **Distribution Versions**: Quarterly new version evaluation
- **Test Coverage**: Continuous expansion as roles evolve
- **Performance Optimization**: Ongoing test execution improvements

### Monitoring
- **Test Success Rates**: Track scenario success over time
- **Platform Health**: Monitor container image availability
- **Resource Usage**: Optimize for CI/CD efficiency
- **Coverage Gaps**: Identify and address testing blind spots

---

**Last Updated**: 2025-07-11  
**Coverage Status**: Comprehensive multi-distribution testing implemented  
**ADR Compliance**: ADR-0004, ADR-0005, ADR-0008 requirements met  
**Next Review**: Monthly platform and coverage assessment
