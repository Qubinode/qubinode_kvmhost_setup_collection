# ADR-0009: GitHub Actions Dependabot Auto-Updates Strategy

## Status
Implemented

> **Review Note (2026-01-25)**: ADR compliance review confirmed full implementation with
> 9/10 compliance score. Dependabot is fully configured with GitHub Actions, Docker,
> and Python dependency management with weekly update schedules.

## Context
The Qubinode project uses GitHub Actions for CI/CD automation and relies on various external actions and dependencies. These dependencies include:

- GitHub Actions marketplace actions (e.g., actions/checkout, actions/setup-python)
- Docker base images used in testing and deployment
- Python packages and Ansible collections
- Container image dependencies in CI/CD pipelines

Without automated dependency management, the project faces:
- Security vulnerabilities in outdated dependencies
- Missing feature improvements and bug fixes
- Manual overhead for tracking and updating dependencies
- Inconsistent dependency versions across workflows
- Potential breaking changes when manual updates occur

GitHub Dependabot provides automated dependency scanning and pull request generation for keeping dependencies current.

## Decision
Implement GitHub Dependabot for automated dependency management with the following configuration:

1. **GitHub Actions Updates** - Automated updates for workflow actions
2. **Docker Image Updates** - Monitor and update container base images
3. **Python Dependencies** - Track Python package updates where applicable
4. **Scheduled Updates** - Weekly update checks for all dependency types
5. **Automated Security Updates** - Immediate updates for security vulnerabilities
6. **Review Process** - Require review for major version updates

## Alternatives Considered
1. **Manual dependency management** - Human-driven updates only
   - Pros: Full control over timing and versions
   - Cons: Time-consuming, error-prone, often delayed, security risks

2. **Renovate Bot** - Alternative dependency management tool
   - Pros: More configuration options, supports more ecosystems
   - Cons: Additional third-party tool, more complex setup, GitHub native solution preferred

3. **Custom automation scripts** - Build internal dependency checking
   - Pros: Tailored to specific needs, full control
   - Cons: Development and maintenance overhead, reinventing existing solutions

4. **No automation** - Manual updates only when issues arise
   - Pros: No additional tooling complexity
   - Cons: Security vulnerabilities, missed improvements, technical debt accumulation

## Consequences

### Positive
- **Security improvements** - Automatic security vulnerability patching
- **Reduced maintenance** - Automated dependency update pull requests
- **Consistent updates** - Regular, predictable update schedule
- **Early issue detection** - Find breaking changes before manual updates
- **Improved reliability** - Stay current with bug fixes and improvements
- **Time savings** - Reduce manual dependency tracking effort
- **Compliance** - Better security posture for enterprise environments

### Negative
- **Update frequency** - More pull requests to review and merge
- **Breaking changes** - Potential for automated updates to introduce issues
- **Testing overhead** - Need robust CI/CD to validate automated updates
- **Review burden** - Team needs to review and approve automated PRs

## Implementation

### Dependabot Configuration (`.github/dependabot.yml`)
```yaml
version: 2
updates:
  # GitHub Actions dependencies
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 5
    reviewers:
      - "qubinode/maintainers"
    assignees:
      - "qubinode/maintainers"

  # Docker dependencies  
  - package-ecosystem: "docker"
    directory: "/molecule/default"
    schedule:
      interval: "weekly"
      day: "tuesday"
    open-pull-requests-limit: 3

  # Python dependencies (if requirements.txt exists)
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "wednesday"
    open-pull-requests-limit: 5
```

### Update Strategy
- **Minor/Patch Updates**: Auto-merge after CI passes (with team approval)
- **Major Updates**: Require manual review and testing
- **Security Updates**: Immediate notification and priority handling
- **Failed Updates**: Alert team for manual intervention

### Integration with CI/CD
- All Dependabot PRs trigger full test suite
- Molecule tests validate changes don't break role functionality
- Ansible lint and syntax checks ensure code quality
- Manual testing for major dependency updates

## Evidence
- `.github/dependabot.yml` configuration file
- GitHub Actions workflows using pinned action versions
- Docker images with version tags in testing configurations
- CI/CD pipeline integration with dependency validation

## Date
2024-07-11

## Tags
github-actions, dependabot, automation, security, dependencies, ci-cd, maintenance
