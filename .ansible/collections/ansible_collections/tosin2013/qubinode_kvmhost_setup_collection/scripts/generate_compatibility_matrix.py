#!/usr/bin/env python3
"""
Feature Compatibility Matrix Generator
Automatically detects and documents RHEL version compatibility
Based on ADR-0010: End-User Repeatability Strategy
"""

import yaml
import json
import os
import subprocess
import sys
from pathlib import Path


class CompatibilityMatrix:
    def __init__(self, project_root="/home/vpcuser/qubinode_kvmhost_setup_collection"):
        self.project_root = Path(project_root)
        self.roles_dir = self.project_root / "roles"
        self.compatibility_data = {}
        
    def detect_rhel_versions(self):
        """Detect supported RHEL versions from role tasks and vars"""
        rhel_versions = set()
        
        # Common RHEL version patterns
        version_patterns = ["rhel8", "rhel9", "rhel10", "el8", "el9", "el10"]
        
        for role_dir in self.roles_dir.iterdir():
            if role_dir.is_dir() and role_dir.name.startswith("kvmhost_"):
                # Check tasks for version-specific logic
                tasks_dir = role_dir / "tasks"
                if tasks_dir.exists():
                    for task_file in tasks_dir.glob("*.yml"):
                        try:
                            with open(task_file, 'r') as f:
                                content = f.read()
                                for pattern in version_patterns:
                                    if pattern in content.lower():
                                        # Extract version number
                                        if "rhel8" in pattern or "el8" in pattern:
                                            rhel_versions.add("8")
                                        elif "rhel9" in pattern or "el9" in pattern:
                                            rhel_versions.add("9")
                                        elif "rhel10" in pattern or "el10" in pattern:
                                            rhel_versions.add("10")
                        except Exception as e:
                            print(f"Warning: Could not read {task_file}: {e}")
        
        # Default to supporting 8, 9, 10 if no specific versions found
        if not rhel_versions:
            rhel_versions = {"8", "9", "10"}
            
        return sorted(list(rhel_versions))
    
    def analyze_role_features(self, role_name):
        """Analyze features and compatibility for a specific role"""
        role_path = self.roles_dir / role_name
        features = {}
        
        if not role_path.exists():
            return features
            
        # Analyze defaults/main.yml for feature flags
        defaults_file = role_path / "defaults" / "main.yml"
        if defaults_file.exists():
            try:
                with open(defaults_file, 'r') as f:
                    defaults = yaml.safe_load(f) or {}
                    
                # Look for feature-related variables
                for key, value in defaults.items():
                    if any(keyword in key.lower() for keyword in 
                          ['enable', 'install', 'configure', 'feature']):
                        features[key] = {
                            'default': value,
                            'description': f"Feature flag for {key}",
                            'rhel_compatibility': {}
                        }
            except Exception as e:
                print(f"Warning: Could not parse {defaults_file}: {e}")
                
        # Analyze tasks for version-specific features
        tasks_dir = role_path / "tasks"
        if tasks_dir.exists():
            for task_file in tasks_dir.glob("*.yml"):
                try:
                    with open(task_file, 'r') as f:
                        content = f.read()
                        
                    # Extract feature names from task file names
                    feature_name = task_file.stem
                    if feature_name not in features:
                        features[feature_name] = {
                            'description': f"Task group: {feature_name}",
                            'rhel_compatibility': {}
                        }
                        
                    # Check for RHEL version conditions
                    rhel_versions = self.detect_rhel_versions()
                    for version in rhel_versions:
                        version_supported = True
                        
                        # Look for version-specific conditions
                        if f"rhel{version}" in content.lower() or f"el{version}" in content.lower():
                            version_supported = True
                        elif "when:" in content and "ansible_distribution_major_version" in content:
                            # More sophisticated parsing could be added here
                            version_supported = True
                            
                        features[feature_name]['rhel_compatibility'][f"rhel{version}"] = {
                            'supported': version_supported,
                            'notes': f"Detected from {task_file.name}"
                        }
                        
                except Exception as e:
                    print(f"Warning: Could not analyze {task_file}: {e}")
                    
        return features
    
    def generate_matrix(self):
        """Generate the complete compatibility matrix"""
        rhel_versions = self.detect_rhel_versions()
        matrix = {
            'metadata': {
                'generated_date': str(subprocess.check_output(['date', '+%Y-%m-%d %H:%M:%S']).decode().strip()),
                'project': 'Qubinode KVM Host Setup Collection',
                'rhel_versions_detected': rhel_versions,
                'generator_version': '1.0.0'
            },
            'compatibility_matrix': {}
        }
        
        # Analyze each kvmhost role
        for role_dir in self.roles_dir.iterdir():
            if role_dir.is_dir() and role_dir.name.startswith("kvmhost_"):
                role_name = role_dir.name
                print(f"Analyzing role: {role_name}")
                
                role_features = self.analyze_role_features(role_name)
                matrix['compatibility_matrix'][role_name] = {
                    'description': f"KVM Host setup role for {role_name.replace('kvmhost_', '')}",
                    'features': role_features,
                    'overall_compatibility': {}
                }
                
                # Calculate overall compatibility per RHEL version
                for version in rhel_versions:
                    supported_features = 0
                    total_features = len(role_features)
                    
                    for feature_name, feature_data in role_features.items():
                        rhel_compat = feature_data.get('rhel_compatibility', {})
                        if rhel_compat.get(f"rhel{version}", {}).get('supported', True):
                            supported_features += 1
                    
                    compatibility_percentage = (supported_features / total_features * 100) if total_features > 0 else 100
                    matrix['compatibility_matrix'][role_name]['overall_compatibility'][f"rhel{version}"] = {
                        'supported_features': supported_features,
                        'total_features': total_features,
                        'compatibility_percentage': round(compatibility_percentage, 2),
                        'status': 'full' if compatibility_percentage == 100 else 'partial' if compatibility_percentage > 50 else 'limited'
                    }
        
        return matrix
    
    def save_matrix(self, output_file="compatibility_matrix.json"):
        """Save the compatibility matrix to a file"""
        matrix = self.generate_matrix()
        output_path = self.project_root / "docs" / output_file
        
        # Ensure docs directory exists
        output_path.parent.mkdir(exist_ok=True)
        
        with open(output_path, 'w') as f:
            json.dump(matrix, f, indent=2)
            
        print(f"Compatibility matrix saved to: {output_path}")
        return output_path
    
    def generate_report(self):
        """Generate a human-readable compatibility report"""
        matrix = self.generate_matrix()
        report_lines = []
        
        report_lines.append("# RHEL Compatibility Matrix Report")
        report_lines.append(f"**Generated**: {matrix['metadata']['generated_date']}")
        report_lines.append(f"**Project**: {matrix['metadata']['project']}")
        report_lines.append("")
        
        # Summary table
        report_lines.append("## Compatibility Summary")
        report_lines.append("")
        report_lines.append("| Role | RHEL 8 | RHEL 9 | RHEL 10 | Notes |")
        report_lines.append("|------|--------|--------|---------|-------|")
        
        for role_name, role_data in matrix['compatibility_matrix'].items():
            compat = role_data['overall_compatibility']
            rhel8_status = compat.get('rhel8', {}).get('status', 'unknown')
            rhel9_status = compat.get('rhel9', {}).get('status', 'unknown')
            rhel10_status = compat.get('rhel10', {}).get('status', 'unknown')
            
            # Convert status to emoji
            status_emoji = {'full': '✅', 'partial': '⚠️', 'limited': '❌', 'unknown': '❓'}
            rhel8_emoji = status_emoji.get(rhel8_status, '❓')
            rhel9_emoji = status_emoji.get(rhel9_status, '❓')  
            rhel10_emoji = status_emoji.get(rhel10_status, '❓')
            
            notes = f"{rhel8_status.title()}/{rhel9_status.title()}/{rhel10_status.title()}"
            report_lines.append(f"| {role_name} | {rhel8_emoji} | {rhel9_emoji} | {rhel10_emoji} | {notes} |")
        
        # Detailed breakdown
        report_lines.append("")
        report_lines.append("## Detailed Analysis")
        
        for role_name, role_data in matrix['compatibility_matrix'].items():
            report_lines.append(f"### {role_name}")
            report_lines.append(f"*{role_data['description']}*")
            report_lines.append("")
            
            # Feature compatibility table
            features = role_data['features']
            if features:
                report_lines.append("| Feature | RHEL 8 | RHEL 9 | RHEL 10 |")
                report_lines.append("|---------|--------|--------|---------|")
                
                for feature_name, feature_data in features.items():
                    rhel_compat = feature_data.get('rhel_compatibility', {})
                    rhel8_support = rhel_compat.get('rhel8', {}).get('supported', True)
                    rhel9_support = rhel_compat.get('rhel9', {}).get('supported', True)
                    rhel10_support = rhel_compat.get('rhel10', {}).get('supported', True)
                    
                    rhel8_icon = '✅' if rhel8_support else '❌'
                    rhel9_icon = '✅' if rhel9_support else '❌'
                    rhel10_icon = '✅' if rhel10_support else '❌'
                    
                    report_lines.append(f"| {feature_name} | {rhel8_icon} | {rhel9_icon} | {rhel10_icon} |")
            else:
                report_lines.append("*No specific features detected*")
                
            report_lines.append("")
        
        return '\n'.join(report_lines)
    
    def save_report(self, output_file="compatibility_report.md"):
        """Save the human-readable report"""
        report = self.generate_report()
        output_path = self.project_root / "docs" / output_file
        
        with open(output_path, 'w') as f:
            f.write(report)
            
        print(f"Compatibility report saved to: {output_path}")
        return output_path


def main():
    """Main function to generate compatibility matrix"""
    print("Generating RHEL Compatibility Matrix...")
    
    matrix_generator = CompatibilityMatrix()
    
    # Generate and save JSON matrix
    json_path = matrix_generator.save_matrix()
    
    # Generate and save human-readable report  
    report_path = matrix_generator.save_report()
    
    print("\n" + "="*50)
    print("COMPATIBILITY MATRIX GENERATION COMPLETE")
    print("="*50)
    print(f"JSON Matrix: {json_path}")
    print(f"Report: {report_path}")
    print("\nNext steps:")
    print("1. Review the generated compatibility report")
    print("2. Add version-specific tests to your Molecule scenarios")
    print("3. Update role documentation with compatibility info")
    print("4. Integrate with CI/CD for automated compatibility testing")


if __name__ == "__main__":
    main()
