# Ansible Galaxy Release Strategy

## 🎯 Overview

This document outlines the comprehensive release strategy for the Qubinode KVM Host Setup Collection, implementing automated releases triggered by dependency updates with manual override capabilities.

## 🤖 Automated Release Strategy

### Primary Strategy: Dependency-Triggered Releases

**Workflow**: `.github/workflows/auto-release-on-dependencies.yml`

**Trigger Conditions:**
- Dependabot PRs merged with `dependencies` label
- Automatic version bumping based on dependency type
- Comprehensive pre-release validation

**Release Type Mapping:**
```yaml
Python dependencies (pip):     → patch release (0.9.0 → 0.9.1)
GitHub Actions dependencies:   → patch release (0.9.0 → 0.9.1)
Docker dependencies:          → patch release (0.9.0 → 0.9.1)
Ansible dependencies:         → minor release (0.9.0 → 0.10.0)
Breaking changes detected:    → major release (0.9.0 → 1.0.0)
```

**Dependabot Schedule (ADR-0009 Implementation):**
- **Monday 9:00 AM ET**: GitHub Actions dependencies
- **Tuesday 9:00 AM ET**: Docker dependencies (Molecule testing)
- **Wednesday 9:00 AM ET**: Python dependencies
- **Thursday 9:00 AM ET**: Ansible Galaxy dependencies

### Automated Workflow Process

1. **Dependency Change Detection**:
   - Analyzes merged PR labels for dependency types
   - Determines appropriate release type based on dependency category
   - Checks commit messages for breaking changes

2. **Pre-Release Validation**:
   - Runs `scripts/check-compliance.sh`
   - Executes `scripts/enhanced-security-scan.sh`
   - Validates collection structure with `ansible-galaxy collection build`

3. **Version Management**:
   - Automatically calculates new version based on semantic versioning
   - Updates `galaxy.yml` and `Makefile` with new version
   - Commits version changes to repository

4. **Release Creation**:
   - Creates annotated git tag with comprehensive release information
   - Triggers existing `release.yml` workflow for Galaxy deployment
   - Generates automated release notes

## 🛠️ Manual Release Strategy

### Manual Release Workflow

**Workflow**: `.github/workflows/manual-release.yml`

**Use Cases:**
- Feature releases not triggered by dependencies
- Emergency releases requiring immediate deployment
- Custom versioning requirements
- Releases with custom release notes

**Manual Trigger Options:**
```yaml
Version: "1.0.0"           # Custom version number
Release Type: patch/minor/major
Release Notes: "Custom release description"
Skip Validation: false    # Safety option for emergencies
Dry Run: false           # Test mode without actual release
```

### Manual Process Steps

1. **Navigate to GitHub Actions**:
   - Go to repository → Actions → "Manual Release Trigger"
   - Click "Run workflow"

2. **Configure Release Parameters**:
   - Enter desired version (e.g., "1.0.0")
   - Select release type (patch/minor/major)
   - Add custom release notes (optional)
   - Choose validation options

3. **Validation and Deployment**:
   - Automated validation runs (unless skipped)
   - Version files updated automatically
   - Release tag created and pushed
   - Galaxy deployment triggered via existing release.yml

## 📋 Release Validation Requirements

### Pre-Release Checklist (Automated)

**Compliance Validation:**
- ✅ ADR compliance check (`scripts/check-compliance.sh`)
- ✅ File structure validation (`scripts/validate-file-structure.sh`)
- ✅ Security scan (`scripts/enhanced-security-scan.sh`)

**Build Validation:**
- ✅ Collection build test (`ansible-galaxy collection build`)
- ✅ Syntax validation
- ✅ Metadata validation

**Version Consistency:**
- ✅ `galaxy.yml` version updated
- ✅ `Makefile` TAG updated
- ✅ Semantic versioning compliance

### Manual Validation (Optional)

**Local Testing (Recommended):**
```bash
# Run comprehensive local validation
source scripts/activate-molecule-env.sh
scripts/test-local-molecule.sh
scripts/check-compliance.sh
scripts/enhanced-security-scan.sh
```

## 🔄 Version Management Strategy

### Semantic Versioning Implementation

**Version Format**: `MAJOR.MINOR.PATCH`

**Version Bump Rules:**
- **PATCH** (0.9.0 → 0.9.1): Bug fixes, dependency updates, documentation
- **MINOR** (0.9.0 → 0.10.0): New features, Ansible dependency updates
- **MAJOR** (0.9.0 → 1.0.0): Breaking changes, major architectural changes

**Current Version**: 0.9.0 (January 6, 2025)
**Next Recommended**: 0.10.0 (minor - for LLM documentation enhancement)

## 🚀 Galaxy Deployment Process

### Automated Deployment (Primary)

**Trigger**: Git tag creation (v*)
**Workflow**: `.github/workflows/release.yml`

**Process:**
1. **Build Collection**: Creates collection tarball
2. **Create GitHub Release**: With installation instructions
3. **Deploy to Galaxy**: Using `GALAXY_API_KEY` secret
4. **Artifact Upload**: Uploads collection tarball to GitHub release

### Deployment Requirements

**Required Secrets:**
- `GALAXY_API_KEY`: Ansible Galaxy API key for publishing
- `ACCESS_TOKEN`: GitHub token for release creation

**Build Process:**
```bash
# Collection structure copied to build/src
mkdir -p build/src
cp README.md LICENSE ansible.cfg galaxy.yml build/src
cp -rf inventories roles meta build/src

# Build collection
ansible-galaxy collection build build/src --force

# Deploy to Galaxy
ansible-galaxy collection publish tosin2013-qubinode_kvmhost_setup_collection-$VERSION.tar.gz --api-key $GALAXY_API_KEY
```

## 📊 Release Frequency Strategy

### Automated Release Cadence

**Weekly Dependency Releases:**
- **Monday-Thursday**: Dependabot creates PRs
- **Upon Merge**: Automatic patch releases for dependency updates
- **Expected Frequency**: 1-4 releases per week during active dependency updates

**Feature Releases:**
- **Manual Trigger**: For new features and major enhancements
- **Quarterly Target**: Major feature releases every 3-4 months
- **As Needed**: Critical fixes and important enhancements

### Release Planning

**Current Situation (January 2025):**
- Last release: v0.9.0 (January 6, 2025)
- Major enhancement: LLM-friendly documentation (ready for release)
- Recommendation: Create v0.10.0 for documentation enhancement

**Immediate Next Steps:**
1. **v0.10.0**: LLM documentation enhancement (minor release)
2. **v0.10.x**: Dependency updates (automated patch releases)
3. **v1.0.0**: Consider for major milestone when RHEL 10 support is complete

## 🛡️ Release Safety and Rollback

### Safety Measures

**Pre-Release Validation:**
- Comprehensive testing suite execution
- Security scanning and compliance checks
- Collection build validation

**Rollback Capabilities:**
- Git tag deletion and recreation
- Galaxy version management
- GitHub release editing and deletion

### Emergency Procedures

**Failed Release Recovery:**
```bash
# Delete failed tag
git tag -d v0.10.0
git push origin :refs/tags/v0.10.0

# Fix issues and recreate
git tag -a v0.10.0 -m "Fixed release"
git push origin v0.10.0
```

## 📈 Success Metrics

**Release Quality Indicators:**
- ✅ All automated tests pass
- ✅ Security scans show no critical issues
- ✅ Galaxy deployment succeeds
- ✅ Collection installs correctly from Galaxy

**Monitoring:**
- Galaxy download statistics
- GitHub release download counts
- Issue reports related to releases
- Community feedback and adoption

## 🎯 Recommended Immediate Action

**For Current LLM Documentation Enhancement:**

1. **Create v0.10.0 Release** (minor version for significant documentation enhancement)
2. **Use Manual Release Workflow** with custom release notes highlighting LLM capabilities
3. **Enable Automated Releases** for future dependency updates

**Command to Execute:**
- Navigate to GitHub Actions → "Manual Release Trigger"
- Version: "0.10.0"
- Release Type: "minor"
- Release Notes: "Major LLM-friendly documentation enhancement - all 62 scripts now include comprehensive AI assistant guidance"
