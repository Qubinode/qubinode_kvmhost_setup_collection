# GitHub Copilot Instructions for Qubinode KVM Host Setup Collection

## Ansible Lint Error Fixing

When encountering ansible-lint errors in this repository, use the following automated scripts and procedures:

### 1. YAML Syntax Error Fixing

For YAML syntax errors with escaped quotes (e.g., `default('\'\)`), use the Python fix script:

```bash
# Use the fix_yaml.py script to fix escaped quote patterns
python3 fix_yaml.py <file_path>

# Or run the comprehensive fix for all problematic files
./fix_all_yaml.sh

# You may also use ansible-lint's auto-fix feature
ansible-lint --fix <file_path>
```

The `fix_yaml.py` script automatically handles:
- `default('\'\)` → `default('')`
- `default('text\'\)` → `default('text')`
- Other malformed escape sequences in YAML strings

### 2. Module Path Fixing

For `syntax-check[unknown-module]` errors with double prefixes (e.g., `ansible.builtin.ansible.builtin.systemd`), use:

```bash
# Fix double ansible.builtin prefixes in handlers and tasks
sed -i 's/ansible\.builtin\.ansible\.builtin\./ansible.builtin./g' <file_path>
```

Common patterns to fix:
- `ansible.builtin.ansible.builtin.systemd` → `ansible.builtin.systemd`
- `ansible.builtin.ansible.builtin.service` → `ansible.builtin.service`
- `ansible.builtin.ansible.builtin.file` → `ansible.builtin.file`

### 3. Comprehensive Lint Validation

Always run the full validation workflow after fixes:

```bash
# Check ansible-lint status
ansible-lint --parseable

# Test individual YAML files for syntax
python3 -c "import yaml; yaml.safe_load(open('<file_path>').read())"

# Run the GitHub Actions workflow for complete validation
# .github/workflows/automated-ansible-lint-fixes.yml
```

## Python Environment Setup

This repository uses virtual environments for Python dependencies on self-hosted runners:

```bash
# Python detection and virtual environment setup
python_cmd=$(which python3.12 2>/dev/null || which python3.11 2>/dev/null || which python3 2>/dev/null)
$python_cmd -m venv ansible-lint-env
source ansible-lint-env/bin/activate
pip install --upgrade pip
pip install -r requirements-dev.txt
```

## File Structure Patterns

When working with this Ansible collection:

- **Roles**: Located in `roles/` directory with standard Ansible role structure
- **Tasks**: Main logic in `roles/*/tasks/main.yml` and subdirectories
- **Handlers**: Service management in `roles/*/handlers/main.yml`
- **Defaults**: Variable defaults in `roles/*/defaults/main.yml`
- **Templates**: Jinja2 templates in `roles/*/templates/`

## Common Issues and Solutions

### Load Failure Errors
- Usually caused by YAML syntax errors (escaped quotes, malformed strings)
- Fix with `fix_yaml.py` script
- Validate with Python YAML parser

### Module Resolution Errors
- Often due to double module prefixes from automated fixes
- Use sed commands to clean up prefixes
- Always use `ansible.builtin.*` for core modules

### Virtual Environment Issues
- Self-hosted runners need manual Python environment setup
- Use virtual environments instead of `setup-python` action
- Ensure Python 3.11+ for ansible-core>=2.17.7 compatibility

## Quality Gates

Before committing changes:

1. ✅ All YAML files pass Python YAML parser validation
2. ✅ ansible-lint returns 0 fatal errors
3. ✅ GitHub Actions workflow completes successfully
4. ✅ No `load-failure[runtimeerror]` or `syntax-check[unknown-module]` errors

## Repository-Specific Context

This is an Ansible collection for KVM host setup with:
- **Purpose**: Automated KVM virtualization host configuration
- **Target**: RHEL/CentOS systems for enterprise virtualization
- **Dependencies**: libvirt, QEMU/KVM, networking components
- **Testing**: Molecule framework with container-based testing

When suggesting fixes or improvements, consider the enterprise virtualization context and maintain compatibility with the existing KVM host setup workflows.
