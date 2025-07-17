#!/usr/bin/env python3
"""
Advanced Ansible-lint Fix Script - Phase 2
Handles more complex issues like Jinja spacing, no-changed-when, etc.
"""

import os
import re
import sys
import yaml
import glob
from pathlib import Path
from typing import List, Dict

class AdvancedAnsibleLintFixer:
    def __init__(self, base_path: str = "."):
        self.base_path = Path(base_path)
        self.fixes_applied = []
        
    def fix_advanced_jinja_spacing(self) -> int:
        """Fix complex Jinja2 spacing issues"""
        fixed_count = 0
        yaml_files = list(self.base_path.glob("roles/**/*.yml"))
        
        for file_path in yaml_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                # Fix complex Jinja patterns with multiple pipes and spaces
                patterns = [
                    # {{ var|filter|filter }} -> {{ var | filter | filter }}
                    (r'\{\{\s*([^}|]+)\|([^}|]+)\|([^}]+)\s*\}\}', r'{{ \1 | \2 | \3 }}'),
                    # {{ var      |      filter }} -> {{ var | filter }}
                    (r'\{\{\s*([^}|]+)\s+\|\s+([^}]+)\s*\}\}', r'{{ \1 | \2 }}'),
                    # Fix multi-space issues in joins
                    (r'\|\s*join\(\s*[\'"]([^\'"]*)[\'"]\s*\)\s*\|\s*', r'| join(\'\1\') | '),
                    # Fix spacing around default filter
                    (r'\|\s*default\s*\(\s*[\'"]([^\'"]*)[\'"]\s*\)', r'| default(\'\1\')'),
                ]
                
                for pattern, replacement in patterns:
                    content = re.sub(pattern, replacement, content)
                
                if content != original_content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    fixed_count += 1
                    self.fixes_applied.append(f"Fixed advanced Jinja spacing in {file_path}")
                    
            except Exception as e:
                print(f"Error fixing advanced Jinja spacing in {file_path}: {e}")
                
        return fixed_count
    
    def add_changed_when_conditions(self) -> int:
        """Add changed_when: false to shell/command tasks that shouldn't report changes"""
        fixed_count = 0
        yaml_files = list(self.base_path.glob("roles/**/*.yml"))
        
        # Common patterns for tasks that are typically idempotent checks
        read_only_patterns = [
            r'check\s+if',
            r'verify\s+',
            r'get\s+(current|existing)',
            r'test\s+',
            r'validate\s+',
            r'show\s+',
            r'list\s+',
            r'cat\s+',
            r'grep\s+',
            r'find\s+',
            r'stat\s+',
        ]
        
        for file_path in yaml_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                lines = content.split('\n')
                new_lines = []
                i = 0
                
                while i < len(lines):
                    line = lines[i]
                    
                    # Look for shell/command tasks
                    if re.match(r'\s*-\s+(name|shell|command):', line) or \
                       'module: shell' in line or 'module: command' in line:
                        
                        # Check if this is a task block
                        task_lines = [line]
                        indent_level = len(line) - len(line.lstrip())
                        j = i + 1
                        
                        # Collect the full task
                        while j < len(lines):
                            next_line = lines[j]
                            next_indent = len(next_line) - len(next_line.lstrip())
                            
                            if next_line.strip() == '':
                                task_lines.append(next_line)
                                j += 1
                                continue
                            
                            if next_indent <= indent_level and next_line.strip().startswith('-'):
                                break
                                
                            task_lines.append(next_line)
                            j += 1
                        
                        task_content = '\n'.join(task_lines)
                        
                        # Check if it's a shell/command task without changed_when
                        if ('shell:' in task_content or 'command:' in task_content) and \
                           'changed_when:' not in task_content and \
                           'register:' not in task_content:
                            
                            # Check if it matches read-only patterns
                            command_text = task_content.lower()
                            is_readonly = any(re.search(pattern, command_text) for pattern in read_only_patterns)
                            
                            if is_readonly:
                                # Add changed_when: false
                                last_task_line = len(task_lines) - 1
                                while last_task_line >= 0 and task_lines[last_task_line].strip() == '':
                                    last_task_line -= 1
                                
                                if last_task_line >= 0:
                                    base_indent = ' ' * (indent_level + 2)
                                    task_lines.insert(last_task_line + 1, f"{base_indent}changed_when: false")
                                    self.fixes_applied.append(f"Added changed_when: false to read-only task in {file_path}")
                        
                        new_lines.extend(task_lines)
                        i = j
                        continue
                    
                    new_lines.append(line)
                    i += 1
                
                new_content = '\n'.join(new_lines)
                if new_content != original_content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    fixed_count += 1
                    
            except Exception as e:
                print(f"Error adding changed_when in {file_path}: {e}")
                
        return fixed_count
    
    def fix_fqcn_actions(self) -> int:
        """Fix FQCN (Fully Qualified Collection Name) issues"""
        fixed_count = 0
        yaml_files = list(self.base_path.glob("roles/**/*.yml"))
        
        # Common FQCN replacements
        fqcn_mappings = {
            'modprobe': 'community.general.modprobe',
            'setup': 'ansible.builtin.setup',
            'ping': 'ansible.builtin.ping',
            'copy': 'ansible.builtin.copy',
            'template': 'ansible.builtin.template',
            'file': 'ansible.builtin.file',
            'lineinfile': 'ansible.builtin.lineinfile',
            'replace': 'ansible.builtin.replace',
            'package': 'ansible.builtin.package',
            'service': 'ansible.builtin.service',
            'systemd': 'ansible.builtin.systemd',
            'mount': 'ansible.posix.mount',
            'firewalld': 'ansible.posix.firewalld',
            'sysctl': 'ansible.posix.sysctl',
        }
        
        for file_path in yaml_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                for short_name, fqcn in fqcn_mappings.items():
                    # Replace module usage patterns
                    patterns = [
                        (f'{short_name}:', f'{fqcn}:'),
                        (f'module: {short_name}', f'module: {fqcn}'),
                    ]
                    
                    for pattern, replacement in patterns:
                        content = re.sub(pattern, replacement, content)
                
                if content != original_content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    fixed_count += 1
                    self.fixes_applied.append(f"Fixed FQCN actions in {file_path}")
                    
            except Exception as e:
                print(f"Error fixing FQCN in {file_path}: {e}")
                
        return fixed_count
    
    def fix_partial_become_tasks(self) -> int:
        """Fix partial become tasks by adding become: true"""
        fixed_count = 0
        yaml_files = list(self.base_path.glob("roles/**/*.yml"))
        
        for file_path in yaml_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                lines = content.split('\n')
                new_lines = []
                i = 0
                
                while i < len(lines):
                    line = lines[i]
                    
                    # Look for tasks with become_user but no become
                    if 'become_user:' in line:
                        # Check the context for this task
                        task_start = i
                        indent_level = len(line) - len(line.lstrip())
                        
                        # Find the start of this task
                        while task_start > 0:
                            prev_line = lines[task_start - 1]
                            prev_indent = len(prev_line) - len(prev_line.lstrip())
                            if prev_line.strip().startswith('- name:') or prev_indent < indent_level:
                                break
                            task_start -= 1
                        
                        # Collect the task block
                        task_lines = []
                        j = task_start
                        while j < len(lines):
                            task_line = lines[j]
                            task_indent = len(task_line) - len(task_line.lstrip())
                            
                            if j > task_start and task_line.strip().startswith('-') and task_indent <= indent_level:
                                break
                                
                            task_lines.append((j, task_line))
                            j += 1
                        
                        # Check if become: is already present
                        task_text = '\n'.join([line for _, line in task_lines])
                        if 'become_user:' in task_text and 'become:' not in task_text:
                            # Add become: true before become_user
                            base_indent = ' ' * indent_level
                            new_lines.append(f"{base_indent}become: true")
                            self.fixes_applied.append(f"Added become: true to task with become_user in {file_path}")
                    
                    new_lines.append(line)
                    i += 1
                
                new_content = '\n'.join(new_lines)
                if new_content != original_content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    fixed_count += 1
                    
            except Exception as e:
                print(f"Error fixing partial become in {file_path}: {e}")
                
        return fixed_count
    
    def fix_literal_compare(self) -> int:
        """Fix literal True/False comparisons"""
        fixed_count = 0
        yaml_files = list(self.base_path.glob("roles/**/*.yml"))
        
        for file_path in yaml_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                # Fix literal comparisons
                patterns = [
                    (r'==\s*True\b', ''),
                    (r'==\s*False\b', ' == false'),
                    (r'!=\s*True\b', ' == false'),
                    (r'!=\s*False\b', ''),
                    (r'\bis\s+True\b', ''),
                    (r'\bis\s+False\b', ' == false'),
                    (r'\bis\s+not\s+True\b', ' == false'),
                    (r'\bis\s+not\s+False\b', ''),
                ]
                
                for pattern, replacement in patterns:
                    content = re.sub(pattern, replacement, content)
                
                if content != original_content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    fixed_count += 1
                    self.fixes_applied.append(f"Fixed literal comparisons in {file_path}")
                    
            except Exception as e:
                print(f"Error fixing literal compare in {file_path}: {e}")
                
        return fixed_count
    
    def run_all_fixes(self) -> Dict[str, int]:
        """Run all advanced automated fixes"""
        print("🔧 Starting advanced automated ansible-lint fixes...")
        
        results = {
            "advanced_jinja_spacing": self.fix_advanced_jinja_spacing(),
            "changed_when_conditions": self.add_changed_when_conditions(),
            "fqcn_actions": self.fix_fqcn_actions(),
            "partial_become_tasks": self.fix_partial_become_tasks(),
            "literal_compare": self.fix_literal_compare(),
        }
        
        total_fixes = sum(results.values())
        
        print(f"\n✅ Advanced automated fixes completed!")
        print(f"📊 Summary:")
        for fix_type, count in results.items():
            if count > 0:
                print(f"  - {fix_type.replace('_', ' ').title()}: {count} files")
        
        print(f"\n🎯 Total files fixed: {total_fixes}")
        
        if self.fixes_applied:
            print(f"\n📝 Applied fixes:")
            for fix in self.fixes_applied[:10]:  # Show first 10
                print(f"  - {fix}")
            if len(self.fixes_applied) > 10:
                print(f"  ... and {len(self.fixes_applied) - 10} more")
        
        return results

def main():
    fixer = AdvancedAnsibleLintFixer()
    results = fixer.run_all_fixes()
    
    print(f"\n🔍 Run 'ansible-lint roles/' again to see remaining issues")
    return 0 if sum(results.values()) > 0 else 1

if __name__ == "__main__":
    sys.exit(main())
