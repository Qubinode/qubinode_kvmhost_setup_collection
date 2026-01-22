# ADR-0018: CI/CD Third-Party Repository GPG Verification Strategy

## Status
Accepted

## Date
2026-01-22

## Context

### Problem Statement
GitHub Actions CI/CD pipelines running on self-hosted Rocky Linux 9 runners experience failures due to GPG signature verification errors from third-party package repositories. Specifically, the `gh-cli` repository configured on the runner causes `dnf makecache` operations to fail with:

```
Error: Failed to download metadata for repo 'gh-cli': repomd.xml GPG signature verification error: Bad GPG signature
```

This blocks all CI/CD jobs that run on self-hosted runners, including:
- Molecule tests (test matrix jobs)
- Security scans
- CentOS Stream 10 compatibility tests
- Dependency validation

### Root Cause Analysis
1. The self-hosted runner has third-party repositories (gh-cli, EPEL) configured with `gpgcheck=1`
2. GPG keys for these repositories may become stale, unavailable, or have signature mismatches
3. Any `dnf` operation triggers metadata refresh for all enabled repositories
4. A single repository GPG failure blocks all package management operations

### Impact
- CI/CD pipeline reliability: Intermittent failures unrelated to code changes
- Developer productivity: False negatives requiring manual investigation
- Release velocity: Blocked deployments due to infrastructure issues

## Decision

Implement a **GPG verification bypass for third-party repositories in CI/CD environments only** through:

1. **Reusable Script**: Create `scripts/fix-ci-repo-gpg-issues.sh` that:
   - Identifies problematic third-party repositories (gh-cli, EPEL variants)
   - Disables GPG verification (`gpgcheck=0`) for these repositories
   - Cleans repository metadata cache
   - Runs early in each CI/CD job before any package operations

2. **Workflow Integration**: Add the GPG fix step after `actions/checkout` in all self-hosted runner jobs:
   - `ansible-test.yml`: lint, test, centos-stream10-test, security jobs
   - `dependency-testing.yml`: All self-hosted jobs

3. **Scope Limitation**: This bypass applies ONLY to:
   - GitHub Actions self-hosted runners
   - Third-party repositories (not base OS repositories)
   - CI/CD test environments (not production deployments)

## Alternatives Considered

### 1. Manual GPG Key Management
- **Approach**: Import and maintain GPG keys for all third-party repositories
- **Pros**: Maintains full security verification
- **Cons**:
  - High maintenance burden
  - Keys expire and need rotation
  - Different repositories have different key management approaches
  - Still fails when upstream key servers are unavailable
- **Decision**: Rejected due to maintenance complexity

### 2. Remove Third-Party Repositories
- **Approach**: Uninstall gh-cli and EPEL from the runner
- **Pros**: Eliminates the source of GPG errors
- **Cons**:
  - May lose access to needed tools (gh CLI for PR operations)
  - EPEL provides useful packages for testing
- **Decision**: Rejected as it removes useful functionality

### 3. Use ubuntu-latest Runners
- **Approach**: Switch all jobs to ubuntu-latest GitHub-hosted runners
- **Pros**: No third-party repository issues
- **Cons**:
  - Loses RHEL/Rocky/Alma testing parity
  - Cannot test SELinux functionality
  - Different package ecosystem (apt vs dnf)
- **Decision**: Rejected as it undermines testing goals

### 4. Repository-Specific Workarounds
- **Approach**: Disable specific repositories case-by-case
- **Pros**: Minimal changes
- **Cons**:
  - Fragile; new repositories could cause same issue
  - Spread across multiple workflow files
  - No centralized management
- **Decision**: Partially adopted via reusable script

## Consequences

### Positive
- **CI/CD Reliability**: Eliminates GPG-related failures
- **Maintainability**: Single script handles all third-party repository GPG issues
- **Visibility**: ADR documents the decision for future reference
- **Minimal Impact**: Only affects CI/CD environments, not production

### Negative
- **Reduced Security**: GPG verification disabled for third-party repos in CI
  - **Mitigation**: This only affects test environments; production deployments are not impacted
- **Technical Debt**: If runner is rebuilt, this workaround may no longer be needed
  - **Mitigation**: Script is idempotent and no-ops if repositories are already configured correctly

### Neutral
- **Ongoing Monitoring**: Should periodically review if this workaround is still needed
- **Runner Modernization**: Consider rebuilding runner as CentOS Stream 10 (see GitHub issue)

## Implementation

### Files Created/Modified
1. `scripts/fix-ci-repo-gpg-issues.sh` - Reusable GPG fix script
2. `.github/workflows/ansible-test.yml` - Added GPG fix step to 4 jobs
3. `.github/workflows/dependency-testing.yml` - Added GPG fix step to 6 jobs

### Usage
The fix is applied automatically at the start of each CI/CD job:

```yaml
- name: Fix third-party repository GPG issues
  run: |
    chmod +x scripts/fix-ci-repo-gpg-issues.sh
    ./scripts/fix-ci-repo-gpg-issues.sh
```

## Evidence

### Related ADRs
- **ADR-0009**: GitHub Actions Dependabot Auto-Updates Strategy
- **ADR-0017**: ansible-core Version Support Policy

### References
- Failed run: https://github.com/Qubinode/qubinode_kvmhost_setup_collection/actions/runs/21228537922
- gh-cli repository documentation: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
- DNF GPG verification: https://dnf.readthedocs.io/en/latest/conf_ref.html#gpgcheck-label

## Tags
- ci-cd
- infrastructure
- security
- reliability
- github-actions
