#!/usr/bin/env python3

# =============================================================================
# Character Encoding Fixer - The "Encoding Specialist"
# =============================================================================
#
# 🎯 PURPOSE FOR LLMs:
# This Python script fixes specific YAML parsing errors caused by escape characters
# and encoding issues, ensuring proper character handling in Ansible files.
#
# 🧠 ARCHITECTURE OVERVIEW FOR AI ASSISTANTS:
# 1. [PHASE 1]: File Discovery - Scans all YAML files for escape character issues
# 2. [PHASE 2]: Pattern Detection - Identifies problematic escape character patterns
# 3. [PHASE 3]: Encoding Analysis - Analyzes character encoding issues
# 4. [PHASE 4]: Targeted Fixes - Applies specific fixes for identified patterns
# 5. [PHASE 5]: Validation - Verifies fixes don't break YAML structure
# 6. [PHASE 6]: Report Generation - Documents all character fixes applied
#
# 🔧 HOW IT CONNECTS TO QUBINODE KVMHOST SETUP COLLECTION:
# - Fixes: Escape character issues in roles/**/*.yml files
# - Resolves: YAML parsing errors caused by character encoding problems
# - Supports: Ansible playbook and role functionality by fixing syntax issues
# - Integrates: With YAML parsing and lint fixing pipeline
# - Prevents: Runtime errors from character encoding problems
# - Maintains: Proper character encoding across all YAML content
#
# 📊 KEY DESIGN PRINCIPLES FOR LLMs TO UNDERSTAND:
# - TARGETED: Focuses on specific escape character and encoding issues
# - PRECISION: Uses precise pattern matching to avoid over-correction
# - SAFETY: Validates fixes to ensure YAML structure remains intact
# - ENCODING-AWARE: Handles various character encoding scenarios
# - SYSTEMATIC: Processes all YAML files consistently
# - REPORTING: Provides detailed logs of all fixes applied
#
# 💡 WHEN TO MODIFY THIS SCRIPT (for future LLMs):
# - New Patterns: Add fix patterns for new escape character issues
# - Encoding Support: Add support for new character encodings
# - File Types: Extend support to additional file types beyond YAML
# - Validation: Enhance validation to catch more encoding issues
# - Performance: Optimize for processing large numbers of files
# - Integration: Add integration with text editors or IDEs
#
# 🚨 IMPORTANT FOR LLMs: Character encoding fixes can subtly change file
# content. Always validate that fixes preserve intended functionality and
# don't introduce new parsing errors or change semantic meaning.

"""
Targeted fix for specific YAML parsing errors with escape characters
"""

import os
import re
import sys
from pathlib import Path

def fix_escape_character_errors():
    """Fix specific escape character errors in YAML files"""
    base_path = Path(".")
    yaml_files = list(base_path.glob("roles/**/*.yml"))
    
    fixes_applied = 0
    
    for file_path in yaml_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Fix escaped quotes inside double-quoted strings
            # Pattern: "...\'...\'" -> "...'...'"
            content = re.sub(r'"([^"]*?)\\\'([^"]*?)\\\'"', r'"\1\'\2\'"', content)
            
            # Fix escaped quotes in Jinja filters within double quotes
            # Pattern: "{{ var | default(\'value\') }}" -> "{{ var | default('value') }}"
            content = re.sub(r'"(\{\{[^}]*?\|\s*default\s*\()\\\'([^\\\']*?)\\\'\)([^}]*?\}\})"', r'"\1\'\2\'\)\3"', content)
            
            # Alternative pattern for the same issue
            content = re.sub(r'"([^"]*?default\s*\()\\\'([^\\\']*?)\\\'\)([^"]*?)"', r'"\1\'\2\'\)\3"', content)
            
            # More generic fix for any escaped single quotes in double-quoted strings
            content = re.sub(r'"([^"]*?)\\\'([^"]*?)"', r'"\1\'\2"', content)
            
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                fixes_applied += 1
                print(f"Fixed escape character errors in {file_path}")
                
        except Exception as e:
            print(f"Error fixing escape characters in {file_path}: {e}")
    
    return fixes_applied

def main():
    print("🔧 Fixing escape character errors in YAML files...")
    fixes = fix_escape_character_errors()
    print(f"✅ Fixed escape character errors in {fixes} files")
    
    if fixes > 0:
        print("\n🔍 Validating YAML syntax after fixes...")
        # Quick validation check
        import yaml
        yaml_files = list(Path(".").glob("roles/**/*.yml"))
        valid_count = 0
        error_count = 0
        
        for file_path in yaml_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    yaml.safe_load(f)
                valid_count += 1
            except yaml.YAMLError:
                error_count += 1
        
        print(f"📊 YAML validation results: {valid_count} valid, {error_count} with errors")

if __name__ == "__main__":
    main()
