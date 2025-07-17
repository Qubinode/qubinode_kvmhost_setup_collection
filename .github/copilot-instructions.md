# GitHub Copilot Instructions for Qubinode KVM Host Setup Collection

## Ansible Development Standards & Best Practices

When working with this Ansible collection, always follow Ansible best practices and official documentation standards. Prioritize proper Ansible conventions over quick fixes.

### 1. Ansible-Lint Error Resolution Strategy

**Primary Approach: Follow Ansible Standards**
- Consult [Ansible official documentation](https://docs.ansible.com/) for proper syntax and conventions
- Reference [ansible-lint rules documentation](https://ansible-lint.readthedocs.io/rules/) to understand the reasoning behind each rule
- Apply fixes that align with Ansible best practices, not just suppress warnings

**For YAML Syntax Issues:**
```yaml
# ✅ CORRECT: Use proper YAML quoting
- name: "Set default value"
  ansible.builtin.set_fact:
    my_var: "{{ my_var | default('') }}"

# ❌ AVOID: Malformed escape sequences
- name: 'Set default value'
  ansible.builtin.set_fact:
    my_var: "{{ my_var | default('\'\) }}"
```

**For Module Usage:**
```yaml
# ✅ CORRECT: Use fully qualified collection names (FQCN)
- name: "Manage systemd service"
  ansible.builtin.systemd:
    name: "{{ service_name }}"
    state: started
    enabled: true

# ❌ AVOID: Bare module names or double prefixes
- name: "Manage systemd service"
  systemd:  # Missing FQCN
    name: "{{ service_name }}"
```

### 2. Code Quality Standards

**Task Naming Convention:**
- Use descriptive, action-oriented names
- Follow format: "Action target with context"
- Use double quotes for consistency

```yaml
# ✅ GOOD
- name: "Install KVM virtualization packages"
- name: "Configure libvirt networking bridge"
- name: "Validate KVM host capabilities"

# ❌ AVOID
- name: install packages
- name: 'Configure stuff'
```

**Variable and Parameter Standards:**
```yaml
# ✅ Use snake_case for variables
kvm_host_packages:
  - qemu-kvm
  - libvirt-daemon-system

# ✅ Use meaningful defaults with proper filtering
bridge_name: "{{ custom_bridge_name | default('br0') }}"

# ✅ Use proper boolean values
enable_nested_virtualization: true
```

### 3. Idempotency and Error Handling

**Ensure Idempotent Operations:**
```yaml
# ✅ Use appropriate modules for idempotent operations
- name: "Ensure KVM packages are installed"
  ansible.builtin.package:
    name: "{{ kvm_host_packages }}"
    state: present

# ✅ Use proper conditionals and checks
- name: "Start libvirt service only if not running"
  ansible.builtin.systemd:
    name: libvirtd
    state: started
  when: ansible_facts['services']['libvirtd']['state'] != 'running'
```

**Error Handling Best Practices:**
```yaml
- name: "Configure network bridge with validation"
  ansible.builtin.shell: |
    ip link show {{ bridge_name }}
  register: bridge_check
  failed_when: false
  changed_when: false

- name: "Create bridge if it doesn't exist"
  ansible.builtin.command: |
    ip link add name {{ bridge_name }} type bridge
  when: bridge_check.rc != 0
```

### 4. Documentation and Metadata Standards

**Role Documentation:**
- Maintain comprehensive `README.md` for each role
- Document all variables in `defaults/main.yml` with comments
- Include example playbooks and usage scenarios

**Meta Information:**
```yaml
# roles/*/meta/main.yml
galaxy_info:
  author: "Your Name"
  description: "Clear, concise role description"
  license: GPLv2
  min_ansible_version: "2.10"
  platforms:
    - name: EL
      versions:
        - "8"
        - "9"
  galaxy_tags:
    - virtualization
    - kvm
    - libvirt
```

### 5. Testing and Validation Standards

**Use Molecule for Testing:**
```yaml
# molecule/default/molecule.yml
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: quay.io/ansible/creator-rhel8-runner:latest
    pre_build_image: true
    privileged: true
provisioner:
  name: ansible
  config_options:
    defaults:
      interpreter_python: auto_silent
verifier:
  name: ansible
```

**Validation Tasks:**
```yaml
- name: "Verify KVM host configuration"
  block:
    - name: "Check KVM module is loaded"
      ansible.builtin.shell: lsmod | grep kvm
      register: kvm_check
      changed_when: false

    - name: "Validate libvirt service status"
      ansible.builtin.systemd:
        name: libvirtd
      register: libvirt_status

    - name: "Assert KVM is properly configured"
      ansible.builtin.assert:
        that:
          - kvm_check.rc == 0
          - libvirt_status.status.ActiveState == "active"
        fail_msg: "KVM host configuration validation failed"
```

### 6. Automated Fix Tools (Use as Last Resort)

When manual fixes following Ansible standards are not feasible, these tools can help:

```bash
# Use ansible-lint's built-in auto-fix capabilities
ansible-lint --fix <file_path>

# For legacy code cleanup (use sparingly)
python3 fix_yaml.py <file_path>  # For escaped quote issues
./fix_all_yaml.sh               # Bulk fixes

# Module prefix cleanup (manual verification required)
sed -i 's/ansible\.builtin\.ansible\.builtin\./ansible.builtin./g' <file_path>
```

**⚠️ Important:** Always review automated fixes to ensure they maintain Ansible best practices and don't introduce regressions.

### 7. Comprehensive Validation Workflow

Always run the full validation workflow after making changes:

```bash
# 1. Validate YAML syntax
ansible-lint --parseable

# 2. Test individual YAML files
python3 -c "import yaml; yaml.safe_load(open('<file_path>').read())"

# 3. Run molecule tests locally (recommended)
cd roles/<role_name>
molecule test

# 4. Validate against ADR compliance
./scripts/adr-compliance-checker.sh

# 5. Check for security issues
./scripts/enhanced-security-scan.sh
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
