# ADR-0011: Local Molecule Testing Validation Before CI/CD

## Status
Proposed

## Context
The project currently has Molecule tests but lacks integration into the local development workflow. Developers can push code without validating it locally, leading to CI/CD failures and wasted resources. Research findings show that 80% of CI/CD failures can be prevented through local testing, and cloud-hosted GitHub Actions runners lack KVM hardware virtualization needed for true libvirt testing. The existing RHEL compatibility matrix workflow creates comprehensive testing but could be more efficient with local pre-validation gates.

## Decision
Implement mandatory local Molecule testing validation before allowing code commits to reach CI/CD. This includes:

1. **Local testing script** that validates environment setup and runs Molecule tests
2. **Pre-commit hooks** that enforce local testing for Ansible-related changes  
3. **Developer guidelines** for local environment setup based on research findings (Python 3.11, Ansible-core 2.17+, Podman preferred)
4. **Quality gates** that prevent untested code from reaching CI/CD
5. **Integration** with existing GitHub Actions workflow without disrupting current functionality

## Alternatives Considered

1. **Continue relying solely on CI/CD for testing validation**
   - Pros: No additional developer setup required
   - Cons: Continued waste of CI/CD resources, slower feedback loops, preventable failures

2. **Implement different local testing framework besides Molecule**
   - Pros: Might be simpler for developers
   - Cons: Would require rebuilding existing test infrastructure, Molecule already integrated

3. **Create separate development and testing branches with different validation rules**
   - Pros: Allows for different workflow approaches
   - Cons: Complicates workflow, doesn't solve the core issue of early validation

4. **Use only lightweight linting without full Molecule test execution locally**
   - Pros: Faster local validation
   - Cons: Misses critical functional and integration issues that Molecule catches

## Consequences

### Positive
- **Reduced CI/CD failures** (target 80% reduction based on research findings)
- **Faster feedback loops** for developers (50% improvement in development cycles)
- **Prevention of wasted CI resources** on preventable failures
- **Improved code quality** through early issue detection
- **Better developer experience** with clear validation steps and immediate feedback
- **Complement existing CI/CD** rather than replace it, maintaining comprehensive testing

### Negative
- **Initial learning curve** for developers unfamiliar with local Molecule testing
- **Additional local setup requirements** (Python 3.11, Podman, Molecule)
- **Potential friction** in urgent fix scenarios where developers might want to bypass testing
- **Maintenance overhead** for local testing scripts and documentation

## Implementation

### Phase 1: Foundation (Week 1-2)
- Create local testing script (`scripts/test-local-molecule.sh`)
- Implement basic pre-commit hook example
- Document environment setup requirements

### Phase 2: Integration (Week 3-4)
- Integrate with existing roles and scenarios
- Add environment validation and setup checks
- Create developer onboarding documentation

### Phase 3: Enforcement (Week 5-6)
- Enable mandatory pre-commit hooks
- Add quality gates for CI/CD protection
- Monitor adoption and effectiveness metrics

## Evidence
- Research findings from `docs/research/local-molecule-testing-validation-2025-01-12.md` showing 80% CI/CD failure prevention potential
- ADR-0005 Molecule Testing Framework Integration provides foundation
- GitHub Actions workflow analysis showing lack of KVM virtualization in cloud runners
- Industry best practices for pre-commit validation and quality gates

## Related ADRs
- **ADR-0005**: Molecule Testing Framework Integration - Provides the testing foundation
- **ADR-0004**: Idempotent Task Design Pattern - Ensures reliable test execution
- **ADR-0009**: GitHub Actions Dependabot Auto-Updates Strategy - CI/CD automation context

## Date
2025-01-12

## Tags
molecule, ci-cd, local-testing, quality-gates, developer-experience, testing-strategy
