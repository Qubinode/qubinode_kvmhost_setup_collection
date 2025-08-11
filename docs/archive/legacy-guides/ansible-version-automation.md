# Ansible Version Automation System

## 🎯 Overview

This document describes the automated system that monitors for new Ansible versions, tests compatibility, and creates pull requests when newer versions pass all tests.

## 🚀 How It Works

### Automated Monitoring
- **Schedule**: Runs every Tuesday at 8 AM UTC
- **Trigger**: Can be manually triggered via GitHub Actions
- **Detection**: Checks PyPI for new stable ansible-core releases
- **Testing**: Comprehensive compatibility testing before PR creation

### Version Management Strategy
The system manages Ansible versions across multiple configuration files:
- `requirements.txt` - Python package requirements
- `pyproject.toml` - Project metadata and dependencies
- `.github/workflows/ansible-test.yml` - CI/CD test matrix
- `.github/config/future-compatibility-config.yml` - Compatibility testing

## 📋 Automated Testing Suite

### Critical Tests Performed
1. **Installation Test**: Verify new Ansible version installs correctly
2. **Dependencies Test**: Ensure all project dependencies are compatible
3. **Basic Functionality**: Test core Ansible commands work
4. **Ansible Lint**: Verify ansible-lint compatibility
5. **Collections**: Test Ansible Galaxy collection installation
6. **Syntax Check**: Validate playbook syntax with new version

### Test Results Classification
- **✅ All Tests Passed**: Automatic PR creation, ready for review
- **⚠️ Mixed Results**: PR created as draft, manual review required
- **❌ Critical Failures**: No PR created, issue logged for investigation

## 🔧 Configuration Files Updated

### Automatic Updates
When a new compatible version is found, the system updates:

```yaml
# requirements.txt
ansible-core>=2.19.0,<2.20.0  # Updated version constraint

# pyproject.toml
dependencies = [
    "ansible-core>=2.19.0,<2.20.0",  # Updated dependency
    # ... other dependencies
]

# .github/workflows/ansible-test.yml
matrix:
  ansible-version: ["2.19"]  # Updated test matrix

# .github/config/future-compatibility-config.yml
ansible_versions:
  stable:
    - "2.19"  # Updated stable version
```

## 🛠️ Manual Usage

### Check Current Status
```bash
# Run local version check and testing
./scripts/check-ansible-versions.sh

# Manual trigger with interactive options
./scripts/trigger-ansible-update.sh
```

### Trigger Workflow Manually
```bash
# Using GitHub CLI - automatic version detection
gh workflow run ansible-version-auto-pr.yml --field force_check=true

# Test specific version
gh workflow run ansible-version-auto-pr.yml --field target_version=2.19.0

# Or via GitHub web interface:
# Actions → Ansible Version Auto-Update → Run workflow
```

## 📊 Monitoring and Reporting

### Status Tracking
The system provides comprehensive reporting:
- **JSON Reports**: Detailed test results and version information
- **PR Descriptions**: Complete test summaries and validation checklists
- **GitHub Labels**: Automatic categorization and priority assignment

### Output Files
- `ansible-version-status.json` - Detailed version and test status
- `ANSIBLE_UPDATE_SUMMARY.md` - Human-readable update summary
- Test result logs for each component

## 🎯 Decision Logic

### PR Creation Criteria
```bash
# Conditions for PR creation:
1. New stable version available on PyPI
2. Version is higher than current project version
3. Installation test passes
4. Basic functionality test passes
5. No existing PR for Ansible updates

# PR Status:
- Draft: If any non-critical tests fail
- Ready for Review: If all critical tests pass
```

### Version Selection Strategy
- **Stable Releases Only**: No pre-releases or development versions
- **Incremental Updates**: Prefers minor version updates over major
- **Compatibility First**: Tests thoroughly before recommending updates

## 🔍 Test Environment

### Isolated Testing
```bash
# Each test runs in isolated virtual environment:
python3 -m venv ansible-test-venv
source ansible-test-venv/bin/activate
pip install "ansible-core==X.Y.Z.*"
# Run comprehensive test suite
deactivate
rm -rf ansible-test-venv
```

### Test Coverage
- **Installation Compatibility**: Package installation and dependencies
- **Runtime Functionality**: Core Ansible commands and operations
- **Tool Integration**: ansible-lint, molecule, and other tools
- **Project Compatibility**: Collection requirements and syntax validation

## 📋 Pull Request Content

### Automated PR Includes
- **Version Comparison**: Clear before/after version information
- **Test Results**: Comprehensive test result summary
- **File Changes**: List of all updated configuration files
- **Validation Checklist**: Manual review and testing requirements
- **Release Notes**: Links to official Ansible release documentation

### Review Requirements
- [ ] Manual review of automated test results
- [ ] Full molecule test suite execution
- [ ] Performance regression testing
- [ ] Documentation updates if needed
- [ ] Deprecation warning review

## 🚨 Error Handling

### Common Issues and Solutions

#### Installation Failures
```bash
# Issue: New version fails to install
# Solution: Check for dependency conflicts
pip install "ansible-core==X.Y.Z.*" --verbose
```

#### Compatibility Issues
```bash
# Issue: ansible-lint incompatibility
# Solution: Update ansible-lint version constraint
pip install "ansible-lint>=Y.Z.0"
```

#### Collection Problems
```bash
# Issue: Collection installation fails
# Solution: Update collection requirements
ansible-galaxy collection install -r requirements.yml --force
```

## 📈 Benefits

### Automation Advantages
- **⚡ Rapid Updates**: Immediate detection and testing of new versions
- **🔄 Consistency**: Standardized update process across all files
- **📊 Comprehensive Testing**: Thorough compatibility validation
- **🚀 Reduced Overhead**: Eliminates manual version monitoring

### Quality Assurance
- **✅ Automated Testing**: Comprehensive test suite before updates
- **📝 Documentation**: Complete change tracking and validation
- **🏷️ Proper Labeling**: Automatic GitHub issue categorization
- **👥 Review Process**: Maintains code review standards

## 🔮 Future Enhancements

### Planned Improvements
- **Performance Benchmarking**: Automated performance regression testing
- **Security Scanning**: Integration with security vulnerability checks
- **Multi-Version Testing**: Test against multiple Ansible versions simultaneously
- **Rollback Automation**: Automatic rollback on critical failures

### Integration Opportunities
- **Slack/Teams Notifications**: Real-time update notifications
- **Dependency Tracking**: Monitor related package updates
- **Release Calendar**: Integration with Ansible release schedules
- **Custom Test Scenarios**: Project-specific compatibility tests

## 🎯 Best Practices

### Maintenance Guidelines
1. **Regular Review**: Weekly review of automation logs and results
2. **Test Validation**: Always run full test suite after updates
3. **Documentation**: Keep version compatibility matrix updated
4. **Monitoring**: Watch for patterns in test failures or issues

### Integration with Development Workflow
1. **Branch Strategy**: Automated PRs use consistent branch naming
2. **Review Process**: Standard code review applies to automated PRs
3. **Testing Requirements**: Full validation before merging
4. **Release Planning**: Coordinate with project release cycles

---

*This automated system ensures the project stays current with Ansible developments while maintaining stability and compatibility.*
