# ADR-0017: ansible-core Version Support Policy

## Status
Accepted

## Context
The Qubinode project requires a clear policy for supported ansible-core versions to ensure compatibility across our target platforms (RHEL 9, RHEL 10, Rocky Linux 9, CentOS Stream 10). Key considerations include:

- **Python Compatibility**: RHEL 9 uses Python 3.11 by default; RHEL 10/CentOS Stream 10 uses Python 3.12
- **SELinux Binding Issues**: ansible-core 2.17.x has known issues with Python 3.11 SELinux bindings that cause test failures
- **Molecule-Podman Compatibility**: ansible-core 2.19+ requires `ANSIBLE_ALLOW_BROKEN_CONDITIONALS=True` for molecule-podman compatibility
- **CI/CD Stability**: Self-hosted runners need reliable, tested ansible-core versions

### Research Findings

#### ansible-core 2.17.x
- Has SELinux binding issues with Python 3.11
- Causes `ansible-config dump` failures in CI environments
- Not recommended for new deployments

#### ansible-core 2.18.x
- Fixes SELinux binding issues present in 2.17
- Provides stable Python 3.11 support for RHEL 9
- Supports Python 3.12 for RHEL 10/CentOS Stream 10
- Current stable release recommended for production

#### ansible-core 2.19.x
- Enhanced Python 3.12 support
- Requires `ANSIBLE_ALLOW_BROKEN_CONDITIONALS=True` for molecule-podman compatibility
- Breaking changes in conditional handling affect some molecule scenarios
- Suitable for testing and forward compatibility validation

## Decision
Establish a version support policy for ansible-core:

1. **Minimum Version**: ansible-core 2.18.0
2. **Maximum Version**: ansible-core <2.20.0
3. **CI Matrix**: Test both 2.18 and 2.19 in parallel
4. **Environment Variable**: Set `ANSIBLE_ALLOW_BROKEN_CONDITIONALS=True` for 2.19 compatibility

### Version Constraint
```
ansible-core>=2.18.0,<2.20.0
```

## Alternatives Considered

### 1. Pin to Single Version (2.18.x only)
- **Pros**: Maximum stability, no compatibility workarounds needed
- **Cons**: Doesn't validate forward compatibility, may miss Python 3.12 improvements

### 2. Use Latest (>=2.17.0)
- **Pros**: Always uses newest features
- **Cons**: 2.17 has known SELinux issues, unstable for Python 3.11

### 3. Wider Range (>=2.17.0,<2.21.0)
- **Pros**: Maximum flexibility
- **Cons**: Includes problematic 2.17, requires extensive workarounds

### 4. Conservative (2.16 LTS only)
- **Pros**: Long-term support stability
- **Cons**: Missing Python 3.11/3.12 improvements, older dependencies

## Consequences

### Positive
- **Stability**: 2.18.x is proven stable with Python 3.11 on RHEL 9
- **Forward Compatibility**: Testing 2.19 ensures readiness for future upgrades
- **SELinux Support**: Both versions properly support SELinux bindings
- **CI Reliability**: Clear version constraints prevent unexpected failures
- **Documentation**: Clear policy for contributors and users

### Negative
- **Workaround Required**: 2.19 needs `ANSIBLE_ALLOW_BROKEN_CONDITIONALS=True`
- **Excluded Versions**: 2.17.x explicitly not supported despite availability
- **Testing Overhead**: CI matrix tests multiple versions

## Implementation

### CI/CD Configuration
```yaml
# .github/workflows/ansible-test.yml
strategy:
  matrix:
    ansible-version: ["2.18", "2.19"]
    python-version: ["3.11"]
```

### Environment Variables for 2.19 Compatibility
```yaml
env:
  ANSIBLE_ALLOW_BROKEN_CONDITIONALS: "True"
```

### Version Installation
```bash
# Install specific version
pip install ansible-core==2.18

# Install with constraint
pip install "ansible-core>=2.18.0,<2.20.0"
```

### Lint Tools Configuration
```bash
# Install lint tools with compatible ansible-core
pip install ansible-lint>=6.0.0 "ansible-core>=2.18.0,<2.20.0"
```

## Python Compatibility Matrix

| Platform | Python Version | Recommended ansible-core | Notes |
|----------|----------------|-------------------------|-------|
| RHEL 9 | Python 3.11 | 2.18.x | Stable, full SELinux support |
| Rocky Linux 9 | Python 3.11 | 2.18.x | Same as RHEL 9 |
| RHEL 10 | Python 3.12 | 2.18.x / 2.19.x | Both supported |
| CentOS Stream 10 | Python 3.12 | 2.18.x / 2.19.x | Both supported |

## Evidence

### Implementation Artifacts
- `.github/workflows/ansible-test.yml`: CI matrix with 2.18 and 2.19
- `.github/workflows/dependency-testing.yml`: Version compatibility tests
- `molecule/*/molecule.yml`: Molecule scenarios tested with both versions

### Validation Evidence
- CI pipeline successfully runs with 2.18 and 2.19 matrix
- SELinux binding tests pass with 2.18+ on Python 3.11
- Molecule-podman works with `ANSIBLE_ALLOW_BROKEN_CONDITIONALS=True` on 2.19

## References

- [ADR-0008: RHEL 9 and RHEL 10 Support Strategy](./adr-0008-rhel-9-and-rhel-10-support-strategy.md) - Platform support decisions
- [ADR-0012: Init Container vs Regular Container Molecule Testing](./adr-0012-init-container-vs-regular-container-molecule-testing.md) - Container testing strategy
- [ADR-0013: Molecule systemd Configuration Best Practices](./adr-0013-molecule-systemd-configuration-best-practices.md) - Molecule configuration patterns
- [Ansible Core Release Notes](https://github.com/ansible/ansible/blob/stable-2.18/changelogs/CHANGELOG-v2.18.rst) - Official changelog

## Date
2026-01-22

## Tags
ansible-core, python, compatibility, ci-cd, version-policy, rhel-9, rhel-10, selinux, molecule
