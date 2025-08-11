# Local Testing Requirements

This guide explains the mandatory local testing requirements for contributing to the Qubinode KVM Host Setup Collection, based on ADR-0011.

## 🎯 Goal

Ensure code quality and prevent CI/CD failures by:
- Running comprehensive local tests before pushing code
- Following mandatory testing procedures
- Implementing proper pre-commit validation
- Maintaining ADR compliance

## 📋 Prerequisites

- Completed [Set Up Development Environment](setup-development-environment.md)
- Molecule testing framework configured
- Understanding of project quality standards
- Familiarity with Git workflows

## 🛡️ Mandatory Testing Rules

### Critical Quality Gate
**Code CANNOT be pushed to CI/CD unless:**

1. ✅ Local testing script exists: `scripts/test-local-molecule.sh`
2. ✅ Script is executable: `chmod +x scripts/test-local-molecule.sh`
3. ✅ All local Molecule tests pass before commit
4. ✅ ADR-0012 compliance: Only init containers used in Molecule configurations
5. ✅ Architectural rules compliance satisfied

### Rule Enforcement
- **Rule ID**: `mandatory-local-testing-before-push`
- **Severity**: `CRITICAL`
- **Enforcement**: `BLOCKING`
- **Source**: ADR-0011 (Local Molecule Testing Validation Before CI/CD)

## 🚀 Quick Start Implementation

### Step 1: Set Up Testing Environment
```bash
# Run automated setup (first time only)
./scripts/setup-local-testing.sh

# Verify setup
./scripts/check-compliance.sh
```

### Step 2: Activate Testing Environment
```bash
# Activate for each development session
source scripts/activate-molecule-env.sh

# Verify activation
molecule --version
which molecule
```

### Step 3: Run Mandatory Local Tests
```bash
# MANDATORY: Run before every commit
./scripts/test-local-molecule.sh

# Test specific roles only (if needed)
./scripts/test-local-molecule.sh kvmhost_base kvmhost_networking
```

### Step 4: Set Up Pre-Commit Hook (Recommended)
```bash
# Install pre-commit hook
./scripts/install-pre-commit-hook.sh

# Manual setup if script not available
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "🧪 Running mandatory local tests..."
source scripts/activate-molecule-env.sh
./scripts/test-local-molecule.sh
if [ $? -ne 0 ]; then
    echo "❌ Local tests failed. Commit blocked."
    exit 1
fi
echo "✅ Local tests passed. Proceeding with commit."
EOF

chmod +x .git/hooks/pre-commit
```

## 🔧 Testing Procedures

### Daily Development Workflow

#### Before Starting Work
```bash
# 1. Update from upstream
git fetch upstream
git checkout main
git merge upstream/main

# 2. Activate testing environment
source scripts/activate-molecule-env.sh

# 3. Create feature branch
git checkout -b feature/your-feature
```

#### During Development
```bash
# Test individual roles as you work
cd roles/modified_role
molecule test --scenario-name default

# Quick syntax check
ansible-lint roles/modified_role/
yamllint roles/modified_role/
```

#### Before Committing
```bash
# MANDATORY: Run full test suite
./scripts/test-local-molecule.sh

# Additional quality checks
ansible-lint .
yamllint .
./scripts/check-compliance.sh
```

### Testing Scope Requirements

#### Minimum Testing Requirements
- **Modified Roles**: All roles you've changed must pass tests
- **Integration Tests**: Test role interactions if multiple roles modified
- **Lint Checks**: All linting must pass without errors
- **Compliance**: All ADR compliance checks must pass

#### Comprehensive Testing (Recommended)
```bash
# Full test suite
./scripts/test-local-molecule.sh

# Security scanning
./scripts/enhanced-security-scan.sh

# Performance validation
./scripts/performance-test.sh

# Documentation validation
./scripts/validate-documentation.sh
```

## 📊 Test Execution Standards

### Test Performance Targets
- **Individual Role Tests**: < 5 minutes per role
- **Full Test Suite**: < 30 minutes total
- **Lint Checks**: < 2 minutes
- **Compliance Checks**: < 1 minute

### Resource Requirements
- **Memory**: 4GB+ available for container testing
- **CPU**: 2+ cores for parallel testing
- **Storage**: 10GB+ free space for container images
- **Network**: Stable connection for image downloads

### Test Environment Isolation
```bash
# Clean environment before testing
podman system prune -f
docker system prune -f  # if using Docker

# Set unique test directory
export MOLECULE_EPHEMERAL_DIRECTORY=/tmp/molecule-$(date +%s)

# Run tests in isolation
./scripts/test-local-molecule.sh
```

## 🚨 Failure Handling

### When Tests Fail

#### Immediate Actions
1. **Do NOT push code** - Fix issues locally first
2. **Analyze failure logs** - Understand what went wrong
3. **Fix the issues** - Address root causes, not symptoms
4. **Re-run tests** - Verify fixes work
5. **Only then commit** - After all tests pass

#### Common Failure Scenarios

**Lint Failures**
```bash
# Fix Ansible lint issues
ansible-lint --fix .

# Fix YAML formatting
yamllint . --format parsable | while read line; do
    # Address each issue manually
done
```

**Molecule Test Failures**
```bash
# Debug failed tests
cd roles/failing_role
molecule test --debug

# Interactive debugging
molecule create
molecule login
# Debug inside container
```

**Compliance Failures**
```bash
# Check specific compliance issues
./scripts/check-compliance.sh --verbose

# Fix ADR compliance issues
./scripts/fix-adr-compliance.sh
```

## 🔄 Continuous Improvement

### Test Optimization
- **Parallel Execution**: Run independent tests in parallel
- **Caching**: Use container image caching
- **Selective Testing**: Test only changed components when appropriate

### Monitoring Test Health
```bash
# Track test execution times
./scripts/test-local-molecule.sh --timing

# Monitor resource usage
htop  # During test execution

# Check test coverage
./scripts/generate-test-coverage.sh
```

## 📚 Best Practices

### Test Development
- **Write tests first** - TDD approach for new features
- **Test edge cases** - Don't just test happy paths
- **Use realistic data** - Test with production-like configurations
- **Document test scenarios** - Explain what each test validates

### Performance Optimization
- **Use local images** - Cache container images locally
- **Parallel testing** - Run independent tests concurrently
- **Resource monitoring** - Watch memory and CPU usage
- **Clean up regularly** - Remove unused containers and images

### Quality Assurance
- **Consistent environments** - Use same test setup across team
- **Reproducible results** - Tests should be deterministic
- **Clear failure messages** - Make test failures easy to understand
- **Regular maintenance** - Keep test infrastructure updated

## 🔗 Related Documentation

- **Setup**: [Set Up Development Environment](setup-development-environment.md)
- **Testing**: [Run Molecule Tests](run-molecule-tests.md)
- **Migration**: [Migrate Molecule Tests](migrate-molecule-tests.md)
- **ADR**: [ADR-0011 Local Testing](../../explanations/architecture-decisions/adr-0011-local-molecule-testing.md)

---

*This guide established mandatory testing requirements. For understanding the testing philosophy, see the explanations section. For specific testing procedures, check the testing guides.*
