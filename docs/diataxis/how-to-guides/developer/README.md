# Developer How-To Guides - Contribution-Oriented Documentation

Welcome to the Developer How-To Guides! This section is specifically for developers and contributors who want to work with the source code, contribute to the project, or understand the development process.

## 🎯 What You'll Find Here

Developer How-To Guides are **contribution-oriented** and designed for:
- Developers who want to contribute to the collection
- Contributors setting up development environments
- Maintainers working on the codebase
- Anyone interested in the development and testing process

## 📋 Available Developer Guides

### Development Environment
- [Set Up Development Environment](setup-development-environment.md) - Complete dev environment setup
- [Configure IDE and Tools](configure-ide-tools.md) - Optimize your development workflow
- [Set Up Local Testing](setup-local-testing.md) - Run tests locally before CI/CD
- [Container Development Setup](container-development.md) - Develop using containers

### Testing and Quality Assurance
- [Run Molecule Tests](run-molecule-tests.md) - Execute local testing with Molecule
- [Ansible Lint Integration](ansible-lint-integration.md) - Code quality and linting
- [Security Testing](security-testing.md) - Run security scans and validation
- [Performance Testing](performance-testing.md) - Benchmark and performance validation

### Building and Packaging
- [Build Collection from Source](build-from-source.md) - Create collection packages
- [Release Process](release-process.md) - How releases are created and deployed
- [Version Management](version-management.md) - Semantic versioning and tagging
- [Galaxy Publishing](galaxy-publishing.md) - Deploy to Ansible Galaxy

### Contribution Workflow
- [Contributing Guidelines](contributing-guidelines.md) - How to contribute effectively
- [Code Review Process](code-review-process.md) - Understanding the review workflow
- [Issue and PR Templates](issue-pr-templates.md) - Using project templates
- [Documentation Updates](documentation-updates.md) - Maintaining documentation

### Architecture and Design
- [Role Development](role-development.md) - Creating and modifying roles
- [Module Development](module-development.md) - Custom module development
- [Testing Framework](testing-framework.md) - Understanding the test architecture
- [CI/CD Pipeline](cicd-pipeline.md) - GitHub Actions workflow details

### CI/CD Infrastructure
- [Set Up GitHub Actions Runner](setup-github-actions-runner.md) - Configure CentOS Stream 10 self-hosted runner

### Advanced Development
- [Debugging Techniques](debugging-techniques.md) - Troubleshoot development issues
- [Custom Molecule Scenarios](custom-molecule-scenarios.md) - Advanced testing scenarios
- [Integration Testing](integration-testing.md) - End-to-end testing strategies
- [Automation Development](automation-development.md) - Extending automation capabilities

## 🛠️ Developer Guide Characteristics

Each guide in this section:
- **Assumes development context** - You're working with source code
- **Covers development tools** - IDEs, testing frameworks, build tools
- **Includes setup instructions** - Environment configuration and dependencies
- **Focuses on contribution** - How to effectively contribute to the project
- **Provides troubleshooting** - Common development issues and solutions

## 🚀 Getting Started as a Developer

### Prerequisites
- Git installed and configured
- Python 3.9+ with pip
- Ansible 2.13+ installed
- Container runtime (Podman or Docker)
- Basic understanding of Ansible collections

### Quick Start
1. **Fork and clone the repository**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/qubinode_kvmhost_setup_collection.git
   cd qubinode_kvmhost_setup_collection
   ```

2. **Set up development environment**:
   ```bash
   # Follow the detailed guide: setup-development-environment.md
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements-dev.txt
   ```

3. **Run initial tests**:
   ```bash
   # Follow the detailed guide: setup-local-testing.md
   source scripts/activate-molecule-env.sh
   scripts/test-local-molecule.sh
   ```

## 🔧 Development Tools

### Required Tools
- **Python 3.9+**: Core development language
- **Ansible 2.13+**: Collection framework
- **Molecule 6.0+**: Testing framework
- **Podman/Docker**: Container testing
- **Git**: Version control

### Recommended Tools
- **VS Code**: With Ansible and Python extensions
- **ansible-lint**: Code quality checking
- **yamllint**: YAML formatting
- **pytest**: Python testing framework
- **bandit**: Security scanning

## 📚 Development Resources

### Internal Documentation
- [Architecture Decision Records](../../adrs/) - Design decisions and rationale
- [Testing Documentation](../../../testing.md) - Comprehensive testing guide
- [Contributing Guidelines](../../../CONTRIBUTING.md) - Project contribution rules

### External Resources
- [Ansible Collection Development Guide](https://docs.ansible.com/ansible/devel/dev_guide/developing_collections.html)
- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

## 🤝 Contributing Process

1. **Read the guidelines**: Start with [Contributing Guidelines](contributing-guidelines.md)
2. **Set up environment**: Follow [Set Up Development Environment](setup-development-environment.md)
3. **Make changes**: Develop your feature or fix
4. **Test locally**: Use [Run Molecule Tests](run-molecule-tests.md)
5. **Submit PR**: Follow [Code Review Process](code-review-process.md)

## 🔗 Related Documentation

- **Learning the collection?** Start with [Tutorials](../../tutorials/)
- **Using the collection?** Check [How-To Guides](../)
- **Need technical details?** See [Reference](../../reference/)
- **Understanding design?** Read [Explanations](../../explanations/)

---

*This section is specifically for developers and contributors. End-users should refer to the main [How-To Guides](../) section for usage-focused documentation.*
