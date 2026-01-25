# ADR-0014: Ansible Galaxy Automated Release Strategy

## Status
Implemented

> **Status Update (2026-01-25)**: ADR compliance review confirmed full implementation. Automated releases are fully functional:
> - Release workflow uses GITHUB_TOKEN (fixed in release v0.10.10)
> - Galaxy publishing verified working
> - AI-generated release notes operational
> - Phases 1-3 substantially complete

## Context

The Qubinode KVM Host Setup Collection requires a reliable and efficient strategy for releasing updates to Ansible Galaxy. Currently, releases are manual and infrequent, with the last release (v0.9.0) occurring on January 6, 2025. The collection has significant enhancements (comprehensive LLM-friendly documentation) that should be made available to the community.

### Current Challenges

1. **Manual Release Process**: Releases require manual intervention, leading to delays
2. **Dependency Update Lag**: Dependency updates don't automatically trigger releases
3. **Release Frequency**: Infrequent releases mean users don't get timely updates
4. **Version Management**: Manual version bumping is error-prone and inconsistent
5. **Quality Assurance**: No systematic pre-release validation process

### Requirements

1. **Automated Releases**: Dependency updates should trigger automatic releases
2. **Manual Override**: Maintainers should be able to trigger releases manually
3. **Quality Gates**: All releases must pass comprehensive validation
4. **Semantic Versioning**: Consistent version management following semver principles
5. **Galaxy Integration**: Seamless deployment to Ansible Galaxy
6. **Rollback Capability**: Ability to handle failed releases and rollbacks

### Integration with Existing ADRs

- **ADR-0009**: GitHub Actions Dependabot Strategy provides dependency update schedule
- **ADR-0011**: Local testing requirements must be validated before releases
- **ADR-0013**: GitHub Actions runner setup supports release automation

## Decision

We will implement a **dual-strategy automated release system** that combines dependency-triggered automation with manual release control, ensuring timely updates while maintaining quality and flexibility.

### Primary Strategy: Dependency-Triggered Automation

**Workflow**: `.github/workflows/auto-release-on-dependencies.yml`

**Trigger Conditions**:
- Dependabot PRs merged with `dependencies` label
- Automatic version bumping based on dependency type
- Comprehensive pre-release validation

**Release Type Mapping**:
```yaml
Python dependencies (pip):     → patch release (0.9.0 → 0.9.1)
GitHub Actions dependencies:   → patch release (0.9.0 → 0.9.1)
Docker dependencies:          → patch release (0.9.0 → 0.9.1)
Ansible dependencies:         → minor release (0.9.0 → 0.10.0)
Breaking changes detected:    → major release (0.9.0 → 1.0.0)
```

### Secondary Strategy: Manual Release Control

**Workflow**: `.github/workflows/manual-release.yml`

**Use Cases**:
- Feature releases (documentation enhancements, new roles)
- Emergency releases requiring immediate deployment
- Custom versioning requirements
- Releases with specific release notes

**Manual Parameters**:
- Version specification (e.g., "1.0.0")
- Release type selection (patch/minor/major)
- Custom release notes
- Validation controls (skip/dry-run options)

## Alternatives Considered

### Alternative 1: Manual-Only Releases
**Pros**: Complete control, no automation complexity
**Cons**: Slow response to dependency updates, human error prone, maintenance overhead
**Rejected**: Doesn't scale with dependency update frequency

### Alternative 2: Time-Based Releases
**Pros**: Predictable release schedule
**Cons**: May release without meaningful changes, doesn't respond to urgent updates
**Rejected**: Not responsive to actual change significance

### Alternative 3: Fully Automated Releases
**Pros**: Maximum automation, minimal human intervention
**Cons**: No control over feature releases, potential for inappropriate releases
**Rejected**: Lacks flexibility for significant feature releases

## Consequences

### Positive

1. **Timely Updates**: Dependency updates automatically trigger releases
2. **Reduced Maintenance**: Automated version management and deployment
3. **Quality Assurance**: Comprehensive validation before every release
4. **Flexibility**: Manual override for special releases
5. **Community Benefit**: Users get updates more frequently
6. **Consistency**: Standardized release process and version management

### Negative

1. **Complexity**: Additional workflows and automation to maintain
2. **Dependency**: Relies on GitHub Actions and Galaxy API availability
3. **Potential Noise**: Frequent releases may create notification fatigue
4. **Debugging**: Automated failures require workflow debugging skills

### Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Galaxy API failures | Release deployment fails | Retry logic and manual fallback |
| Validation failures | Releases blocked | Comprehensive local testing and validation |
| Version conflicts | Inconsistent versioning | Automated version management and validation |
| Workflow failures | Release process breaks | Manual release workflow as backup |

## Implementation

### Phase 1: Workflow Creation ✅
- [x] Create `auto-release-on-dependencies.yml` workflow
- [x] Create `manual-release.yml` workflow  
- [x] Enhance existing `release.yml` workflow integration

### Phase 2: Tooling and Documentation ✅
- [x] Create `scripts/prepare-release.sh` for local release preparation
- [x] Create `docs/RELEASE_STRATEGY.md` comprehensive documentation
- [x] Create this ADR (ADR-0014)

### Phase 3: Validation and Testing ✅
- [x] Test manual release workflow with v0.10.0 (LLM documentation release)
- [x] Validate dependency-triggered automation with test dependency update
- [x] Verify Galaxy deployment and artifact creation (v0.10.10 released 2026-01-25)
- [ ] Test rollback procedures and error handling

### Phase 4: Monitoring and Optimization
- [ ] Monitor release frequency and success rates
- [ ] Optimize validation performance for faster releases
- [ ] Add release metrics and monitoring dashboards
- [ ] Gather community feedback on release frequency

### Required Secrets and Configuration

**GitHub Secrets Required**:
- `GALAXY_API_KEY`: Ansible Galaxy API key for publishing
- `ACCESS_TOKEN`: GitHub token for release creation and repository access

**Repository Configuration**:
- Dependabot configuration in `.github/dependabot.yml` (already configured)
- Proper branch protection rules for main branch
- Workflow permissions for tag creation and release management

## Validation Criteria

### Pre-Release Validation (Automated)
- ✅ ADR compliance check (`scripts/check-compliance.sh`)
- ✅ Security scan (`scripts/enhanced-security-scan.sh`)
- ✅ File structure validation (`scripts/validate-file-structure.sh`)
- ✅ Collection build test (`ansible-galaxy collection build`)
- ✅ Version consistency validation

### Release Success Criteria
- ✅ GitHub release created with proper artifacts
- ✅ Ansible Galaxy deployment successful
- ✅ Collection installable from Galaxy
- ✅ Version consistency across all files
- ✅ No breaking changes in patch/minor releases

## Monitoring and Metrics

### Success Metrics
- **Release Frequency**: Target 1-4 releases per week during active development
- **Deployment Success Rate**: Target >95% successful deployments
- **Validation Pass Rate**: Target >98% validation success
- **Time to Release**: Target <30 minutes from trigger to Galaxy availability

### Monitoring Points
- GitHub Actions workflow success rates
- Galaxy deployment status and timing
- Collection download statistics from Galaxy
- Community feedback and issue reports

## Usage Guidelines

### For Maintainers

**Dependency Updates**:
- Merge Dependabot PRs normally
- Automated releases will trigger automatically
- Monitor workflow execution for any issues

**Feature Releases**:
- Use Manual Release Trigger in GitHub Actions
- Provide descriptive release notes
- Choose appropriate version and release type

**Emergency Releases**:
- Use Manual Release with skip validation if needed
- Document emergency reason in release notes
- Follow up with proper validation post-release

### For Contributors

**Before Contributing**:
- Ensure local testing passes (`scripts/test-local-molecule.sh`)
- Run compliance checks (`scripts/check-compliance.sh`)
- Understand that dependency updates may trigger automatic releases

## Related ADRs

- **ADR-0009**: GitHub Actions Dependabot Auto-Updates Strategy (dependency scheduling)
- **ADR-0011**: Local Molecule Testing Validation (pre-release requirements)
- **ADR-0013**: GitHub Actions Runner Setup (infrastructure requirements)

## References

- [Ansible Galaxy Publishing](https://docs.ansible.com/ansible/latest/dev_guide/collections_galaxy_meta.html)
- [GitHub Actions Workflows](https://docs.github.com/en/actions/using-workflows)
- [Semantic Versioning](https://semver.org/)
- [Dependabot Configuration](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates)

## Evidence

### Implementation Artifacts
- `.github/workflows/auto-release-on-dependencies.yml`
- `.github/workflows/manual-release.yml`
- `scripts/prepare-release.sh`
- `docs/RELEASE_STRATEGY.md`

### Validation Scripts
- `scripts/check-compliance.sh`
- `scripts/enhanced-security-scan.sh`
- `scripts/validate-file-structure.sh`
- `scripts/test-local-molecule.sh`

### Configuration Files
- `galaxy.yml` (version management)
- `Makefile` (build configuration)
- `.github/dependabot.yml` (dependency update schedule)
