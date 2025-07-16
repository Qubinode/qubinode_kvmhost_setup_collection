#!/usr/bin/env python3
"""
Comprehensive YAML Parsing Error Fixer
Fixes various YAML syntax issues that can break ansible-lint and Ansible execution
"""

import os
import re
import sys
import yaml
from pathlib import Path
from typing import List, Dict, Tuple

class YAMLParsingFixer:
    def __init__(self, base_path: str = "."):
        self.base_path = Path(base_path)
        self.fixes_applied = []
        
    def validate_yaml_syntax(self, file_path: Path) -> Tuple[bool, str]:
        """Validate YAML syntax and return error if any"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                yaml.safe_load(f)
            return True, ""
        except yaml.YAMLError as e:
            return False, str(e)
        except Exception as e:
            return False, f"File read error: {str(e)}"
    
    def fix_double_module_names(self) -> int:
        """Fix doubled module names like ansible.builtin.ansible.builtin.file"""
        fixed_count = 0
        yaml_files = list(self.base_path.glob("roles/**/*.yml"))
        
        patterns = [
            (r'ansible\.builtin\.ansible\.builtin\.', 'ansible.builtin.'),
            (r'community\.general\.community\.general\.', 'community.general.'),
            (r'ansible\.posix\.ansible\.posix\.', 'ansible.posix.'),
            (r'containers\.podman\.containers\.podman\.', 'containers.podman.'),
        ]
        
        for file_path in yaml_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                for pattern, replacement in patterns:
                    content = re.sub(pattern, replacement, content)
                
                if content != original_content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    fixed_count += 1
                    self.fixes_applied.append(f"Fixed double module names in {file_path}")
                    
            except Exception as e:
                print(f"Error fixing double module names in {file_path}: {e}")
                
        return fixed_count
    
    def fix_malformed_jinja_escaping(self) -> int:
        """Fix malformed Jinja template escaping"""
        fixed_count = 0
        yaml_files = list(self.base_path.glob("roles/**/*.yml"))
        
        for file_path in yaml_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                # Fix various malformed escaping patterns
                fixes = [
                    # Fix \'string\' -> 'string'
                    (r"\\\'([^\\\']*?)\\\'", r"'\1'"),
                    # Fix \"string\" -> "string"
                    (r'\\"([^\\"]*?)\\"', r'"\1"'),
                    # Fix spacing in filters with escaped quotes
                    (r'default\(\\\'([^\\\']*)\\\'\)', r"default('\1')"),
                    (r'default\(\\"([^\\"]*)\\"\\)', r'default("\1")'),
                    # Fix malformed Jinja spacing artifacts
                    (r'\{\{\s*([^}]+?)\s*\|\s*default\s*\(\s*\\\'([^\\\']*)\\\'\s*\)\s*\}\}', r"{{ \1 | default('\2') }}"),
                    (r'\{\{\s*([^}]+?)\s*\|\s*default\s*\(\s*\\"([^\\"]*)\\"\\s*\)\s*\}\}', r'{{ \1 | default("\2") }}'),
                ]
                
                for pattern, replacement in fixes:
                    content = re.sub(pattern, replacement, content)
                
                if content != original_content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    fixed_count += 1
                    self.fixes_applied.append(f"Fixed malformed Jinja escaping in {file_path}")
                    
            except Exception as e:
                print(f"Error fixing Jinja escaping in {file_path}: {e}")
                
        return fixed_count
    
    def fix_jinja_spacing_artifacts(self) -> int:
        """Fix spacing artifacts from previous automated fixes"""
        fixed_count = 0
        yaml_files = list(self.base_path.glob("roles/**/*.yml"))
        
        for file_path in yaml_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                # Fix various spacing artifacts
                fixes = [
                    # Fix excessive spaces around pipes
                    (r'\|\s{2,}default\s*\(', '| default('),
                    (r'\|\s{2,}join\s*\(', '| join('),
                    (r'\|\s{2,}length\s*', '| length'),
                    (r'\|\s{2,}int\s*', '| int'),
                    (r'\|\s{2,}bool\s*', '| bool'),
                    
                    # Fix multiple spaces in Jinja templates
                    (r'\{\{\s{2,}', '{{ '),
                    (r'\s{2,}\}\}', ' }}'),
                    
                    # Fix spacing around operators in Jinja
                    (r'\s+\|\s+default\s+\(\s+', ' | default('),
                    (r'\s+\|\s+join\s+\(\s+', ' | join('),
                    
                    # Fix line continuation artifacts
                    (r'\s+\|\s+\n\s+default', ' | default'),
                ]
                
                for pattern, replacement in fixes:
                    content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
                
                if content != original_content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    fixed_count += 1
                    self.fixes_applied.append(f"Fixed Jinja spacing artifacts in {file_path}")
                    
            except Exception as e:
                print(f"Error fixing Jinja spacing artifacts in {file_path}: {e}")
                
        return fixed_count
    
    def fix_quote_inconsistencies(self) -> int:
        """Fix quote inconsistencies that can cause YAML parsing issues"""
        fixed_count = 0
        yaml_files = list(self.base_path.glob("roles/**/*.yml"))
        
        for file_path in yaml_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                # Fix mixed quotes in YAML values
                fixes = [
                    # Fix mode values to be consistent
                    (r'mode:\s*"([^"]*)"', r"mode: '\1'"),
                    # Fix path values with mixed quotes
                    (r'path:\s*"([^"]*)"', r"path: '\1'"),
                    # Fix name values with mixed quotes in loops
                    (r'name:\s*"([^"]*)"', r"name: '\1'"),
                ]
                
                for pattern, replacement in fixes:
                    content = re.sub(pattern, replacement, content)
                
                if content != original_content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    fixed_count += 1
                    self.fixes_applied.append(f"Fixed quote inconsistencies in {file_path}")
                    
            except Exception as e:
                print(f"Error fixing quote inconsistencies in {file_path}: {e}")
                
        return fixed_count
    
    def fix_indentation_issues(self) -> int:
        """Fix common indentation issues that break YAML parsing"""
        fixed_count = 0
        yaml_files = list(self.base_path.glob("roles/**/*.yml"))
        
        for file_path in yaml_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                
                fixed_lines = []
                changed = False
                
                for i, line in enumerate(lines):
                    original_line = line
                    
                    # Fix common indentation issues
                    # Remove tabs and replace with spaces
                    if '\t' in line:
                        line = line.expandtabs(2)
                        changed = True
                    
                    # Fix lines that start with spaces but should be at root level
                    if line.strip().startswith('---') and line.startswith(' '):
                        line = line.lstrip()
                        changed = True
                    
                    # Fix mixed indentation in task lists
                    if re.match(r'^\s*-\s+name:', line):
                        # Ensure consistent 2-space indentation
                        indent_level = (len(line) - len(line.lstrip())) // 2 * 2
                        line = ' ' * indent_level + line.lstrip()
                        if line != original_line:
                            changed = True
                    
                    fixed_lines.append(line)
                
                if changed:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.writelines(fixed_lines)
                    fixed_count += 1
                    self.fixes_applied.append(f"Fixed indentation issues in {file_path}")
                    
            except Exception as e:
                print(f"Error fixing indentation in {file_path}: {e}")
                
        return fixed_count
    
    def fix_unicode_and_encoding_issues(self) -> int:
        """Fix unicode and encoding issues that can break YAML parsing"""
        fixed_count = 0
        yaml_files = list(self.base_path.glob("roles/**/*.yml"))
        
        for file_path in yaml_files:
            try:
                # Try to read with different encodings
                content = None
                for encoding in ['utf-8', 'latin1', 'cp1252']:
                    try:
                        with open(file_path, 'r', encoding=encoding) as f:
                            content = f.read()
                        break
                    except UnicodeDecodeError:
                        continue
                
                if content is None:
                    continue
                
                original_content = content
                
                # Fix common unicode issues
                fixes = [
                    # Fix smart quotes
                    ('"', '"'),
                    ('"', '"'),
                    (''', "'"),
                    (''', "'"),
                    # Fix em/en dashes
                    ('—', '-'),
                    ('–', '-'),
                    # Fix ellipsis
                    ('…', '...'),
                ]
                
                for old_char, new_char in fixes:
                    content = content.replace(old_char, new_char)
                
                if content != original_content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    fixed_count += 1
                    self.fixes_applied.append(f"Fixed unicode/encoding issues in {file_path}")
                    
            except Exception as e:
                print(f"Error fixing unicode/encoding in {file_path}: {e}")
                
        return fixed_count
    
    def validate_all_yaml_files(self) -> Tuple[int, List[str]]:
        """Validate all YAML files and return count of valid files and list of errors"""
        yaml_files = list(self.base_path.glob("roles/**/*.yml"))
        valid_count = 0
        errors = []
        
        for file_path in yaml_files:
            is_valid, error = self.validate_yaml_syntax(file_path)
            if is_valid:
                valid_count += 1
            else:
                errors.append(f"{file_path}: {error}")
        
        return valid_count, errors
    
    def run_all_fixes(self) -> Dict[str, int]:
        """Run all YAML parsing fixes"""
        print("🔧 Starting comprehensive YAML parsing fixes...")
        
        # Validate before fixes
        total_files = len(list(self.base_path.glob("roles/**/*.yml")))
        valid_before, errors_before = self.validate_all_yaml_files()
        print(f"� Before fixes: {valid_before}/{total_files} files are valid YAML")
        
        if errors_before:
            print(f"❌ Found {len(errors_before)} YAML parsing errors")
            for error in errors_before[:5]:  # Show first 5 errors
                print(f"   - {error}")
            if len(errors_before) > 5:
                print(f"   ... and {len(errors_before) - 5} more errors")
        
        results = {
            "double_module_names": self.fix_double_module_names(),
            "malformed_jinja_escaping": self.fix_malformed_jinja_escaping(),
            "jinja_spacing_artifacts": self.fix_jinja_spacing_artifacts(),
            "quote_inconsistencies": self.fix_quote_inconsistencies(),
            "indentation_issues": self.fix_indentation_issues(),
            "unicode_encoding_issues": self.fix_unicode_and_encoding_issues(),
        }
        
        # Validate after fixes
        valid_after, errors_after = self.validate_all_yaml_files()
        
        total_fixes = sum(results.values())
        
        print(f"\n✅ YAML parsing fixes completed!")
        print(f"📊 Summary:")
        for fix_type, count in results.items():
            if count > 0:
                print(f"  - {fix_type.replace('_', ' ').title()}: {count} files")
        
        print(f"\n🎯 Total files fixed: {total_fixes}")
        print(f"📈 YAML validity improved: {valid_before}/{total_files} → {valid_after}/{total_files}")
        
        if valid_after > valid_before:
            print(f"🎉 Fixed {valid_after - valid_before} previously broken YAML files!")
        
        if errors_after:
            print(f"\n⚠️  Remaining YAML errors ({len(errors_after)}):")
            for error in errors_after[:3]:  # Show first 3 remaining errors
                print(f"   - {error}")
            if len(errors_after) > 3:
                print(f"   ... and {len(errors_after) - 3} more errors")
        
        if self.fixes_applied:
            print(f"\n📝 Applied fixes:")
            for fix in self.fixes_applied[:10]:  # Show first 10
                print(f"  - {fix}")
            if len(self.fixes_applied) > 10:
                print(f"  ... and {len(self.fixes_applied) - 10} more")
        
        return results

def main():
    fixer = YAMLParsingFixer()
    results = fixer.run_all_fixes()
    
    total_fixes = sum(results.values())
    if total_fixes > 0:
        print(f"\n🔍 Run 'ansible-lint roles/' again to see if parsing errors are resolved")
        return 0
    else:
        print(f"\n✅ No YAML parsing fixes were needed")
        return 1

if __name__ == "__main__":
    sys.exit(main())
