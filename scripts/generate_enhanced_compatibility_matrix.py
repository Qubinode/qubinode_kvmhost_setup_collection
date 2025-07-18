#!/usr/bin/env python3
"""
Enhanced Feature Compatibility Matrix Generator
Includes container compatibility and advanced container detection logic
Based on ADR-0010: End-User Repeatability Strategy
Updated: 2025-07-16 - Container Compatibility Enhancement
"""

import yaml
import json
import os
import subprocess
import sys
from pathlib import Path
from datetime import datetime


class EnhancedCompatibilityMatrix:
    def __init__(self, project_root=None):
        if project_root is None:
            self.project_root = self._detect_project_root()
        else:
            self.project_root = Path(project_root)

        self.roles_dir = self.project_root / "roles"
        self.molecule_dir = self.project_root / "molecule"
        self.compatibility_data = {}

    def _detect_project_root(self):
        """Detect project root by looking for key files in multiple locations"""
        # Start with current working directory
        current_dir = Path.cwd()

        # Check current directory first
        if self._is_project_root(current_dir):
            return current_dir

        # Check if we're in a subdirectory (like scripts/)
        for parent in current_dir.parents:
            if self._is_project_root(parent):
                return parent

        # Check common GitHub Actions paths
        github_workspace = os.environ.get('GITHUB_WORKSPACE')
        if github_workspace:
            github_path = Path(github_workspace)
            if self._is_project_root(github_path):
                return github_path

        # Check if we're in a nested GitHub Actions structure
        if 'github' in str(current_dir).lower():
            # Look for the actual project directory
            for part in current_dir.parts:
                if 'qubinode_kvmhost_setup_collection' in part:
                    # Try to construct the path
                    potential_root = Path('/'.join(current_dir.parts[:current_dir.parts.index(part)+1]))
                    if self._is_project_root(potential_root):
                        return potential_root

        # Try to find the project based on the script location
        script_path = Path(__file__).resolve()
        script_parent = script_path.parent.parent  # Go up from scripts/ to project root
        if self._is_project_root(script_parent):
            return script_parent

        # Look for common project locations
        common_locations = [
            Path.home() / "qubinode_kvmhost_setup_collection",
            Path("/home/vpcuser/qubinode_kvmhost_setup_collection"),
            Path("/home/runner/work/qubinode_kvmhost_setup_collection/qubinode_kvmhost_setup_collection"),
        ]

        for location in common_locations:
            if self._is_project_root(location):
                return location

        # Fallback: return current directory and let the script handle missing roles
        print(f"Warning: Could not detect project root, using current directory: {current_dir}")
        return current_dir

    def _is_project_root(self, path):
        """Check if a path looks like the project root"""
        path = Path(path)

        # Must have roles directory
        if not (path / "roles").exists():
            return False

        # Should have at least one of these files
        indicators = ["galaxy.yml", "ansible.cfg", "pyproject.toml", "requirements.txt"]
        return any((path / indicator).exists() for indicator in indicators)
        
    def detect_rhel_versions(self):
        """Detect supported RHEL versions from role tasks and Molecule scenarios"""
        rhel_versions = set()

        # Check if roles directory exists
        if not self.roles_dir.exists():
            print(f"Warning: Roles directory not found at {self.roles_dir}")
            return ["8", "9"]  # Default fallback versions

        # Check Molecule configurations for tested versions
        if self.molecule_dir.exists():
            for scenario_dir in self.molecule_dir.iterdir():
                if scenario_dir.is_dir():
                    molecule_yml = scenario_dir / "molecule.yml"
                    if molecule_yml.exists():
                        try:
                            with open(molecule_yml, 'r') as f:
                                molecule_config = yaml.safe_load(f)
                                platforms = molecule_config.get('platforms', [])
                                for platform in platforms:
                                    image = platform.get('image', '')
                                    if 'rockylinux' in image or 'almalinux' in image or 'ubi' in image:
                                        if ':8' in image or 'rhel8' in image:
                                            rhel_versions.add("8")
                                        elif ':9' in image or 'rhel9' in image:
                                            rhel_versions.add("9")
                                        elif ':10' in image or 'rhel10' in image:
                                            rhel_versions.add("10")
                        except Exception as e:
                            print(f"Warning: Could not read {molecule_yml}: {e}")

        # Fallback: check task files for version-specific logic
        version_patterns = ["rhel8", "rhel9", "rhel10", "el8", "el9", "el10"]
        try:
            for role_dir in self.roles_dir.iterdir():
                if role_dir.is_dir() and role_dir.name.startswith("kvmhost_"):
                    tasks_dir = role_dir / "tasks"
                    if tasks_dir.exists():
                        for task_file in tasks_dir.glob("*.yml"):
                            try:
                                with open(task_file, 'r') as f:
                                    content = f.read()
                                for pattern in version_patterns:
                                    if pattern in content.lower():
                                        if "rhel8" in pattern or "el8" in pattern:
                                            rhel_versions.add("8")
                                        elif "rhel9" in pattern or "el9" in pattern:
                                            rhel_versions.add("9")
                                        elif "rhel10" in pattern or "el10" in pattern:
                                            rhel_versions.add("10")
                            except Exception as e:
                                print(f"Warning: Could not read {task_file}: {e}")
        except Exception as e:
            print(f"Warning: Could not scan roles directory: {e}")
        
        # Default to supporting 8, 9, 10 if no specific versions found
        if not rhel_versions:
            rhel_versions = {"8", "9", "10"}
            
        return sorted(list(rhel_versions))
    
    def detect_container_compatibility(self):
        """Detect container compatibility features from recent enhancements"""
        container_features = {
            'advanced_container_detection': {
                'implemented': False,
                'criteria': [],
                'description': 'Multi-criteria container environment detection'
            },
            'task_skipping': {
                'implemented': False,
                'skipped_tasks': [],
                'description': 'Container-inappropriate task skipping'
            },
            'gpg_verification': {
                'implemented': False,
                'strategy': 'unknown',
                'description': 'Dynamic GPG verification for container environments'
            },
            'molecule_testing': {
                'implemented': False,
                'scenarios': [],
                'platforms': [],
                'description': 'Container-based testing with Molecule'
            }
        }
        
        # Check for advanced container detection in performance_optimization.yml
        perf_opt_file = self.project_root / "roles" / "kvmhost_setup" / "tasks" / "performance_optimization.yml"
        if perf_opt_file.exists():
            try:
                with open(perf_opt_file, 'r') as f:
                    content = f.read()
                    if 'is_container_environment' in content:
                        container_features['advanced_container_detection']['implemented'] = True
                        if 'ansible_virtualization_type in' in content:
                            container_features['advanced_container_detection']['criteria'].append('virtualization_type')
                        if 'ansible_env.container' in content:
                            container_features['advanced_container_detection']['criteria'].append('environment_variables')
                        if 'ansible_mounts' in content and 'overlay' in content:
                            container_features['advanced_container_detection']['criteria'].append('filesystem_analysis')
                        if 'ansible_selinux' in content and 'docker_t' in content:
                            container_features['advanced_container_detection']['criteria'].append('selinux_context')
                    
                    # Count tasks with container guards
                    guard_count = content.count('when: not is_container_environment')
                    if guard_count > 0:
                        container_features['task_skipping']['implemented'] = True
                        container_features['task_skipping']['skipped_tasks'] = [f"{guard_count} KVM-specific tasks"]
            except Exception as e:
                print(f"Warning: Could not analyze {perf_opt_file}: {e}")
        
        # Check for dynamic GPG verification in main.yml
        main_file = self.project_root / "roles" / "kvmhost_setup" / "tasks" / "main.yml"
        if main_file.exists():
            try:
                with open(main_file, 'r') as f:
                    content = f.read()
                    if 'disable_gpg_check' in content and 'container' in content:
                        container_features['gpg_verification']['implemented'] = True
                        container_features['gpg_verification']['strategy'] = 'dynamic_container_detection'
            except Exception as e:
                print(f"Warning: Could not analyze {main_file}: {e}")
        
        # Check Molecule scenarios for container testing
        if self.molecule_dir.exists():
            scenarios = []
            platforms = []
            for scenario_dir in self.molecule_dir.iterdir():
                if scenario_dir.is_dir():
                    scenarios.append(scenario_dir.name)
                    molecule_yml = scenario_dir / "molecule.yml"
                    if molecule_yml.exists():
                        try:
                            with open(molecule_yml, 'r') as f:
                                molecule_config = yaml.safe_load(f)
                                for platform in molecule_config.get('platforms', []):
                                    image = platform.get('image', '')
                                    if image not in platforms:
                                        platforms.append(image)
                        except Exception as e:
                            print(f"Warning: Could not read {molecule_yml}: {e}")
            
            if scenarios:
                container_features['molecule_testing']['implemented'] = True
                container_features['molecule_testing']['scenarios'] = scenarios
                container_features['molecule_testing']['platforms'] = platforms
        
        return container_features
    
    def analyze_role_features(self, role_name):
        """Analyze features and compatibility for a specific role"""
        role_dir = self.roles_dir / role_name
        features = {}
        
        # Standard feature detection
        tasks_dir = role_dir / "tasks"
        if tasks_dir.exists():
            for task_file in tasks_dir.glob("*.yml"):
                try:
                    with open(task_file, 'r') as f:
                        content = f.read()
                        
                    # Extract feature name from file
                    feature_name = task_file.stem
                    
                    features[feature_name] = {
                        'file': str(task_file.relative_to(self.project_root)),
                        'rhel_compatibility': {},
                        'container_compatibility': 'unknown',
                        'requires_physical_host': False
                    }
                    
                    # Check for container compatibility
                    if 'when: not is_container_environment' in content:
                        features[feature_name]['container_compatibility'] = 'skipped_in_containers'
                        features[feature_name]['requires_physical_host'] = True
                    elif 'is_container_environment' in content:
                        features[feature_name]['container_compatibility'] = 'container_aware'
                    else:
                        features[feature_name]['container_compatibility'] = 'compatible'
                    
                    # Check RHEL version compatibility
                    rhel_versions = self.detect_rhel_versions()
                    for version in rhel_versions:
                        version_supported = True
                        notes = []
                        
                        # Look for version-specific conditions
                        if f"rhel{version}" in content.lower():
                            notes.append(f"RHEL {version} specifically mentioned")
                        if f"ansible_distribution_major_version" in content:
                            if f'== "{version}"' in content or f"== '{version}'" in content:
                                notes.append(f"Version {version} specifically supported")
                            elif f'in [' in content and f'"{version}"' in content:
                                notes.append(f"Version {version} in supported list")
                        
                        features[feature_name]['rhel_compatibility'][f"rhel{version}"] = {
                            'supported': version_supported,
                            'notes': notes if notes else [f"No specific restrictions found for RHEL {version}"]
                        }
                        
                except Exception as e:
                    print(f"Warning: Could not analyze {task_file}: {e}")
                    
        return features
    
    def generate_enhanced_matrix(self):
        """Generate the enhanced compatibility matrix with container support"""
        rhel_versions = self.detect_rhel_versions()
        container_features = self.detect_container_compatibility()
        
        matrix = {
            'metadata': {
                'generated_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'project': 'Qubinode KVM Host Setup Collection',
                'version': '2.1.0',
                'rhel_versions_supported': rhel_versions,
                'generator_version': '2.0.0',
                'container_compatibility': 'enhanced',
                'last_updated_commit': self.get_git_commit_hash()
            },
            'container_compatibility': container_features,
            'platform_support': {
                'physical_hosts': {
                    'supported': True,
                    'features': 'full_kvm_optimization',
                    'notes': 'All features available including performance optimization'
                },
                'virtual_machines': {
                    'supported': True,
                    'features': 'limited_optimization',
                    'notes': 'Some performance features may not be applicable'
                },
                'containers': {
                    'supported': True,
                    'features': 'testing_only',
                    'notes': 'Container-inappropriate tasks automatically skipped',
                    'testing_platforms': ['Podman', 'Docker']
                }
            },
            'rhel_compatibility_matrix': {}
        }
        
        # Analyze each kvmhost role
        if not self.roles_dir.exists():
            print(f"❌ Error: Roles directory not found at {self.roles_dir}")
            print(f"🔍 Current project root: {self.project_root}")
            print("💡 Please run this script from the project root or specify the correct path")
            raise FileNotFoundError(f"Roles directory not found: {self.roles_dir}")

        for role_dir in self.roles_dir.iterdir():
            if role_dir.is_dir() and role_dir.name.startswith("kvmhost_"):
                role_name = role_dir.name
                print(f"Analyzing role: {role_name}")

                role_features = self.analyze_role_features(role_name)
                matrix['rhel_compatibility_matrix'][role_name] = {
                    'description': f"KVM Host setup role for {role_name.replace('kvmhost_', '')}",
                    'features': role_features,
                    'overall_compatibility': {},
                    'container_readiness': {
                        'testing_compatible': True,
                        'production_deployment': 'physical_vm_only'
                    }
                }
                
                # Calculate overall compatibility per RHEL version
                for version in rhel_versions:
                    supported_features = 0
                    total_features = len(role_features)
                    container_aware_features = 0
                    
                    for feature_name, feature_data in role_features.items():
                        if feature_data['rhel_compatibility'].get(f"rhel{version}", {}).get('supported', False):
                            supported_features += 1
                        if feature_data['container_compatibility'] in ['container_aware', 'skipped_in_containers']:
                            container_aware_features += 1
                    
                    compatibility_percentage = (supported_features / total_features * 100) if total_features > 0 else 0
                    container_awareness = (container_aware_features / total_features * 100) if total_features > 0 else 0
                    
                    matrix['rhel_compatibility_matrix'][role_name]['overall_compatibility'][f"rhel{version}"] = {
                        'compatibility_percentage': round(compatibility_percentage, 1),
                        'supported_features': supported_features,
                        'total_features': total_features,
                        'container_awareness_percentage': round(container_awareness, 1),
                        'status': 'supported' if compatibility_percentage >= 80 else 'partial'
                    }
        
        return matrix
    
    def get_git_commit_hash(self):
        """Get the current git commit hash"""
        try:
            result = subprocess.run(['git', 'rev-parse', 'HEAD'], 
                                  capture_output=True, text=True, cwd=self.project_root)
            return result.stdout.strip()[:8] if result.returncode == 0 else 'unknown'
        except:
            return 'unknown'
    
    def save_matrix(self, matrix, output_dir="docs"):
        """Save the compatibility matrix to JSON and generate markdown report"""
        output_path = self.project_root / output_dir
        output_path.mkdir(exist_ok=True)
        
        # Save JSON matrix
        json_file = output_path / "compatibility_matrix.json"
        with open(json_file, 'w') as f:
            json.dump(matrix, f, indent=2)
        print(f"✅ Compatibility matrix saved to: {json_file}")
        
        # Generate markdown report
        self.generate_markdown_report(matrix, output_path)
    
    def generate_markdown_report(self, matrix, output_path):
        """Generate a human-readable markdown compatibility report"""
        md_content = []
        md_content.append("# RHEL Compatibility Matrix Report")
        md_content.append("")
        md_content.append("## 📊 Overview")
        md_content.append("")
        md_content.append(f"**Generated:** {matrix['metadata']['generated_date']}")
        md_content.append(f"**Project:** {matrix['metadata']['project']}")
        md_content.append(f"**Version:** {matrix['metadata']['version']}")
        md_content.append(f"**Commit:** {matrix['metadata']['last_updated_commit']}")
        md_content.append("")
        
        # Container compatibility section
        md_content.append("## 🐳 Container Compatibility Enhancement")
        md_content.append("")
        container_features = matrix['container_compatibility']
        
        for feature_name, feature_data in container_features.items():
            status = "✅" if feature_data['implemented'] else "❌"
            md_content.append(f"- **{feature_name.replace('_', ' ').title()}** {status}")
            md_content.append(f"  - {feature_data['description']}")
            
            if feature_name == 'advanced_container_detection' and feature_data['criteria']:
                md_content.append(f"  - Detection criteria: {', '.join(feature_data['criteria'])}")
            elif feature_name == 'task_skipping' and feature_data['skipped_tasks']:
                md_content.append(f"  - Skipped tasks: {', '.join(feature_data['skipped_tasks'])}")
            elif feature_name == 'gpg_verification' and feature_data['strategy']:
                md_content.append(f"  - Strategy: {feature_data['strategy']}")
            elif feature_name == 'molecule_testing':
                if feature_data['scenarios']:
                    md_content.append(f"  - Test scenarios: {', '.join(feature_data['scenarios'])}")
                if feature_data['platforms']:
                    md_content.append(f"  - Container platforms: {len(feature_data['platforms'])} images tested")
            md_content.append("")
        
        # Platform support section
        md_content.append("## 🖥️ Platform Support Matrix")
        md_content.append("")
        md_content.append("| Platform | Supported | Features | Notes |")
        md_content.append("|----------|-----------|----------|-------|")
        
        for platform, support_data in matrix['platform_support'].items():
            status = "✅" if support_data['supported'] else "❌"
            platform_name = platform.replace('_', ' ').title()
            features = support_data['features'].replace('_', ' ').title()
            notes = support_data['notes']
            md_content.append(f"| {platform_name} | {status} | {features} | {notes} |")
        
        md_content.append("")
        
        # RHEL compatibility section
        md_content.append("## 🔴 RHEL Version Compatibility")
        md_content.append("")
        
        rhel_versions = matrix['metadata']['rhel_versions_supported']
        for role_name, role_data in matrix['rhel_compatibility_matrix'].items():
            md_content.append(f"### {role_name}")
            md_content.append("")
            md_content.append(role_data['description'])
            md_content.append("")
            
            # Compatibility table
            md_content.append("| RHEL Version | Compatibility | Features Supported | Container Awareness | Status |")
            md_content.append("|--------------|---------------|-------------------|-------------------|--------|")
            
            for version in rhel_versions:
                compat_data = role_data['overall_compatibility'].get(f"rhel{version}", {})
                compat_pct = compat_data.get('compatibility_percentage', 0)
                container_pct = compat_data.get('container_awareness_percentage', 0)
                supported = compat_data.get('supported_features', 0)
                total = compat_data.get('total_features', 0)
                status = compat_data.get('status', 'unknown')
                
                status_icon = "✅" if status == 'supported' else "⚠️" if status == 'partial' else "❌"
                
                md_content.append(f"| RHEL {version} | {compat_pct}% | {supported}/{total} | {container_pct}% | {status_icon} {status} |")
            
            md_content.append("")
        
        # Testing validation section
        md_content.append("## 🧪 Testing Validation")
        md_content.append("")
        
        if matrix['container_compatibility']['molecule_testing']['implemented']:
            scenarios = matrix['container_compatibility']['molecule_testing']['scenarios']
            platforms = matrix['container_compatibility']['molecule_testing']['platforms']
            
            md_content.append(f"**Molecule Test Scenarios:** {len(scenarios)}")
            for scenario in scenarios:
                md_content.append(f"- {scenario}")
            md_content.append("")
            
            md_content.append(f"**Container Platforms Tested:** {len(platforms)}")
            for platform in platforms[:5]:  # Limit to first 5 for readability
                md_content.append(f"- {platform}")
            if len(platforms) > 5:
                md_content.append(f"- ... and {len(platforms) - 5} more")
            md_content.append("")
        
        # Save markdown report
        md_file = output_path / "compatibility_report.md"
        with open(md_file, 'w') as f:
            f.write('\n'.join(md_content))
        print(f"✅ Compatibility report saved to: {md_file}")


def main():
    """Main execution function"""
    if len(sys.argv) > 1:
        project_root = sys.argv[1]
        print(f"🔍 Using specified project root: {project_root}")
        generator = EnhancedCompatibilityMatrix(project_root)
    else:
        print("🔍 Auto-detecting project root...")
        generator = EnhancedCompatibilityMatrix()
        print(f"🔍 Detected project root: {generator.project_root}")

    print("🔍 Generating Enhanced Compatibility Matrix...")
    
    matrix = generator.generate_enhanced_matrix()
    generator.save_matrix(matrix)
    
    print("\n🎉 Enhanced compatibility matrix generation complete!")
    print("\n📋 Summary:")
    print(f"- RHEL versions supported: {', '.join(matrix['metadata']['rhel_versions_supported'])}")
    print(f"- Container compatibility: {matrix['metadata']['container_compatibility']}")
    print(f"- Roles analyzed: {len(matrix['rhel_compatibility_matrix'])}")
    
    container_features = matrix['container_compatibility']
    implemented_features = sum(1 for f in container_features.values() if f['implemented'])
    print(f"- Container features implemented: {implemented_features}/{len(container_features)}")


if __name__ == "__main__":
    main()
