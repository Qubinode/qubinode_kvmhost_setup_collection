# Ansible Lint Automation Toolkit

This repository includes a comprehensive set of automated tools to resolve ansible-lint failures efficiently. These tools can significantly reduce the manual effort required to maintain code quality standards.

## 🚀 Quick Start

### One-Command Solution
```bash
./scripts/ansible_lint_toolkit.sh
```

This runs all automated fixes in the optimal order and provides a detailed before/after analysis.

## 🛠️ Individual Tools

### 1. Comprehensive YAML Parsing Fixer
**File:** `scripts/fix_yaml_parsing.py`

**Purpose:** Fixes YAML syntax errors that prevent ansible-lint from running

**Fixes:**
- Double module names (e.g., `ansible.builtin.ansible.builtin.file` → `ansible.builtin.file`)
- Malformed Jinja template escaping
- Spacing artifacts from previous fixes
- Quote inconsistencies
- Indentation issues
- Unicode/encoding problems

**Usage:**
```bash
python3 scripts/fix_yaml_parsing.py
```

**Example Output:**
```
🔧 Starting comprehensive YAML parsing fixes...
📊 Before fixes: 109/127 files are valid YAML
✅ YAML parsing fixes completed!
📈 YAML validity improved: 109/127 → 125/127
🎉 Fixed 16 previously broken YAML files!
```

### 2. Basic Ansible-Lint Fixer
**File:** `scripts/fix_ansible_lint.py`

**Purpose:** Resolves common, straightforward ansible-lint violations

**Fixes:**
- Trailing spaces in YAML files
- Handler name casing (lowercase → Title Case)
- `meta/main.yml` galaxy_info issues
- Basic Jinja2 spacing problems
- YAML truthy values (`yes/no` → `true/false`)
- Creates missing validation files

**Usage:**
```bash
python3 scripts/fix_ansible_lint.py
```

**Example Output:**
```
🔧 Starting automated ansible-lint fixes...
✅ Automated fixes completed!
📊 Summary:
  - Trailing Spaces: 25 files
  - Handler Names: 2 files
  - Meta Galaxy Info: 9 files
  - Jinja Spacing: 39 files
🎯 Total files fixed: 75
```

### 3. Advanced Ansible-Lint Fixer
**File:** `scripts/fix_ansible_lint_advanced.py`

**Purpose:** Handles complex ansible-lint patterns and rules

**Fixes:**
- Advanced Jinja2 spacing with multiple filters
- Adds `changed_when: false` to read-only commands
- FQCN (Fully Qualified Collection Name) corrections
- `partial-become` task fixes
- Literal True/False comparisons

**Usage:**
```bash
python3 scripts/fix_ansible_lint_advanced.py
```

### 4. YAML Escape Character Fixer
**File:** `scripts/fix_escape_chars.py`

**Purpose:** Resolves specific escape character issues in YAML

**Fixes:**
- Escaped quotes in double-quoted strings
- Malformed Jinja filter escaping
- YAML parsing errors from incorrect escaping

**Usage:**
```bash
python3 scripts/fix_escape_chars.py
```

## 📊 Expected Results

### Typical Improvements
Our automated tools typically achieve:

- **60-80%** reduction in ansible-lint failures
- **Resolution of all YAML parsing errors**
- **Automatic fixing of 200+ common violations**

### Before/After Example
```
Before: 227 ansible-lint failures
After:  45 ansible-lint failures
Fixed:  182 issues (80% improvement)
```

## 🎯 Remaining Manual Work

After running all automated fixes, you may still need to manually address:

### High-Priority Issues
- `schema[meta]` - Platform version corrections
- `load-failure` - Missing or broken file references  
- `jinja[invalid]` - Complex template logic errors

### Medium-Priority Issues
- `risky-shell-pipe` - Add `set -o pipefail` to shell commands
- `no-changed-when` - Add `changed_when` conditions to specific tasks
- `ignore-errors` - Replace with `failed_when` conditions

### Low-Priority Issues
- `yaml[line-length]` - Break long lines (cosmetic)
- `name[casing]` - Task name capitalization (cosmetic)

## 🔧 Integration with CI/CD

### GitHub Actions Integration
Add to your workflow:

```yaml
- name: Run Ansible Lint Automation
  run: |
    pip install ansible-lint[yamllint]
    ./scripts/ansible_lint_toolkit.sh
    
- name: Check remaining issues
  run: |
    ansible-lint roles/ --exclude roles/.cache/ --exclude roles/.venv/
  continue-on-error: true
```

### Pre-commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit
echo "Running ansible-lint automation..."
./scripts/ansible_lint_toolkit.sh
```

## 🚀 Advanced Usage

### Custom Ansible-Lint Configuration
Create `.ansible-lint` to ignore acceptable violations:

```yaml
skip_list:
  - yaml[line-length]  # Allow long lines in specific cases
  - name[casing]       # Allow lowercase task names
  
exclude_paths:
  - roles/.cache/
  - roles/.venv/
  - molecule/
```

### Automated Reporting
```bash
# Generate detailed report
ansible-lint roles/ --format sarif > ansible-lint-results.sarif

# Show only high-priority issues
ansible-lint roles/ | grep -E "(schema|load-failure|jinja\[invalid\])"
```

## 🔍 Troubleshooting

### Script Fails with Permission Errors
```bash
chmod +x scripts/*.py scripts/*.sh
```

### YAML Parsing Errors Persist
1. Check file encoding: `file -bi roles/path/to/file.yml`
2. Validate manually: `python3 -c "import yaml; yaml.safe_load(open('file.yml'))"`
3. Look for special characters or malformed syntax

### Ansible-Lint Not Found
```bash
pip install ansible-lint[yamllint]
# or
pip3 install --user ansible-lint[yamllint]
```

## 📈 Performance Tips

### Large Repositories
- Run tools in stages during low-traffic periods
- Use `--exclude` patterns for external dependencies
- Focus on roles/ directory first

### Continuous Improvement
1. Run toolkit weekly as part of maintenance
2. Monitor trending violations
3. Update automation scripts as new patterns emerge

## 🤝 Contributing

### Adding New Automation
1. Study common ansible-lint failures in your codebase
2. Create targeted fix functions
3. Add comprehensive error handling
4. Test on a variety of YAML structures

### Reporting Issues
If the automation tools don't handle specific patterns in your codebase:
1. Capture the specific ansible-lint violation
2. Provide the problematic YAML snippet
3. Suggest the expected fix

---

**💡 Pro Tip:** Run `./scripts/ansible_lint_toolkit.sh` regularly as part of your development workflow to maintain high code quality with minimal manual effort!

## 🤖 Automated Pull Request Generation

### GitHub Actions Integration
We've created a powerful GitHub Actions workflow that automatically runs the ansible-lint automation and creates pull requests with fixes!

**File:** `.github/workflows/automated-ansible-lint-fixes.yml`

**Features:**
- **Scheduled Automation** - Runs weekly on Sundays at 2 AM UTC
- **Manual Trigger** - Run on-demand via GitHub Actions UI
- **Automatic PRs** - Creates pull requests when fixes are found
- **Detailed Reporting** - Comprehensive before/after analysis
- **Smart Detection** - Only creates PRs when meaningful improvements are made

**Usage:**

#### Automatic Weekly Runs
The workflow runs automatically every Sunday and will:
1. Scan your codebase for ansible-lint violations
2. Apply all available automated fixes
3. Generate a detailed summary of improvements
4. Create a pull request if fixes were applied
5. Include comprehensive diff and metrics

#### Manual Trigger
Trigger the automation anytime via GitHub Actions:

```bash
# Using GitHub CLI
gh workflow run automated-ansible-lint-fixes.yml

# Or via GitHub web interface:
# Actions → Automated Ansible Lint Fixes → Run workflow
```

#### Example Pull Request
When the automation finds and fixes issues, it creates a PR like this:

**Title:** `🤖 Automated Ansible Lint Fixes - 47 issues resolved`

**Description includes:**
- **Summary** of all changes made
- **Before/After metrics** (failures reduced, YAML validity improved)  
- **Files modified** with change counts
- **Detailed diff** (expandable section)
- **Full automation log** (expandable section)

**Labels:** `automated`, `ansible-lint`, `code-quality`, `maintenance`

### Configuration
Customize the automation behavior via `.github/ansible-lint-automation-config.yml`:

```yaml
# Example configuration
automation:
  min_improvements_threshold: 5  # Minimum fixes to create PR
  max_files_per_pr: 100         # Maximum files to modify
  
notifications:
  notify_on_success: true       # Notify even when no changes
  create_failure_issues: true   # Create issues on automation failure
```

### Monitoring Dashboard
Track your automation status with the built-in dashboard:

```bash
./scripts/automation_dashboard.sh
```

**Dashboard shows:**
- Latest workflow run status
- Open automation PRs awaiting review
- Current ansible-lint failure count
- YAML file validity status
- Toolkit completeness check
- Actionable recommendations

### Best Practices

#### Review Process
1. **Automated PRs are safe** - All fixes use proven patterns
2. **Review before merging** - Check the diff for any edge cases
3. **Merge regularly** - Don't let automation PRs accumulate
4. **Monitor dashboard** - Check weekly for status updates

#### Integration with Development Workflow
```yaml
# Add to your main CI workflow
- name: Check for automation PRs
  run: |
    AUTOMATION_PRS=$(gh pr list --label="automated,ansible-lint" --state=open | wc -l)
    if [ "$AUTOMATION_PRS" -gt 0 ]; then
      echo "⚠️ $AUTOMATION_PRS automation PR(s) pending review"
      echo "Consider reviewing and merging before major releases"
    fi
```

#### Failure Handling
If automation fails, it will:
- Create a detailed issue with debugging information
- Upload artifacts with logs and analysis
- Provide specific commands to reproduce locally
