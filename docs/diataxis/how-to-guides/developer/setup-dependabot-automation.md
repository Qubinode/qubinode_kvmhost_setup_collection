# How to Set Up Dependabot Automation

This guide shows you how to configure Dependabot for automated dependency management in the Qubinode KVM Host Setup Collection.

## 🎯 Goal

Set up comprehensive Dependabot automation for:
- Automated security updates
- Regular dependency updates
- GitHub Actions workflow updates
- Container image updates for testing
- Automated release triggers

## 📋 Prerequisites

- Repository admin access
- Understanding of GitHub repository settings
- Familiarity with GitHub Actions workflows
- Basic knowledge of dependency management

## 🚀 Step 1: Enable Dependabot Features

### Repository Settings
Navigate to `Settings > General > Features` and enable:
- ✅ **Issues** - Required for Dependabot to create issue reports
- ✅ **Pull Requests** - Essential for Dependabot PRs
- ✅ **Actions** - Required for automated workflow triggers

### Organization Security Settings
Navigate to `Organization Settings > Code security and analysis` and enable:
- ✅ **Dependency graph** - Required for Dependabot to analyze dependencies
- ✅ **Dependabot alerts** - Security vulnerability notifications
- ✅ **Dependabot security updates** - Automatic security fix PRs
- ✅ **Dependabot version updates** - Regular dependency updates

## 🔧 Step 2: Configure Branch Protection

Navigate to `Settings > Branches > Branch protection rules` for the `main` branch:

### Required Settings
- ✅ **Require pull request reviews before merging**
- ✅ **Require status checks to pass before merging**
- ✅ **Require branches to be up to date before merging**
- ✅ **Include administrators** (recommended)

### Required Status Checks
- `RHEL Compatibility Matrix Testing / validate-local-testing`
- `RHEL Compatibility Matrix Testing / container-compatibility-validation`
- `Ansible Lint / ansible-lint`
- `Security Scan / security-scan`

## 📝 Step 3: Create Dependabot Configuration

Create `.github/dependabot.yml`:

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
      interval: "daily"
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
    allow:
      - dependency-type: "direct"
        update-type: "security"

  # Ansible Galaxy dependencies
  - package-ecosystem: "gitsubmodule"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "thursday"
      time: "09:00"
      timezone: "UTC"
    commit-message:
      prefix: "deps"
      include: "scope"
    labels:
      - "dependencies"
      - "ansible-galaxy"
```

## 🤖 Step 4: Set Up Auto-Merge Workflow

Create `.github/workflows/dependabot-auto-merge.yml`:

```yaml
name: Dependabot Auto-merge
on:
  pull_request:
    types: [opened, synchronize]

permissions:
  contents: write
  pull-requests: write
  checks: read

jobs:
  auto-merge:
    if: github.actor == 'dependabot[bot]'
    runs-on: ubuntu-latest
    steps:
      - name: Check if PR is ready for auto-merge
        id: check-pr
        run: |
          # Only auto-merge patch updates and security fixes
          if [[ "${{ github.event.pull_request.title }}" =~ ^(ci|deps)\(.*\):.*patch.*$ ]] || \
             [[ "${{ github.event.pull_request.title }}" =~ .*security.* ]]; then
            echo "auto_merge=true" >> $GITHUB_OUTPUT
          else
            echo "auto_merge=false" >> $GITHUB_OUTPUT
          fi

      - name: Enable auto-merge for safe updates
        if: steps.check-pr.outputs.auto_merge == 'true'
        run: |
          gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Add review request for major updates
        if: steps.check-pr.outputs.auto_merge == 'false'
        run: |
          gh pr edit "$PR_URL" --add-reviewer "qubinode/maintainers"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 🔒 Step 5: Configure Security Settings

### Enable Security Features
Navigate to `Settings > Code security and analysis`:

- ✅ **Secret scanning** - Detects accidentally committed secrets
- ✅ **Code scanning** - Static analysis for vulnerabilities  
- ✅ **Private vulnerability reporting** - Responsible disclosure

### Configure Vulnerability Alerts
- Set severity threshold to "Medium" or higher
- Enable email notifications for maintainers
- Configure Slack/Teams integration if desired

## 👥 Step 6: Set Up Team Permissions

### Create Maintainers Team
1. Navigate to `Organization > Teams`
2. Create `@qubinode/maintainers` team
3. Add appropriate maintainers
4. Grant "Write" access to repository

### Configure Review Assignments
In repository settings:
- Set maintainers team as default reviewers
- Configure auto-assignment for Dependabot PRs
- Set up CODEOWNERS file if needed

## ✅ Step 7: Test Dependabot Setup

### Manual Trigger
```bash
# Trigger Dependabot manually (GitHub CLI)
gh api repos/:owner/:repo/dependabot/updates \
  --method POST \
  --field package_ecosystem=github-actions
```

### Verify Configuration
1. Check `Insights > Dependency graph`
2. Review `Security > Dependabot alerts`
3. Monitor `Actions` tab for Dependabot workflows

## 📊 Step 8: Monitor and Maintain

### Weekly Maintenance Tasks
- Review and merge Dependabot PRs
- Check for failed status checks
- Update auto-merge rules if needed
- Review security alerts

### Monthly Review
- Analyze Dependabot insights
- Review update frequency and limits
- Adjust configuration based on PR volume
- Update team assignments if needed

### Quarterly Assessment
- Review overall dependency health
- Update Dependabot configuration
- Assess auto-merge effectiveness
- Plan major dependency upgrades

## 🚨 Troubleshooting

### Common Issues

**Problem**: Dependabot PRs not being created
**Solution**: 
- Verify dependency files exist (requirements.txt, package.json)
- Check Dependabot permissions in organization settings
- Review branch protection rules for conflicts

**Problem**: Auto-merge not working
**Solution**:
- Verify all status checks are passing
- Check that required reviews are satisfied
- Ensure auto-merge is enabled in branch protection

**Problem**: Too many PRs being created
**Solution**:
- Reduce `open-pull-requests-limit` in dependabot.yml
- Change update frequency from daily to weekly
- Restrict allowed update types

### Debug Commands
```bash
# Check Dependabot status
gh api repos/:owner/:repo/dependabot/updates

# List open Dependabot PRs
gh pr list --author "dependabot[bot]"

# Check workflow runs
gh run list --workflow="dependabot-auto-merge.yml"
```

## 🎯 Success Metrics

### Key Performance Indicators
- **Security Response Time**: < 24 hours for critical vulnerabilities
- **Update Frequency**: Weekly for non-security updates
- **Auto-merge Rate**: > 80% for patch updates
- **Manual Review Rate**: < 20% requiring manual intervention

### Monitoring Dashboard
Track these metrics:
- Number of Dependabot PRs per week
- Time to merge security updates
- Failed status checks on Dependabot PRs
- Manual intervention frequency

## 🔗 Related Documentation

- **Release Process**: [Release Process](release-process.md)
- **CI/CD Pipeline**: [CI/CD Pipeline](cicd-pipeline.md)
- **Security**: [Security Testing](security-testing.md)
- **Automation Strategy**: [Automation Philosophy](../../explanations/automation-philosophy.md)

---

*This guide established automated dependency management. For understanding the broader automation strategy, see the explanations section.*
