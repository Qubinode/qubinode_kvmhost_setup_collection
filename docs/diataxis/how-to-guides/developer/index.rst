Developer How-To Guides - Contribution-Oriented
==============================================

Welcome to the developer guides section! These guides help you contribute effectively to the Qubinode KVM Host Setup Collection, from setting up your development environment to submitting high-quality pull requests.

.. note::
   **New contributor?** Start with :doc:`setup-development-environment` to get your development environment ready.

Getting Started as a Contributor
---------------------------------

.. grid:: 1 1 2 2
    :gutter: 3

    .. grid-item-card:: 🛠️ Development Environment
        :link: setup-development-environment
        :link-type: doc

        **Set Up Development Environment**
        
        Complete guide to setting up your local development environment with all required tools and dependencies.

    .. grid-item-card:: 🧪 Testing Framework
        :link: run-molecule-tests
        :link-type: doc

        **Run Molecule Tests**
        
        Learn to run and debug Molecule tests locally to validate your changes before submitting.

    .. grid-item-card:: 🤝 Contributing Process
        :link: contributing-guidelines
        :link-type: doc

        **Contributing Guidelines**
        
        Complete workflow from finding issues to getting your pull requests merged successfully.

Development Workflow Guides
----------------------------

.. grid:: 1 1 2 2
    :gutter: 3

    .. grid-item-card:: ✅ Testing Requirements
        :link: local-testing-requirements
        :link-type: doc

        **Local Testing Requirements**
        
        Mandatory testing procedures that must be followed before pushing code to CI/CD.

    .. grid-item-card:: 🔄 Test Migration
        :link: migrate-molecule-tests
        :link-type: doc

        **Migrate Molecule Tests**
        
        Update existing Molecule configurations to current best practices and standards.

Automation and CI/CD
---------------------

.. grid:: 1 1 2 2
    :gutter: 3

    .. grid-item-card:: 🤖 Dependabot Setup
        :link: setup-dependabot-automation
        :link-type: doc

        **Set Up Dependabot Automation**

        Configure automated dependency management and security updates for the project.

    .. grid-item-card:: 🖥️ GitHub Actions Runner
        :link: setup-github-actions-runner
        :link-type: doc

        **Set Up Self-Hosted Runner**

        Configure a CentOS Stream 10 self-hosted runner for CI/CD pipelines.

Developer Guide Characteristics
-------------------------------

All developer guides in this section:

- **Focus on contribution**: Help you contribute effectively to the project
- **Assume development context**: You're working with source code and development tools
- **Provide complete procedures**: End-to-end workflows from setup to completion
- **Include quality standards**: Code quality, testing, and compliance requirements
- **Support collaboration**: Guidelines for working with the community

Contribution Types
------------------

### Code Contributions
- **Bug fixes**: Resolve issues and improve reliability
- **New features**: Add functionality and capabilities
- **Performance improvements**: Optimize existing code
- **Security enhancements**: Improve security posture

### Documentation Contributions
- **Tutorial improvements**: Enhance learning materials
- **How-to guide additions**: Add solutions for new problems
- **Reference updates**: Keep technical documentation current
- **Explanation enhancements**: Improve architectural understanding

### Testing Contributions
- **Test coverage**: Add tests for untested code
- **Test scenarios**: Create new testing scenarios
- **Test infrastructure**: Improve testing tools and processes
- **Performance testing**: Add performance validation

Development Environment
-----------------------

### Required Tools
- **Git**: Version control and collaboration
- **Python 3.9+**: Runtime environment
- **Ansible 2.13+**: Automation framework
- **Molecule**: Testing framework
- **Container Runtime**: Podman (preferred) or Docker
- **IDE/Editor**: VS Code (recommended) with Ansible extensions

### Optional Tools
- **GitHub CLI**: Enhanced GitHub integration
- **Pre-commit**: Automated code quality checks
- **Ansible Lint**: Code quality validation
- **YAML Lint**: YAML formatting validation

Quality Standards
-----------------

### Code Quality Requirements
- **Ansible Lint**: Must pass without errors
- **YAML Lint**: Proper YAML formatting required
- **Security Scan**: No security vulnerabilities
- **Test Coverage**: All changes must include tests
- **Documentation**: Updates must include documentation changes

### Testing Requirements
- **Local Testing**: All tests must pass locally before pushing
- **Molecule Tests**: Role-specific testing with Molecule
- **Integration Tests**: Multi-role interaction testing
- **Compliance Tests**: ADR compliance validation

### Review Process
- **Automated Checks**: All CI/CD checks must pass
- **Peer Review**: At least one maintainer approval required
- **Documentation Review**: Documentation changes reviewed
- **Security Review**: Security-sensitive changes get additional review

Getting Help
------------

### Community Support
- **GitHub Discussions**: General questions and community support
- **GitHub Issues**: Bug reports and feature requests
- **Maintainer Contact**: Direct contact for complex issues

### Development Resources
- **Architecture Documentation**: :doc:`../../explanations/architecture-overview`
- **Design Decisions**: :doc:`../../explanations/architecture-decisions/index`
- **Technical Reference**: :doc:`../../reference/index`
- **Testing Framework**: :doc:`../../explanations/testing-framework-selection`

Contribution Workflow
---------------------

### Standard Workflow
1. **Set up environment**: :doc:`setup-development-environment`
2. **Find something to work on**: Check GitHub issues or discuss with maintainers
3. **Create feature branch**: Follow Git workflow best practices
4. **Make changes**: Implement your contribution
5. **Test locally**: :doc:`run-molecule-tests` and :doc:`local-testing-requirements`
6. **Submit pull request**: :doc:`contributing-guidelines`
7. **Respond to feedback**: Work with reviewers to refine your contribution

### Advanced Workflows
- **Large features**: Break into smaller, reviewable chunks
- **Breaking changes**: Follow deprecation and migration procedures
- **Security fixes**: Follow responsible disclosure procedures
- **Performance improvements**: Include benchmarking and validation

Next Steps
----------

After setting up your development environment:

1. **Explore the codebase**: Understand the modular architecture
2. **Run existing tests**: Familiarize yourself with the testing framework
3. **Find an issue**: Look for "good first issue" labels on GitHub
4. **Make your first contribution**: Start with documentation or small bug fixes
5. **Engage with community**: Participate in discussions and reviews

.. toctree::
   :maxdepth: 2
   :hidden:
   :caption: Developer Guides

   setup-development-environment
   run-molecule-tests
   contributing-guidelines
   local-testing-requirements
   migrate-molecule-tests
   setup-dependabot-automation
   setup-github-actions-runner
