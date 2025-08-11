# Diátaxis Documentation Migration Plan

This document outlines the comprehensive plan for migrating existing documentation into the Diátaxis framework structure.

## 📊 Current Documentation Analysis

### Documentation Inventory

#### User-Facing Documentation (End-User Focus)
- `USER_INSTALLATION_GUIDE.md` → **Tutorial** (comprehensive installation walkthrough)
- `migration_guide.md` → **How-To Guide** (migration procedures)
- `compatibility_report.md` → **Reference** (compatibility matrix)
- `FEATURE_COMPATIBILITY_MATRIX.md` → **Reference** (feature support matrix)

#### Developer Documentation (Contribution Focus)
- `DEPENDABOT_SETUP_GUIDE.md` → **Developer How-To** (automation setup)
- `ANSIBLE_LINT_AUTOMATION.md` → **Developer How-To** (code quality automation)
- `MOLECULE_MIGRATION_GUIDE.md` → **Developer How-To** (testing framework migration)
- `MOLECULE_SYSTEMD_TROUBLESHOOTING.md` → **Developer How-To** (testing troubleshooting)
- `MANDATORY_LOCAL_TESTING.md` → **Developer How-To** (testing requirements)
- `local-molecule-setup.md` → **Developer How-To** (testing setup)
- `TDD_COVERAGE_REPORT.md` → **Developer Reference** (test coverage data)
- `TDD_STATUS_REPORT.md` → **Developer Reference** (testing status)

#### Technical Reference Documentation
- `ANSIBLE_COLLECTION_SECURITY.md` → **Reference** (security specifications)
- `REDHAT_REGISTRY_SETUP.md` → **Reference** (registry configuration)
- `role_interface_standards.md` → **Reference** (API specifications)
- `variable_naming_conventions.md` → **Reference** (coding standards)
- `compatibility_matrix.json` → **Reference** (machine-readable compatibility data)

#### Architectural and Design Documentation
- `DEVOPS_AUTOMATION_FRAMEWORK.md` → **Explanation** (automation philosophy)
- `AUTOMATION_ENABLEMENT_STRATEGY.md` → **Explanation** (automation strategy)
- `RELEASE_STRATEGY.md` → **Explanation** (release philosophy)
- All ADRs in `adrs/` → **Explanations** (design decisions)

#### Process and Workflow Documentation
- `AUTOMATION_SUCCESS_REPORT.md` → **Developer Reference** (automation status)
- `GEMINI_LINT_WORKFLOW.md` → **Developer How-To** (AI-assisted workflows)
- `AIDER_LINT_INTEGRATION.md` → **Developer How-To** (tool integration)
- `WORKFLOW_FAILURE_ANALYZER.md` → **Developer How-To** (troubleshooting workflows)

#### Research and Analysis Documentation
- `research/` directory → **Explanations** (research findings and context)
- `audit-reports/` → **Developer Reference** (audit results)
- `session-reports/` → **Developer Reference** (implementation reports)

#### Temporary/Working Documentation
- `action-plan-sprint.md` → **Archive** (outdated planning)
- `sprint-progress-*.md` → **Archive** (historical progress)
- `todo.md` → **Developer Reference** (current roadmap)
- `fix-stuck-containers-summary.md` → **Archive** (resolved issue)
- `container-testing-improvements-*.md` → **Archive** (completed improvements)

## 🎯 Migration Strategy

### Phase 1: User-Facing Documentation Migration

#### Tutorials Migration
1. **Merge USER_INSTALLATION_GUIDE.md** into existing tutorials:
   - Extract step-by-step sections → enhance existing tutorials
   - Move quick start → create new "Quick Start Tutorial"
   - Preserve troubleshooting → move to how-to guides

2. **Create Missing Tutorials**:
   - Advanced multi-host setup (from USER_INSTALLATION_GUIDE.md)
   - Migration procedures (from migration_guide.md)

#### How-To Guides Migration
1. **Extract problem-solving sections** from various guides
2. **Create new how-to guides** for:
   - System migration procedures
   - Troubleshooting specific issues
   - Configuration management tasks

#### Reference Migration
1. **Consolidate compatibility information**:
   - Merge compatibility_report.md and FEATURE_COMPATIBILITY_MATRIX.md
   - Convert compatibility_matrix.json to readable reference
2. **Create comprehensive reference sections**:
   - Security specifications from ANSIBLE_COLLECTION_SECURITY.md
   - Registry setup from REDHAT_REGISTRY_SETUP.md

### Phase 2: Developer Documentation Migration

#### Developer How-To Guides
1. **Automation Setup Guides**:
   - DEPENDABOT_SETUP_GUIDE.md → setup-dependabot-automation.md
   - ANSIBLE_LINT_AUTOMATION.md → setup-ansible-lint-automation.md
   - GEMINI_LINT_WORKFLOW.md → ai-assisted-development.md

2. **Testing Guides**:
   - MOLECULE_MIGRATION_GUIDE.md → migrate-molecule-tests.md
   - MOLECULE_SYSTEMD_TROUBLESHOOTING.md → troubleshoot-molecule-systemd.md
   - MANDATORY_LOCAL_TESTING.md → local-testing-requirements.md
   - local-molecule-setup.md → setup-local-molecule-testing.md

3. **Workflow Guides**:
   - WORKFLOW_FAILURE_ANALYZER.md → troubleshoot-cicd-failures.md
   - AIDER_LINT_INTEGRATION.md → integrate-ai-tools.md

#### Developer Reference
1. **Standards and Specifications**:
   - role_interface_standards.md → apis/role-interfaces.md
   - variable_naming_conventions.md → standards/variable-naming.md
   - TDD_COVERAGE_REPORT.md → testing/coverage-reports.md
   - TDD_STATUS_REPORT.md → testing/test-status.md

2. **Automation Status**:
   - AUTOMATION_SUCCESS_REPORT.md → automation/automation-status.md
   - audit-reports/ → testing/audit-reports/

### Phase 3: Explanations Migration

#### Architectural Decisions
1. **Move all ADRs** from adrs/ to explanations/architecture-decisions/
2. **Create summary documents** linking related ADRs
3. **Extract key concepts** into standalone explanation documents

#### Strategy and Philosophy
1. **DEVOPS_AUTOMATION_FRAMEWORK.md** → automation-philosophy.md
2. **AUTOMATION_ENABLEMENT_STRATEGY.md** → automation-strategy.md
3. **RELEASE_STRATEGY.md** → release-philosophy.md

#### Research Integration
1. **research/** directory → explanations/research-findings/
2. **Create synthesis documents** from research findings
3. **Link research to architectural decisions**

### Phase 4: Cleanup and Organization

#### Archive Strategy
1. **Create docs/archive/** for historical documents
2. **Move outdated content**:
   - Sprint reports → docs/archive/sprint-reports/
   - Completed action plans → docs/archive/planning/
   - Resolved issue summaries → docs/archive/issues/

#### Link Updates
1. **Update all internal links** to point to new Diátaxis locations
2. **Update README.md** to reference Diátaxis documentation
3. **Update CONTRIBUTING.md** to reference developer guides

## 📋 Migration Mapping

### Tutorials (Learning-Oriented)
| Current File | New Location | Action |
|--------------|--------------|---------|
| USER_INSTALLATION_GUIDE.md (sections) | tutorials/01-first-kvm-host-setup.md | Merge/enhance |
| USER_INSTALLATION_GUIDE.md (quick start) | tutorials/00-quick-start.md | Extract |
| migration_guide.md (user sections) | tutorials/04-system-migration.md | Adapt |

### How-To Guides (Problem-Oriented)
| Current File | New Location | Action |
|--------------|--------------|---------|
| migration_guide.md | how-to-guides/migrate-systems.md | Move/adapt |
| USER_INSTALLATION_GUIDE.md (troubleshooting) | how-to-guides/troubleshoot-installation.md | Extract |

### Developer How-To Guides
| Current File | New Location | Action |
|--------------|--------------|---------|
| DEPENDABOT_SETUP_GUIDE.md | developer/setup-dependabot-automation.md | Move |
| ANSIBLE_LINT_AUTOMATION.md | developer/setup-ansible-lint-automation.md | Move |
| MOLECULE_MIGRATION_GUIDE.md | developer/migrate-molecule-tests.md | Move |
| MOLECULE_SYSTEMD_TROUBLESHOOTING.md | developer/troubleshoot-molecule-systemd.md | Move |
| MANDATORY_LOCAL_TESTING.md | developer/local-testing-requirements.md | Move |
| local-molecule-setup.md | developer/setup-local-molecule-testing.md | Move |
| GEMINI_LINT_WORKFLOW.md | developer/ai-assisted-development.md | Move |
| WORKFLOW_FAILURE_ANALYZER.md | developer/troubleshoot-cicd-failures.md | Move |
| AIDER_LINT_INTEGRATION.md | developer/integrate-ai-tools.md | Move |

### Reference (Information-Oriented)
| Current File | New Location | Action |
|--------------|--------------|---------|
| compatibility_report.md | reference/compatibility/platform-support.md | Move |
| FEATURE_COMPATIBILITY_MATRIX.md | reference/compatibility/feature-matrix.md | Move |
| compatibility_matrix.json | reference/compatibility/compatibility-data.json | Move |
| ANSIBLE_COLLECTION_SECURITY.md | reference/security/security-specifications.md | Move |
| REDHAT_REGISTRY_SETUP.md | reference/config-files/registry-configuration.md | Move |
| role_interface_standards.md | reference/apis/role-interfaces.md | Move |
| variable_naming_conventions.md | reference/standards/variable-naming.md | Move |
| TDD_COVERAGE_REPORT.md | reference/testing/coverage-reports.md | Move |
| TDD_STATUS_REPORT.md | reference/testing/test-status.md | Move |
| AUTOMATION_SUCCESS_REPORT.md | reference/automation/automation-status.md | Move |

### Explanations (Understanding-Oriented)
| Current File | New Location | Action |
|--------------|--------------|---------|
| adrs/ (all ADRs) | explanations/architecture-decisions/ | Move |
| DEVOPS_AUTOMATION_FRAMEWORK.md | explanations/automation-philosophy.md | Move |
| AUTOMATION_ENABLEMENT_STRATEGY.md | explanations/automation-strategy.md | Move |
| RELEASE_STRATEGY.md | explanations/release-philosophy.md | Move |
| research/ (all research) | explanations/research-findings/ | Move |

### Archive
| Current File | New Location | Action |
|--------------|--------------|---------|
| action-plan-sprint.md | docs/archive/planning/ | Archive |
| sprint-progress-*.md | docs/archive/sprint-reports/ | Archive |
| fix-stuck-containers-summary.md | docs/archive/issues/ | Archive |
| container-testing-improvements-*.md | docs/archive/improvements/ | Archive |
| session-reports/ | docs/archive/session-reports/ | Archive |

## 🔄 Implementation Steps

### Step 1: Create Migration Structure
```bash
# Create new directory structure
mkdir -p docs/diataxis/{tutorials,how-to-guides/developer,reference/{compatibility,security,apis,standards,testing,automation},explanations/{architecture-decisions,research-findings}}
mkdir -p docs/archive/{planning,sprint-reports,issues,improvements,session-reports}
```

### Step 2: Content Migration
- Move files to appropriate Diátaxis categories
- Adapt content to fit Diátaxis principles
- Update formatting and structure
- Add proper navigation and cross-references

### Step 3: Content Enhancement
- Merge related content where appropriate
- Remove redundancy and outdated information
- Enhance with examples and practical guidance
- Ensure consistency in tone and style

### Step 4: Link Updates
- Update all internal documentation links
- Update README.md and CONTRIBUTING.md
- Update GitHub issue templates and PR templates
- Update CI/CD workflow documentation references

### Step 5: Validation
- Verify all links work correctly
- Ensure no content is lost
- Validate documentation completeness
- Test user navigation paths

## 🎯 Benefits of Migration

### For Users
- **Easier Navigation**: Clear, purpose-driven organization
- **Better Discoverability**: Find information based on intent
- **Reduced Confusion**: No duplicate or conflicting information
- **Improved Learning Path**: Progressive learning from tutorials to advanced concepts

### For Contributors
- **Clear Contribution Guidelines**: All developer docs in one place
- **Better Onboarding**: Structured learning path for new contributors
- **Reduced Maintenance**: Single source of truth for each topic
- **Improved Quality**: Consistent documentation standards

### For Maintainers
- **Easier Maintenance**: Clear ownership and update responsibilities
- **Better Organization**: Logical grouping reduces maintenance overhead
- **Quality Control**: Consistent review and update processes
- **Reduced Duplication**: Single authoritative source for each topic

## ⚠️ Migration Considerations

### Backward Compatibility
- Keep redirects for commonly referenced files
- Update external links gradually
- Maintain old URLs during transition period

### Content Quality
- Review and update outdated information
- Ensure accuracy of technical details
- Validate all examples and code snippets
- Check for broken external links

### User Impact
- Communicate changes to users
- Provide migration guide for bookmarks
- Update documentation references in code comments
- Consider gradual rollout approach

## 🔗 Next Steps

This migration plan provides the roadmap for organizing all documentation under the Diátaxis framework. The implementation should be done systematically to ensure no valuable content is lost and all users can easily find what they need.

---

*This plan ensures comprehensive migration while maintaining documentation quality and user experience.*
