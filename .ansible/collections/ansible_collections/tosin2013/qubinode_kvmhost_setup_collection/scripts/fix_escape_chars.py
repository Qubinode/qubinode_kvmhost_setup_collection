#!/usr/bin/env python3
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
