#!/bin/bash
# comprehensive-lint-fixes.sh - Comprehensive ansible-lint fixes for known issues

echo "🔧 Applying comprehensive ansible-lint fixes..."

# Exit on any error
set -e

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to backup a file before modifying
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.$(date +%s)"
        log "Backed up $file"
    fi
}

# 1. Remove all document start markers (production profile requirement)
log "📋 Removing document start markers..."
find roles/kvmhost_cockpit/ -name "*.yml" -exec sed -i '1{/^---$/d;}' {} \;

# 2. Fix schema issue in meta.yml (AIX platform)
log "🛠️ Fixing meta.yml schema issue..."
if [ -f roles/kvmhost_cockpit/meta/main.yml ]; then
    backup_file roles/kvmhost_cockpit/meta/main.yml
    
    # Create a temporary file with corrected content
    cat > /tmp/meta_fix.yml << 'EOF'
galaxy_info:
  role_name: kvmhost_cockpit
  author: Qubinode Community
  description: Configure Cockpit web interface for KVM host management with SSL, authentication, and module integration
  company: Red Hat
  license: Apache-2.0
  min_ansible_version: "2.9"

  platforms:
    - name: EL
      versions:
        - "8"
        - "9"

  galaxy_tags:
    - cockpit
    - kvm
    - virtualization
    - web-interface
    - management
    - ssl
    - authentication

dependencies: []
EOF

    # Replace the content while preserving file permissions
    cat /tmp/meta_fix.yml > roles/kvmhost_cockpit/meta/main.yml
    rm -f /tmp/meta_fix.yml
    log "Fixed meta.yml platform configuration"
fi

# 3. Fix double FQCN prefixes
log "🔧 Fixing double FQCN prefixes..."
find roles/kvmhost_cockpit/ -name "*.yml" -exec \
  sed -i 's/ansible\.builtin\.ansible\.builtin\./ansible.builtin./g' {} \;

# Fix specific lineinfile module error
if [ -f roles/kvmhost_cockpit/tasks/configuration/authentication.yml ]; then
    backup_file roles/kvmhost_cockpit/tasks/configuration/authentication.yml
    sed -i 's/ansible\.builtin\.lineinansible\.builtin\.file/ansible.builtin.lineinfile/g' \
      roles/kvmhost_cockpit/tasks/configuration/authentication.yml
    log "Fixed authentication.yml module names"
fi

# 4. Fix line length issues with multiline YAML
log "📏 Fixing line length issues..."

# Fix authentication.yml long debug messages
if [ -f roles/kvmhost_cockpit/tasks/configuration/authentication.yml ]; then
    python3 << 'PYTHON_EOF'
import re

file_path = 'roles/kvmhost_cockpit/tasks/configuration/authentication.yml'

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix the debug task with proper multiline YAML
    new_debug_task = '''- name: "Display authentication configuration"
  ansible.builtin.debug:
    msg:
      - "Cockpit authentication configured"
      - >-
        Auth methods: {{ kvmhost_cockpit_auth_methods | join(', ')
        if kvmhost_cockpit_auth_methods | length > 0 else 'Default' }}
      - >-
        Allowed users: {{ kvmhost_cockpit_allowed_users | join(', ')
        if kvmhost_cockpit_allowed_users | length > 0 else 'All system users' }}
      - >-
        Admin users: {{ kvmhost_cockpit_admin_users | join(', ')
        if kvmhost_cockpit_admin_users | length > 0 else 'Default wheel group members' }}'''
    
    # Find and replace the problematic debug task
    pattern = r'- name: "Display authentication configuration"\s*\n\s*ansible\.builtin\.debug:.*?wheel group members.*?"'
    content = re.sub(pattern, new_debug_task, content, flags=re.DOTALL)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("Fixed authentication.yml debug task")
    
except Exception as e:
    print(f"Error fixing authentication.yml: {e}")
PYTHON_EOF
fi

# Fix cockpit.yml validation message
if [ -f roles/kvmhost_cockpit/tasks/validation/cockpit.yml ]; then
    backup_file roles/kvmhost_cockpit/tasks/validation/cockpit.yml
    
    python3 << 'PYTHON_EOF'
import re

file_path = 'roles/kvmhost_cockpit/tasks/validation/cockpit.yml'

try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix the long Access URL line
    old_pattern = r'"Access URL: \{\{ \'https\' if kvmhost_cockpit_ssl_enabled else \'http\' \}\}://\{\{ ansible_default_ipv4\.address \}\}:\{\{ kvmhost_cockpit_port \}\}"'
    new_content = '''- >-
        Access URL: {{ 'https' if kvmhost_cockpit_ssl_enabled else 'http' }}://{{ ansible_default_ipv4.address }}:{{ kvmhost_cockpit_port }}'''
    
    content = re.sub(old_pattern, new_content, content)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("Fixed cockpit.yml validation message")
    
except Exception as e:
    print(f"Error fixing cockpit.yml: {e}")
PYTHON_EOF
fi

# 5. Apply remaining ansible-lint fixes
log "🔧 Running ansible-lint --fix for remaining issues..."
if command -v ansible-lint &> /dev/null; then
    # Clear cache to ensure we're working with source files
    rm -rf ~/.cache/ansible-compat/ 2>/dev/null || true
    export ANSIBLE_COLLECTIONS_PATH=""
    export ANSIBLE_ROLES_PATH=""
    
    # Run ansible-lint with auto-fix
    ansible-lint --fix roles/kvmhost_cockpit/ || log "Some ansible-lint fixes may have failed"
else
    log "Warning: ansible-lint not found, skipping auto-fix"
fi

# 6. Final verification
log "🔍 Running final verification..."
if command -v ansible-lint &> /dev/null; then
    ansible-lint roles/kvmhost_cockpit/ --profile production || log "Some issues may still remain"
fi

log "✅ Comprehensive fixes completed!"
log "📝 Note: Review the changes and test before committing"

# Display summary of what was fixed
echo ""
echo "=== SUMMARY OF FIXES APPLIED ==="
echo "✓ Removed document start markers (---) from YAML files"
echo "✓ Fixed meta.yml platform configuration (AIX → EL)"
echo "✓ Cleaned up double FQCN prefixes"
echo "✓ Fixed module name errors"
echo "✓ Applied multiline YAML for long lines"
echo "✓ Ran ansible-lint auto-fix"
echo ""
echo "Files modified:"
find roles/kvmhost_cockpit/ -name "*.backup.*" | sed 's/\.backup\.[0-9]*$//' | sort | uniq
echo ""
echo "Run 'ansible-lint roles/kvmhost_cockpit/' to verify remaining issues"
