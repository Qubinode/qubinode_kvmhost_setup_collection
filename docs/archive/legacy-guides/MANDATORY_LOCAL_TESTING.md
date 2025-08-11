# Mandatory Local Testing Rules - Developer Guide

## 🛡️ Critical Quality Gate: Local Testing Before CI/CD

This project enforces **mandatory local testing** before any code can be pushed to GitHub Actions CI/CD. This is a **CRITICAL** architectural rule based on ADR-0011.

## 📋 Rule Summary

- **Rule ID**: `mandatory-local-testing-before-push`
- **Severity**: `CRITICAL`
- **Enforcement**: `BLOCKING`
- **Source**: ADR-0011 (Local Molecule Testing Validation Before CI/CD)

## 🚫 What This Means

**Code CANNOT be pushed to CI/CD unless:**
1. Local testing script exists: `scripts/test-local-molecule.sh`
2. Script is executable: `chmod +x scripts/test-local-molecule.sh`
3. All local Molecule tests pass before commit
4. **ADR-0012 compliance**: Only init containers are used in Molecule configurations
5. Architectural rules compliance is satisfied

## 🔧 Quick Start

### 1. Set Up Your Environment (First Time)
```bash
# Run the automated setup script
./scripts/setup-local-testing.sh
```

### 2. Check Your Compliance
```bash
# Run the compliance check
./scripts/check-compliance.sh
```

### 3. Activate Environment (Each Session)
```bash
# Activate the testing environment
source scripts/activate-molecule-env.sh
```

### 4. Run Local Tests (MANDATORY)
```bash
# Run local Molecule tests before committing
./scripts/test-local-molecule.sh
```

### 5. Set Up Pre-commit Hook (Recommended)
```bash
# Activate the pre-commit hook for automatic validation
cp .git/hooks/pre-commit.example .git/hooks/pre-commit
```

## 📊 Why This Rule Exists

Based on research findings (`docs/research/local-molecule-testing-validation-2025-01-12.md`) and ADR-0012:

- **80% CI/CD failure prevention** through local testing
- **50% faster feedback loops** vs waiting for CI/CD
- **Reduced resource waste** on preventable failures
- **Improved developer experience** with immediate feedback
- **90-98% test success rate** with init containers vs 70-85% with regular containers

## 🛑 What Happens if You Don't Comply

### Pre-commit Hook (if enabled)
- **BLOCKS** commit until tests pass
- Shows detailed error messages
- Guides you to fix issues

### GitHub Actions CI/CD
- **BLOCKS** workflow execution
- `validate-local-testing` job fails
- No compatibility tests run until compliance

### Developer Impact
- Immediate feedback on issues
- Forced to fix problems locally
- Cannot waste CI/CD resources

## 🔍 Architectural Rules Reference

The complete rules are defined in: `rules/local-molecule-testing-rules.json`

### Key Rules:
1. **mandatory-local-testing-before-push** (CRITICAL)
2. **local-molecule-validation** (ERROR)
3. **pre-commit-molecule-hook** (WARNING)
4. **ansible-role-molecule-tests** (ERROR)
5. **adr-0012-init-containers-only** (CRITICAL)

## 📖 Related Documentation

- **ADR-0011**: `docs/adrs/adr-0011-local-molecule-testing-validation-before-cicd.md`
- **ADR-0012**: `docs/adrs/adr-0012-init-container-vs-regular-container-molecule-testing.md`
- **Research**: `docs/research/local-molecule-testing-validation-2025-01-12.md`
- **Rules**: `rules/local-molecule-testing-rules.json`
- **Available Images**: `molecule/AVAILABLE_INIT_IMAGES.md`

## 💡 Developer Workflow

### Recommended Workflow:
1. **First time setup**: `./scripts/setup-local-testing.sh`
2. **Each session**: `source scripts/activate-molecule-env.sh`
3. **Before starting**: `./scripts/check-compliance.sh`
4. **During development**: Make your changes
5. **Before committing**: `./scripts/test-local-molecule.sh`
6. **Commit**: `git commit -m "your message"`
7. **Push**: `git push` (CI/CD will validate compliance)

### If Tests Fail:
1. **Review the output** for specific failures
2. **Fix the issues** in your code
3. **Re-run**: `./scripts/test-local-molecule.sh`
4. **Repeat** until all tests pass
5. **Then commit and push**

## 🆘 Getting Help

### Common Issues:
- **Script not found**: Create `scripts/test-local-molecule.sh`
- **Not executable**: Run `chmod +x scripts/test-local-molecule.sh`
- **Tests failing**: Review test output and fix code issues
- **Non-init images**: Update molecule.yml to use only init containers (see `molecule/AVAILABLE_INIT_IMAGES.md`)
- **ADR-0012 violations**: Replace regular images with init images per documentation
- **Environment issues**: Run `./scripts/setup-local-testing.sh`
- **Molecule not installed**: Run `./scripts/setup-local-testing.sh`
- **Virtual environment**: Use `source scripts/activate-molecule-env.sh`

### Resources:
- **Environment setup**: `./scripts/setup-local-testing.sh`
- **Check compliance**: `./scripts/check-compliance.sh`
- **Activate environment**: `source scripts/activate-molecule-env.sh`
- **Test locally**: `./scripts/test-local-molecule.sh`
- **Pre-commit hook**: `.git/hooks/pre-commit.example`
- **Full documentation**: ADR-0011

---

**Remember**: This rule exists to **help you** catch issues early and avoid CI/CD failures. Local testing is faster and gives you immediate feedback!
