# How to Contribute to the Project

This guide walks you through the complete contribution process, from identifying what to work on to getting your changes merged.

## 🎯 Goal

Successfully contribute to the Qubinode KVM Host Setup Collection by:
- Following established workflows and standards
- Writing quality code that passes all checks
- Creating effective pull requests
- Collaborating effectively with maintainers

## 📋 Prerequisites

- Completed [Set Up Development Environment](setup-development-environment.md)
- Completed [Run Molecule Tests](run-molecule-tests.md)
- Familiarity with Git workflows
- Understanding of Ansible best practices

## 🚀 Step 1: Find Something to Work On

### Check Existing Issues
```bash
# Browse issues on GitHub
# https://github.com/Qubinode/qubinode_kvmhost_setup_collection/issues

# Look for labels:
# - "good first issue" - Great for new contributors
# - "help wanted" - Community contributions welcome
# - "bug" - Bug fixes needed
# - "enhancement" - New features
```

### Identify Improvement Areas
- Review [TODO.md](../../../TODO.md) for planned work
- Check [Architecture Decision Records](../../../docs/adrs/) for implementation needs
- Look at failing tests in CI/CD
- Review user feedback and feature requests

### Propose New Features
```bash
# Create feature proposal issue
# Include:
# - Clear problem statement
# - Proposed solution
# - Implementation approach
# - Testing strategy
```

## 📝 Step 2: Plan Your Contribution

### Create Implementation Plan
1. **Understand the scope** - What exactly needs to be changed?
2. **Identify affected components** - Which roles, files, tests?
3. **Plan testing approach** - How will you validate the changes?
4. **Consider breaking changes** - Will this affect existing users?

### Check Architecture Compliance
```bash
# Review relevant ADRs
ls docs/adrs/
cat docs/adrs/adr-0002-ansible-role-based-modular-architecture.md

# Run compliance checks
scripts/check-compliance.sh
```

## 🔧 Step 3: Implement Your Changes

### Create Feature Branch
```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/descriptive-name

# Or for bug fixes
git checkout -b fix/issue-number-description
```

### Follow Coding Standards

#### Ansible Best Practices
```yaml
# Use descriptive task names
- name: "Install libvirt packages for KVM host setup"
  ansible.builtin.package:
    name: "{{ libvirt_packages }}"
    state: present

# Use proper variable naming
kvm_host_bridge_name: "qubibr0"  # Good
bridge: "qubibr0"                # Avoid

# Include proper tags
- name: "Configure network bridge"
  tags:
    - networking
    - bridge_config
```

#### File Organization
```bash
# Follow role structure
roles/role_name/
├── defaults/main.yml      # Default variables
├── handlers/main.yml      # Handlers
├── meta/main.yml         # Role metadata
├── tasks/main.yml        # Main tasks
├── templates/            # Jinja2 templates
├── vars/main.yml         # Role variables
└── README.md            # Role documentation
```

### Write Tests for Your Changes

#### Create Molecule Tests
```bash
# Navigate to role directory
cd roles/your_role

# Create test scenario if needed
molecule init scenario your-test

# Edit test playbook
vim molecule/your-test/converge.yml
```

#### Write Verification Tests
```python
# In molecule/default/tests/test_your_feature.py
def test_your_feature(host):
    """Test that your feature works correctly."""
    # Test service is running
    service = host.service("your-service")
    assert service.is_running
    
    # Test configuration file exists
    config = host.file("/etc/your-service/config.conf")
    assert config.exists
    assert config.contains("expected_setting")
```

## ✅ Step 4: Validate Your Changes

### Run Local Tests
```bash
# Test the specific role you modified
cd roles/modified_role
molecule test

# Run collection-wide tests
cd ../..
scripts/test-local-molecule.sh

# Run linting
ansible-lint .
yamllint .
```

### Test Integration
```bash
# Test role interactions
ansible-playbook -i inventories/molecule/hosts test-modular.yml

# Test with different variables
ansible-playbook -i inventories/molecule/hosts test-modular.yml \
  -e "custom_test_var=value"
```

### Security and Compliance
```bash
# Run security scans
scripts/enhanced-security-scan.sh

# Check compliance
scripts/check-compliance.sh

# Validate against ADRs
scripts/adr-compliance-checker.sh
```

## 📤 Step 5: Submit Your Contribution

### Prepare Your Commits

#### Write Good Commit Messages
```bash
# Follow conventional commit format
git commit -m "feat(kvmhost_base): add support for custom package repositories

- Add repository configuration variables
- Implement repository validation
- Update documentation and tests
- Resolves #123"

# For bug fixes
git commit -m "fix(kvmhost_networking): resolve bridge creation race condition

- Add proper wait conditions for NetworkManager
- Improve error handling for bridge conflicts
- Add additional validation checks
- Fixes #456"
```

#### Organize Your Commits
```bash
# Squash related commits if needed
git rebase -i HEAD~3

# Ensure clean commit history
git log --oneline -5
```

### Create Pull Request

#### Push Your Branch
```bash
# Push to your fork
git push origin feature/your-feature-name
```

#### Pull Request Template
When creating the PR, include:

```markdown
## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Local Molecule tests pass
- [ ] Integration tests pass
- [ ] Security scans pass
- [ ] Compliance checks pass

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] Changelog entry added (if applicable)

## Related Issues
Closes #issue_number
```

## 🔄 Step 6: Respond to Review Feedback

### Address Review Comments
```bash
# Make requested changes
# Commit changes
git add .
git commit -m "address review feedback: improve error handling"

# Push updates
git push origin feature/your-feature-name
```

### Update Documentation
```bash
# Update role README if needed
vim roles/role_name/README.md

# Update collection documentation
vim docs/diataxis/reference/roles/role_name.md

# Update changelog if significant
vim CHANGELOG.rst
```

## 📚 Contribution Standards

### Code Quality Requirements
- **Ansible Lint**: Must pass without errors
- **YAML Lint**: Proper YAML formatting
- **Security Scan**: No security vulnerabilities
- **Tests**: All tests must pass
- **Documentation**: Updated for changes

### Review Criteria
Reviewers will check:
- **Functionality**: Does it work as intended?
- **Quality**: Follows coding standards?
- **Testing**: Adequate test coverage?
- **Documentation**: Clear and complete?
- **Compatibility**: Doesn't break existing functionality?

### Merge Requirements
- ✅ All CI/CD checks pass
- ✅ At least one maintainer approval
- ✅ No merge conflicts
- ✅ Documentation updated
- ✅ Tests added/updated

## 🤝 Working with Maintainers

### Communication Best Practices
- **Be clear and specific** in issue descriptions
- **Provide context** for your changes
- **Ask questions** if requirements are unclear
- **Be patient** - reviews take time
- **Be responsive** to feedback

### Getting Help
- **GitHub Discussions**: For general questions
- **Issues**: For specific problems or bugs
- **Draft PRs**: For early feedback on approach
- **Maintainer mentions**: For urgent issues

## 🔧 Advanced Contribution Scenarios

### Large Feature Development
```bash
# Create feature branch early
git checkout -b feature/large-feature

# Make incremental commits
git commit -m "feat: add basic structure"
git commit -m "feat: implement core functionality"
git commit -m "feat: add comprehensive tests"

# Keep branch updated
git fetch upstream
git rebase upstream/main
```

### Bug Fix Contributions
```bash
# Create bug fix branch
git checkout -b fix/issue-123-network-timeout

# Write failing test first
# Implement fix
# Verify test passes
# Submit PR with test and fix
```

## 📊 Tracking Your Contributions

### Monitor Your PRs
```bash
# Check PR status
gh pr status  # Using GitHub CLI

# View CI/CD results
gh pr checks PR_NUMBER
```

### Contribution Metrics
- Track your merged PRs
- Monitor issue resolution
- Participate in discussions
- Help other contributors

## 🔗 Related Documentation

- **Previous**: [Run Molecule Tests](run-molecule-tests.md)
- **Next**: [Code Review Process](code-review-process.md)
- **Reference**: [Project Standards](../../reference/project-standards.md)
- **Main Guidelines**: [CONTRIBUTING.md](../../../CONTRIBUTING.md)

---

*This guide covered the complete contribution process. For understanding the review process, see the code review guide. For project standards and requirements, check the reference documentation.*
