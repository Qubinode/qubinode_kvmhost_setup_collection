#!/usr/bin/env python3
"""
Container Compatibility Validation Test
Validates that container detection and task skipping work correctly
across all supported container platforms
"""

import subprocess
import json
import sys
import time
from pathlib import Path


class ContainerCompatibilityValidator:
    def __init__(self):
        self.test_results = {
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
            'platform_tests': {},
            'detection_tests': {},
            'task_skipping_tests': {},
            'overall_status': 'unknown'
        }
        
    def run_command(self, cmd, timeout=30):
        """Run a command with timeout and capture output"""
        try:
            result = subprocess.run(
                cmd, shell=True, capture_output=True, text=True, timeout=timeout
            )
            return {
                'success': result.returncode == 0,
                'stdout': result.stdout,
                'stderr': result.stderr,
                'returncode': result.returncode
            }
        except subprocess.TimeoutExpired:
            return {
                'success': False,
                'stdout': '',
                'stderr': 'Command timed out',
                'returncode': -1
            }
    
    def check_container_running(self, container_name):
        """Check if a container is running"""
        result = self.run_command(f"podman ps --filter name={container_name} --format json")
        if result['success'] and result['stdout'].strip():
            try:
                containers = json.loads(result['stdout'])
                return len(containers) > 0
            except json.JSONDecodeError:
                return False
        return False
    
    def test_container_detection(self, container_name):
        """Test container detection logic in a specific container"""
        print(f"🔍 Testing container detection in {container_name}...")
        
        # Test the container detection playbook
        detection_cmd = f"""
podman exec {container_name} ansible-playbook -i localhost, -c local \\
    /tmp/test_container_detection.yml --extra-vars "target_host=localhost"
"""
        
        result = self.run_command(detection_cmd, timeout=60)
        
        test_result = {
            'container': container_name,
            'detection_success': result['success'],
            'output': result['stdout'],
            'errors': result['stderr']
        }
        
        # Parse the output for specific detection criteria
        if result['success']:
            output = result['stdout']
            test_result['virtualization_detected'] = 'container' in output.lower()
            test_result['container_environment_detected'] = 'is_container_environment' in output
            test_result['task_skipping_active'] = 'skipped' in output.lower()
        
        self.test_results['detection_tests'][container_name] = test_result
        return result['success']
    
    def test_role_execution(self, container_name):
        """Test that the kvmhost_setup role runs without errors in container"""
        print(f"🧪 Testing role execution in {container_name}...")
        
        # Create a minimal test playbook
        test_playbook = f"""
---
- name: Test KVM Host Setup in Container
  hosts: localhost
  connection: local
  become: true
  vars:
    admin_user: test
    domain: test.local
  roles:
    - kvmhost_setup
"""
        
        # Copy test playbook to container
        self.run_command(f"echo '{test_playbook}' | podman exec -i {container_name} tee /tmp/test_role.yml")
        
        # Run the role test
        role_cmd = f"""
podman exec {container_name} ansible-playbook -i localhost, -c local /tmp/test_role.yml
"""
        
        result = self.run_command(role_cmd, timeout=300)  # 5 minutes timeout for role execution
        
        test_result = {
            'container': container_name,
            'role_execution_success': result['success'],
            'output': result['stdout'],
            'errors': result['stderr']
        }
        
        # Count how many tasks were skipped due to container detection
        if result['stdout']:
            skipped_count = result['stdout'].count('skipped')
            test_result['tasks_skipped'] = skipped_count
            test_result['container_appropriate_execution'] = skipped_count > 0
        
        self.test_results['task_skipping_tests'][container_name] = test_result
        return result['success']
    
    def validate_container_platform(self, container_name):
        """Validate a specific container platform"""
        print(f"\n🐳 Validating container platform: {container_name}")
        
        if not self.check_container_running(container_name):
            print(f"❌ Container {container_name} is not running")
            self.test_results['platform_tests'][container_name] = {
                'available': False,
                'detection_test': False,
                'role_test': False,
                'overall': 'failed'
            }
            return False
        
        print(f"✅ Container {container_name} is running")
        
        # Test container detection
        detection_success = self.test_container_detection(container_name)
        
        # Test role execution
        role_success = self.test_role_execution(container_name)
        
        overall_success = detection_success and role_success
        
        self.test_results['platform_tests'][container_name] = {
            'available': True,
            'detection_test': detection_success,
            'role_test': role_success,
            'overall': 'passed' if overall_success else 'failed'
        }
        
        status_icon = "✅" if overall_success else "❌"
        print(f"{status_icon} Platform {container_name}: {'PASSED' if overall_success else 'FAILED'}")
        
        return overall_success
    
    def run_validation(self):
        """Run the complete container compatibility validation"""
        print("🚀 Starting Container Compatibility Validation")
        print("=" * 60)
        
        # Define containers to test (should match our Molecule setup)
        test_containers = ['rocky-9', 'alma-9', 'rhel-9', 'rhel-10']
        
        validation_results = []
        
        for container in test_containers:
            success = self.validate_container_platform(container)
            validation_results.append(success)
        
        # Calculate overall results
        total_tests = len(test_containers)
        passed_tests = sum(validation_results)
        
        self.test_results['overall_status'] = 'passed' if passed_tests == total_tests else 'partial' if passed_tests > 0 else 'failed'
        
        print("\n" + "=" * 60)
        print("🎯 Container Compatibility Validation Summary")
        print("=" * 60)
        
        for container in test_containers:
            platform_result = self.test_results['platform_tests'].get(container, {})
            status = platform_result.get('overall', 'unknown')
            icon = "✅" if status == 'passed' else "❌" if status == 'failed' else "⚠️"
            print(f"{icon} {container:<15} - {status.upper()}")
        
        print(f"\n📊 Results: {passed_tests}/{total_tests} platforms passed")
        
        # Print detailed analysis
        print("\n🔍 Detailed Analysis:")
        
        # Container detection analysis
        detection_success = sum(1 for t in self.test_results['detection_tests'].values() if t.get('detection_success', False))
        print(f"🎯 Container Detection: {detection_success}/{len(self.test_results['detection_tests'])} successful")
        
        # Task skipping analysis
        task_skipping_success = sum(1 for t in self.test_results['task_skipping_tests'].values() if t.get('container_appropriate_execution', False))
        print(f"⏭️  Task Skipping: {task_skipping_success}/{len(self.test_results['task_skipping_tests'])} appropriate")
        
        # Overall status
        if self.test_results['overall_status'] == 'passed':
            print("\n🎉 ✅ ALL CONTAINER PLATFORMS VALIDATED SUCCESSFULLY")
            return True
        elif self.test_results['overall_status'] == 'partial':
            print("\n⚠️  PARTIAL SUCCESS - Some platforms failed validation")
            return False
        else:
            print("\n❌ VALIDATION FAILED - Critical issues detected")
            return False
    
    def save_results(self, output_file="container-compatibility-validation.json"):
        """Save validation results to file"""
        with open(output_file, 'w') as f:
            json.dump(self.test_results, f, indent=2)
        print(f"\n📄 Detailed results saved to: {output_file}")


def main():
    """Main execution function"""
    validator = ContainerCompatibilityValidator()
    
    # First, ensure our test container detection playbook exists
    if not Path('test_container_detection.yml').exists():
        print("❌ test_container_detection.yml not found - creating basic version")
        basic_test = """---
- name: Test Container Detection
  hosts: "{{ target_host | default('localhost') }}"
  gather_facts: true
  tasks:
    - name: Advanced container environment detection
      ansible.builtin.set_fact:
        is_container_environment: >-
          {{
            ansible_virtualization_type in ['container', 'docker', 'podman', 'lxc'] or
            ansible_env.container is defined or
            ansible_facts.get('ansible_proc_cmdline', {}).get('init', '') == '/usr/sbin/init' or
            (ansible_mounts | selectattr('mount', 'equalto', '/') | first).fstype in ['overlay', 'tmpfs'] or
            ansible_facts.get('ansible_selinux', {}).get('type', '') == 'docker_t'
          }}
    
    - name: Display detection results
      ansible.builtin.debug:
        msg: |
          Container Detection Results:
          - Virtualization Type: {{ ansible_virtualization_type | default('unknown') }}
          - Container Environment: {{ is_container_environment }}
          - Host: {{ inventory_hostname }}
"""
        with open('test_container_detection.yml', 'w') as f:
            f.write(basic_test)
    
    # Run the validation
    success = validator.run_validation()
    
    # Save results
    validator.save_results()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
