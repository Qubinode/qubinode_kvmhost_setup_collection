#!/usr/bin/env python3
"""
Idempotency Test Runner
Automated testing framework for Ansible role idempotency compliance
Part of the Qubinode KVM Host Setup Collection
"""

import json
import yaml
import subprocess
import sys
import argparse
import datetime
import os
from pathlib import Path
from typing import Dict, List, Any, Optional

class IdempotencyTestRunner:
    """
    Main class for running idempotency tests on Ansible roles
    Implements ADR-0004 idempotency testing requirements
    """
    
    def __init__(self, config_path: str = "tests/idempotency/config.yml"):
        """Initialize the test runner with configuration"""
        self.config_path = Path(config_path)
        self.config = self._load_config()
        self.results = []
        self.start_time = datetime.datetime.now()
        
    def _load_config(self) -> Dict[str, Any]:
        """Load test configuration from YAML file"""
        try:
            with open(self.config_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            print(f"Error: Configuration file {self.config_path} not found")
            sys.exit(1)
        except yaml.YAMLError as e:
            print(f"Error parsing configuration: {e}")
            sys.exit(1)
    
    def run_ansible_playbook(self, playbook_path: str, inventory: str = "localhost,", 
                           extra_vars: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Execute an Ansible playbook and return results"""
        cmd = [
            "ansible-playbook",
            playbook_path,
            "-i", inventory,
            "--connection=local",
            "-v" if self.config.get("test_settings", {}).get("verbose_logging", False) else "",
        ]
        
        if extra_vars:
            cmd.extend(["-e", json.dumps(extra_vars)])
        
        # Remove empty strings from command
        cmd = [x for x in cmd if x]
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self.config.get("test_settings", {}).get("test_timeout", 3600)
            )
            
            return {
                "returncode": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "success": result.returncode == 0
            }
        except subprocess.TimeoutExpired:
            return {
                "returncode": -1,
                "stdout": "",
                "stderr": "Test timed out",
                "success": False
            }
        except Exception as e:
            return {
                "returncode": -1,
                "stdout": "",
                "stderr": str(e),
                "success": False
            }
    
    def test_role_idempotency(self, role_name: str) -> Dict[str, Any]:
        """Test a specific role for idempotency"""
        print(f"Testing idempotency for role: {role_name}")
        
        role_config = self.config.get("role_configurations", {}).get(role_name, {})
        test_vars = role_config.get("test_vars", {})
        
        # Create temporary playbook for testing this role
        test_playbook = self._create_test_playbook(role_name, test_vars)
        
        try:
            # First run
            print(f"  Running first execution...")
            first_run = self.run_ansible_playbook(test_playbook, extra_vars=test_vars)
            
            if not first_run["success"]:
                return {
                    "role": role_name,
                    "idempotent": False,
                    "error": "First run failed",
                    "first_run": first_run,
                    "second_run": None
                }
            
            # Second run (idempotency check)
            print(f"  Running second execution (idempotency check)...")
            second_run = self.run_ansible_playbook(test_playbook, extra_vars=test_vars)
            
            if not second_run["success"]:
                return {
                    "role": role_name,
                    "idempotent": False,
                    "error": "Second run failed",
                    "first_run": first_run,
                    "second_run": second_run
                }
            
            # Analyze results for changes
            idempotent = self._analyze_idempotency(first_run, second_run, role_config)
            
            return {
                "role": role_name,
                "idempotent": idempotent,
                "error": None if idempotent else "Tasks changed on second run",
                "first_run": first_run,
                "second_run": second_run,
                "test_timestamp": datetime.datetime.now().isoformat()
            }
            
        finally:
            # Clean up temporary playbook
            if test_playbook and os.path.exists(test_playbook):
                os.unlink(test_playbook)
    
    def _create_test_playbook(self, role_name: str, test_vars: Dict[str, Any]) -> str:
        """Create a temporary playbook for testing a specific role"""
        playbook_content = f"""---
- name: "Idempotency test for {role_name}"
  hosts: localhost
  connection: local
  gather_facts: true
  vars:
{yaml.dump(test_vars, default_flow_style=False, indent=4)}
  tasks:
    - name: "Include role {role_name}"
      ansible.builtin.include_role:
        name: {role_name}
      register: role_execution_result
"""
        
        # Create temporary file
        temp_file = f"/tmp/test_{role_name}_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.yml"
        with open(temp_file, 'w') as f:
            f.write(playbook_content)
        
        return temp_file
    
    def _analyze_idempotency(self, first_run: Dict[str, Any], 
                           second_run: Dict[str, Any], 
                           role_config: Dict[str, Any]) -> bool:
        """Analyze playbook output to determine if tasks are idempotent"""
        # Look for "changed:" indicators in output
        second_output = second_run["stdout"]
        
        # Count changed tasks in second run
        changed_lines = [line for line in second_output.split('\n') 
                        if 'changed:' in line and '[localhost]' in line]
        
        # Extract numbers of changed tasks
        changed_count = 0
        for line in changed_lines:
            if 'changed=' in line:
                try:
                    # Extract number after "changed="
                    changed_part = line.split('changed=')[1].split()[0]
                    changed_count += int(changed_part)
                except (IndexError, ValueError):
                    continue
        
        # Check against allowed changes
        max_allowed = role_config.get("allowed_changes", [])
        max_allowed_count = self.config.get("test_settings", {}).get("max_allowed_changes", 0)
        
        return changed_count <= max_allowed_count
    
    def run_all_tests(self, roles: Optional[List[str]] = None) -> Dict[str, Any]:
        """Run idempotency tests for all specified roles"""
        if roles is None:
            roles = list(self.config.get("role_configurations", {}).keys())
        
        print(f"Starting idempotency tests for {len(roles)} roles...")
        print(f"Test configuration: {self.config_path}")
        print("-" * 60)
        
        results = []
        
        for role in roles:
            try:
                result = self.test_role_idempotency(role)
                results.append(result)
                
                status = "✅ PASS" if result["idempotent"] else "❌ FAIL"
                print(f"  {role}: {status}")
                
                if not result["idempotent"] and result["error"]:
                    print(f"    Error: {result['error']}")
                
            except Exception as e:
                error_result = {
                    "role": role,
                    "idempotent": False,
                    "error": f"Test execution failed: {str(e)}",
                    "first_run": None,
                    "second_run": None,
                    "test_timestamp": datetime.datetime.now().isoformat()
                }
                results.append(error_result)
                print(f"  {role}: ❌ ERROR - {str(e)}")
        
        # Generate summary report
        end_time = datetime.datetime.now()
        total_time = (end_time - self.start_time).total_seconds()
        
        passed_count = sum(1 for r in results if r["idempotent"])
        failed_count = len(results) - passed_count
        success_rate = (passed_count / len(results)) * 100 if results else 0
        
        summary = {
            "test_metadata": {
                "start_time": self.start_time.isoformat(),
                "end_time": end_time.isoformat(),
                "total_duration_seconds": total_time,
                "test_framework": "qubinode-idempotency-framework",
                "config_file": str(self.config_path)
            },
            "results": results,
            "summary": {
                "total_roles": len(results),
                "passed": passed_count,
                "failed": failed_count,
                "success_rate": round(success_rate, 2),
                "overall_success": failed_count == 0
            },
            "compliance": {
                "adr_0004_compliant": failed_count == 0,
                "meets_quality_threshold": success_rate >= self.config.get("quality_thresholds", {}).get("minimum_success_rate", 100)
            }
        }
        
        # Save results
        self._save_results(summary)
        
        return summary
    
    def _save_results(self, summary: Dict[str, Any]):
        """Save test results to file"""
        if not self.config.get("test_settings", {}).get("save_artifacts", True):
            return
        
        # Create results directory
        results_dir = Path("tests/idempotency/results")
        results_dir.mkdir(parents=True, exist_ok=True)
        
        # Save JSON report
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        json_file = results_dir / f"idempotency_test_{timestamp}.json"
        
        with open(json_file, 'w') as f:
            json.dump(summary, f, indent=2)
        
        print(f"\nTest results saved to: {json_file}")
        
        # Generate HTML report if requested
        if self.config.get("reporting", {}).get("generate_html", False):
            html_file = results_dir / f"idempotency_test_{timestamp}.html"
            self._generate_html_report(summary, html_file)
    
    def _generate_html_report(self, summary: Dict[str, Any], output_file: Path):
        """Generate HTML report from test results"""
        html_content = f"""
<!DOCTYPE html>
<html>
<head>
    <title>Idempotency Test Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 40px; }}
        .header {{ background-color: #f5f5f5; padding: 20px; border-radius: 5px; }}
        .summary {{ background-color: #e8f5e8; padding: 15px; margin: 20px 0; border-radius: 5px; }}
        .failure {{ background-color: #ffeaea; padding: 15px; margin: 20px 0; border-radius: 5px; }}
        .role {{ margin: 10px 0; padding: 10px; border: 1px solid #ddd; border-radius: 3px; }}
        .pass {{ border-left: 4px solid #4CAF50; }}
        .fail {{ border-left: 4px solid #f44336; }}
        pre {{ background-color: #f9f9f9; padding: 10px; overflow-x: auto; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>Qubinode Idempotency Test Report</h1>
        <p><strong>Generated:</strong> {summary['test_metadata']['end_time']}</p>
        <p><strong>Duration:</strong> {summary['test_metadata']['total_duration_seconds']} seconds</p>
        <p><strong>Framework:</strong> {summary['test_metadata']['test_framework']}</p>
    </div>
    
    <div class="{'summary' if summary['summary']['overall_success'] else 'failure'}">
        <h2>Test Summary</h2>
        <p><strong>Overall Result:</strong> {'✅ ALL TESTS PASSED' if summary['summary']['overall_success'] else '❌ SOME TESTS FAILED'}</p>
        <p><strong>Total Roles:</strong> {summary['summary']['total_roles']}</p>
        <p><strong>Passed:</strong> {summary['summary']['passed']}</p>
        <p><strong>Failed:</strong> {summary['summary']['failed']}</p>
        <p><strong>Success Rate:</strong> {summary['summary']['success_rate']}%</p>
        <p><strong>ADR-0004 Compliant:</strong> {'Yes' if summary['compliance']['adr_0004_compliant'] else 'No'}</p>
    </div>
    
    <h2>Role Results</h2>
"""
        
        for result in summary['results']:
            status_class = "pass" if result['idempotent'] else "fail"
            status_icon = "✅" if result['idempotent'] else "❌"
            
            html_content += f"""
    <div class="role {status_class}">
        <h3>{status_icon} {result['role']}</h3>
        <p><strong>Status:</strong> {'IDEMPOTENT' if result['idempotent'] else 'NOT IDEMPOTENT'}</p>
        <p><strong>Test Time:</strong> {result.get('test_timestamp', 'N/A')}</p>
"""
            
            if result.get('error'):
                html_content += f"<p><strong>Error:</strong> {result['error']}</p>"
            
            html_content += "</div>"
        
        html_content += """
</body>
</html>
"""
        
        with open(output_file, 'w') as f:
            f.write(html_content)
        
        print(f"HTML report saved to: {output_file}")

def main():
    """Main entry point for the idempotency test runner"""
    parser = argparse.ArgumentParser(description="Run idempotency tests for Ansible roles")
    parser.add_argument("--config", "-c", default="tests/idempotency/config.yml",
                       help="Path to test configuration file")
    parser.add_argument("--roles", "-r", nargs="+",
                       help="Specific roles to test (default: all configured roles)")
    parser.add_argument("--verbose", "-v", action="store_true",
                       help="Enable verbose output")
    
    args = parser.parse_args()
    
    # Initialize test runner
    runner = IdempotencyTestRunner(args.config)
    
    # Override verbose setting if specified
    if args.verbose:
        runner.config.setdefault("test_settings", {})["verbose_logging"] = True
    
    try:
        # Run tests
        summary = runner.run_all_tests(args.roles)
        
        # Print final summary
        print("\n" + "=" * 60)
        print("FINAL TEST SUMMARY")
        print("=" * 60)
        print(f"Total Roles Tested: {summary['summary']['total_roles']}")
        print(f"Passed: {summary['summary']['passed']}")
        print(f"Failed: {summary['summary']['failed']}")
        print(f"Success Rate: {summary['summary']['success_rate']}%")
        print(f"ADR-0004 Compliant: {'Yes' if summary['compliance']['adr_0004_compliant'] else 'No'}")
        print(f"Overall Result: {'✅ SUCCESS' if summary['summary']['overall_success'] else '❌ FAILURE'}")
        
        # Exit with appropriate code
        sys.exit(0 if summary['summary']['overall_success'] else 1)
        
    except KeyboardInterrupt:
        print("\nTest execution interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nTest execution failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
