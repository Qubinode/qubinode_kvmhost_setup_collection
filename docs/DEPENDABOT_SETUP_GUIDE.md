# Dependabot Permissions Setup Guide

## Required Repository Permissions for Dependabot

### 1. GitHub Repository Settings

**Navigate to:** `Settings > General > Features`

**Enable the following:**
- ✅ **Issues** - Required for Dependabot to create issue reports
- ✅ **Pull Requests** - Essential for Dependabot PRs
- ✅ **Actions** - Required for automated workflow triggers

### 2. Branch Protection Rules

**Navigate to:** `Settings > Branches > Branch protection rules`

**For the `main` branch:**
- ✅ **Require pull request reviews before merging**
- ✅ **Require status checks to pass before merging**
- ✅ **Require branches to be up to date before merging**
- ✅ **Include administrators** (optional but recommended)

**Status checks to require:**
- `RHEL Compatibility Matrix Testing / validate-local-testing`
- `RHEL Compatibility Matrix Testing / container-compatibility-validation`
- Any other CI checks you want mandatory

### 3. Dependabot Permissions in Organization Settings

**Navigate to:** `Organization Settings > Code security and analysis`

**Enable:**
- ✅ **Dependency graph** - Required for Dependabot to analyze dependencies
- ✅ **Dependabot alerts** - Security vulnerability notifications
- ✅ **Dependabot security updates** - Automatic security fix PRs
- ✅ **Dependabot version updates** - Regular dependency updates

### 4. Required Secrets and Tokens

**Navigate to:** `Settings > Secrets and variables > Actions`

**Repository Secrets (if needed):**
```
GITHUB_TOKEN (automatically provided)
```

**For private registries or enhanced functionality:**
```
DOCKER_USERNAME (if using private Docker registries)
DOCKER_PASSWORD (if using private Docker registries)
ANSIBLE_GALAXY_TOKEN (if using private Galaxy content)
```

### 5. Team/User Permissions for Reviews

**Navigate to:** `Settings > Manage access`

**Ensure the following users/teams have appropriate access:**
- **@qubinode/maintainers** - Admin or Write access
- **Dependabot[bot]** - Should have Write access (auto-granted when enabled)

### 6. Enhanced Dependabot Configuration

Here's an optimized dependabot.yml for your repository:

```yaml
version: 2
updates:
  # GitHub Actions dependencies
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "UTC"
    open-pull-requests-limit: 10
    reviewers:
      - "qubinode/maintainers"
    assignees:
      - "qubinode/maintainers"
    commit-message:
      prefix: "ci"
      include: "scope"
    labels:
      - "dependencies"
      - "github-actions"
      - "security"
    # Allow auto-merge for patch updates
    allow:
      - dependency-type: "direct"
        update-type: "version-update:semver-patch"

  # Docker dependencies for Molecule testing
  - package-ecosystem: "docker"
    directory: "/molecule"
    schedule:
      interval: "weekly"
      day: "tuesday"
      time: "09:00"
      timezone: "UTC"
    open-pull-requests-limit: 8
    commit-message:
      prefix: "ci"
      include: "scope"
    labels:
      - "dependencies"
      - "docker"
      - "testing"
      - "container-compatibility"

  # Python dependencies
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "daily"  # More frequent for security
      time: "09:00"
      timezone: "UTC"
    open-pull-requests-limit: 10
    commit-message:
      prefix: "deps"
      include: "scope"
    labels:
      - "dependencies"
      - "python"
      - "molecule"
    # Security updates only for Python (more conservative)
    allow:
      - dependency-type: "direct"
        update-type: "security"

  # NPM dependencies (if package.json exists)
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "wednesday"
      time: "09:00"
      timezone: "UTC"
    open-pull-requests-limit: 5
    commit-message:
      prefix: "deps"
      include: "scope"
    labels:
      - "dependencies"
      - "javascript"
```

### 7. GitHub Actions Workflow Permissions

**In your workflow files (.github/workflows/*.yml):**

Add explicit permissions to workflows that interact with Dependabot PRs:

```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write
  checks: write
  actions: read
  security-events: write
```

### 8. Auto-merge Setup (Optional but Recommended)

**Create `.github/workflows/dependabot-auto-merge.yml`:**

```yaml
name: Dependabot Auto-merge
on:
  pull_request:
    types: [opened, synchronize]

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    if: github.actor == 'dependabot[bot]'
    runs-on: ubuntu-latest
    steps:
      - name: Enable auto-merge for Dependabot PRs
        run: |
          gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{github.event.pull_request.html_url}}
          GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}
```

### 9. Security Considerations

**Enable Security Features:**
- ✅ **Secret scanning** - Detects accidentally committed secrets
- ✅ **Code scanning** - Static analysis for vulnerabilities
- ✅ **Private vulnerability reporting** - Responsible disclosure

**Configure vulnerability alerts:**
- Set severity threshold (e.g., "Medium" or higher)
- Enable email notifications for maintainers
- Configure Slack/Teams integration if desired

### 10. Monitoring and Maintenance

**Regular Tasks:**
1. **Weekly:** Review and merge Dependabot PRs
2. **Monthly:** Check Dependabot insights and logs
3. **Quarterly:** Review and update dependabot.yml configuration

**Monitoring Tools:**
- GitHub Insights > Dependency graph
- Security tab > Dependabot alerts
- Actions tab > Dependabot workflow runs

## Troubleshooting Common Issues

### Issue: Dependabot PRs not being created
**Solution:** Check that:
- Repository has dependency files (package.json, requirements.txt, etc.)
- Dependabot has proper permissions
- No conflicting branch protection rules

### Issue: Auto-merge not working
**Solution:** Verify:
- Status checks are passing
- Required reviews are satisfied (or configure exemptions for Dependabot)
- Auto-merge is enabled in branch protection

### Issue: Too many PRs being created
**Solution:** Adjust:
- `open-pull-requests-limit` in dependabot.yml
- Update frequency (daily → weekly)
- Dependency types allowed

---

**Quick Setup Checklist:**
- [ ] Enable Dependabot in organization settings
- [ ] Configure branch protection for main branch
- [ ] Update dependabot.yml with proper teams/reviewers
- [ ] Set up auto-merge workflow (optional)
- [ ] Configure security alerts and scanning
- [ ] Test with a manual Dependabot run
