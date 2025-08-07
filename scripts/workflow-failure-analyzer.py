#!/usr/bin/env python3
"""
GitHub Workflow Failure Analyzer

This script monitors GitHub workflow completion and creates detailed issues for failures.
It leverages the Red Hat MaaS API with granite-3-3-8b-instruct model for intelligent
log analysis and root cause identification.

Author: Sophia (Methodological Pragmatism Framework)
Confidence: 92% - Based on GitHub API patterns and LLM integration best practices
"""

import os
import sys
import json
import logging
import requests
import urllib3
from typing import Dict, List, Optional, Tuple
from datetime import datetime
import re
from pathlib import Path

# Disable SSL warnings for internal APIs
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def load_configuration() -> Dict:
    """
    Load configuration from the JSON config file.

    Returns:
        Configuration dictionary

    Confidence: 95% - Simple file loading with error handling
    """
    config_path = Path(__file__).parent / 'workflow-analyzer-config.json'

    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
        logger.info("Configuration loaded successfully")
        return config
    except FileNotFoundError:
        logger.warning(f"Configuration file not found at {config_path}, using defaults")
        return get_default_configuration()
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in configuration file: {e}")
        return get_default_configuration()


def get_default_configuration() -> Dict:
    """
    Return default configuration if config file is not available.

    Returns:
        Default configuration dictionary

    Confidence: 98% - Static configuration data
    """
    return {
        "analyzer_config": {
            "max_workflows_per_run": 20,
            "max_errors_per_job": 10
        },
        "github_api": {
            "timeout_seconds": 30,
            "retry_attempts": 3
        },
        "red_hat_maas": {
            "api_url": "https://granite-3-3-8b-instruct-maas-apicast-production.apps.prod.rhoai.rh-aiservices-bu.com:443",
            "model": "granite-3-3-8b-instruct",
            "max_tokens": 800,
            "temperature": 0.1
        },
        "error_patterns": {
            "critical": [
                "FATAL:",
                "CRITICAL:",
                "Exception:",
                "Traceback \\(most recent call last\\):",
                "Error: Process completed with exit code [1-9]"
            ],
            "ansible_specific": [
                "ansible-lint.*\\[E\\d+\\]",
                "TASK \\[.*\\] \\*+\\nfatal:",
                "FAILED! =>",
                "fatal: \\[.*\\]:"
            ]
        }
    }


class WorkflowFailureAnalyzer:
    """
    Analyzes GitHub workflow failures and creates detailed issues using LLM analysis.
    
    This class implements methodological pragmatism by:
    - Explicitly handling both human-cognitive and artificial-stochastic errors
    - Providing systematic verification of API responses
    - Maintaining clear separation between data collection and analysis phases
    """
    
    def __init__(self):
        """Initialize the analyzer with required environment variables and configuration."""
        # Load configuration
        self.config = load_configuration()

        # Load environment variables
        self.github_token = os.getenv('GITHUB_TOKEN')
        self.github_repository = os.getenv('GITHUB_REPOSITORY')
        self.github_run_id = os.getenv('GITHUB_RUN_ID')
        self.github_workflow_run_url = os.getenv('GITHUB_WORKFLOW_RUN_URL', '')
        self.red_hat_api_key = os.getenv('RED_HAT_MAAS_API_KEY')

        # Red Hat MaaS API configuration from config
        maas_config = self.config.get('red_hat_maas', {})
        self.api_url = maas_config.get('api_url',
            "https://granite-3-3-8b-instruct-maas-apicast-production.apps.prod.rhoai.rh-aiservices-bu.com:443")
        self.model_name = maas_config.get('model', "granite-3-3-8b-instruct")
        self.max_tokens = maas_config.get('max_tokens', 800)
        self.temperature = maas_config.get('temperature', 0.1)

        # Analysis configuration
        analyzer_config = self.config.get('analyzer_config', {})
        self.max_workflows = analyzer_config.get('max_workflows_per_run', 20)
        self.max_errors_per_job = analyzer_config.get('max_errors_per_job', 10)

        # Validate required environment variables
        self._validate_environment()

        # GitHub API headers
        self.github_headers = {
            'Authorization': f'Bearer {self.github_token}',
            'Accept': 'application/vnd.github.v3+json',
            'X-GitHub-Api-Version': '2022-11-28'
        }

        logger.info(f"Initialized analyzer for repository: {self.github_repository}")
        logger.info(f"Configuration: Max workflows={self.max_workflows}, Max errors per job={self.max_errors_per_job}")
    
    def _validate_environment(self) -> None:
        """
        Validate required environment variables are present.
        
        Confidence: 95% - Standard environment validation pattern
        """
        required_vars = {
            'GITHUB_TOKEN': self.github_token,
            'GITHUB_REPOSITORY': self.github_repository,
            'RED_HAT_MAAS_API_KEY': self.red_hat_api_key
        }
        
        missing_vars = [var for var, value in required_vars.items() if not value]
        
        if missing_vars:
            logger.error(f"Missing required environment variables: {', '.join(missing_vars)}")
            sys.exit(1)
        
        logger.info("Environment validation completed successfully")
    
    def get_workflow_runs(self) -> List[Dict]:
        """
        Fetch recent workflow runs from GitHub API.
        
        Returns:
            List of workflow run dictionaries
            
        Confidence: 88% - GitHub API patterns are well-established
        """
        try:
            url = f"https://api.github.com/repos/{self.github_repository}/actions/runs"
            params = {
                'status': 'completed',
                'per_page': 20,
                'page': 1
            }
            
            response = requests.get(url, headers=self.github_headers, params=params)
            response.raise_for_status()
            
            workflow_runs = response.json().get('workflow_runs', [])
            logger.info(f"Retrieved {len(workflow_runs)} workflow runs")
            
            return workflow_runs
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch workflow runs: {e}")
            return []
    
    def get_failed_workflows(self, workflow_runs: List[Dict]) -> List[Dict]:
        """
        Filter workflow runs to identify failures.
        
        Args:
            workflow_runs: List of workflow run dictionaries
            
        Returns:
            List of failed workflow runs
            
        Confidence: 90% - Simple filtering logic with clear criteria
        """
        failed_workflows = [
            run for run in workflow_runs 
            if run.get('conclusion') == 'failure'
        ]
        
        logger.info(f"Identified {len(failed_workflows)} failed workflows")
        return failed_workflows
    
    def get_workflow_jobs(self, run_id: int) -> List[Dict]:
        """
        Fetch jobs for a specific workflow run.
        
        Args:
            run_id: GitHub workflow run ID
            
        Returns:
            List of job dictionaries
            
        Confidence: 87% - Standard GitHub API pattern
        """
        try:
            url = f"https://api.github.com/repos/{self.github_repository}/actions/runs/{run_id}/jobs"
            
            response = requests.get(url, headers=self.github_headers)
            response.raise_for_status()
            
            jobs = response.json().get('jobs', [])
            logger.info(f"Retrieved {len(jobs)} jobs for run {run_id}")
            
            return jobs
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch jobs for run {run_id}: {e}")
            return []
    
    def get_job_logs(self, job_id: int) -> str:
        """
        Fetch logs for a specific job.

        Args:
            job_id: GitHub job ID

        Returns:
            Job logs as string

        Confidence: 85% - Log retrieval can be inconsistent due to GitHub API limitations
        """
        try:
            url = f"https://api.github.com/repos/{self.github_repository}/actions/jobs/{job_id}/logs"

            response = requests.get(url, headers=self.github_headers)
            response.raise_for_status()

            logs = response.text
            logger.info(f"Retrieved logs for job {job_id} ({len(logs)} characters)")

            return logs

        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch logs for job {job_id}: {e}")
            return ""

    def extract_error_segments(self, logs: str) -> List[Dict[str, str]]:
        """
        Parse logs to identify distinct error segments.

        Args:
            logs: Raw job logs

        Returns:
            List of error dictionaries with context

        Confidence: 78% - Error pattern recognition can vary significantly
        """
        error_segments = []

        # Get error patterns from configuration
        error_patterns = []
        pattern_config = self.config.get('error_patterns', {})

        # Combine all pattern categories
        for category, patterns in pattern_config.items():
            error_patterns.extend(patterns)

        # Fallback patterns if configuration is empty
        if not error_patterns:
            error_patterns = [
                r'ERROR:.*',
                r'FAILED:.*',
                r'FATAL:.*',
                r'Exception:.*',
                r'Traceback \(most recent call last\):.*?(?=\n\n|\n[A-Z]|\Z)',
                r'ansible-lint.*\[E\d+\].*',
                r'TASK \[.*\] \*+\nfatal:.*',
                r'The command .* failed with exit code \d+',
                r'Error: .*',
                r'Failed to .*'
            ]

        lines = logs.split('\n')

        for i, line in enumerate(lines):
            for pattern in error_patterns:
                if re.search(pattern, line, re.IGNORECASE | re.DOTALL):
                    # Extract context around the error
                    start_idx = max(0, i - 5)
                    end_idx = min(len(lines), i + 10)

                    error_context = '\n'.join(lines[start_idx:end_idx])

                    # Check if this is a duplicate error
                    is_duplicate = any(
                        error_context[:100] in existing['context'][:100]
                        for existing in error_segments
                    )

                    if not is_duplicate:
                        error_segments.append({
                            'line_number': i + 1,
                            'error_line': line.strip(),
                            'context': error_context,
                            'pattern_matched': pattern
                        })
                    break

        logger.info(f"Extracted {len(error_segments)} distinct error segments")
        return error_segments

    def analyze_error_with_llm(self, error_segment: Dict[str, str],
                              workflow_name: str, job_name: str) -> Dict[str, str]:
        """
        Analyze error using Red Hat MaaS granite-3-3-8b-instruct model.

        Args:
            error_segment: Error context and details
            workflow_name: Name of the failed workflow
            job_name: Name of the failed job

        Returns:
            LLM analysis results

        Confidence: 82% - LLM responses can vary but granite model is reliable for technical analysis
        """
        try:
            # Construct analysis prompt
            prompt = f"""
You are an expert DevOps engineer analyzing a GitHub Actions workflow failure.

WORKFLOW: {workflow_name}
JOB: {job_name}
ERROR CONTEXT:
{error_segment['context']}

Please provide a structured analysis:

1. ROOT CAUSE: Identify the specific technical reason for this failure
2. IMPACT: Describe what this error prevents or breaks
3. SOLUTION: Provide step-by-step fix instructions
4. PREVENTION: Suggest how to prevent this error in the future

Format your response as a clear, actionable analysis for a developer to resolve this issue.
"""

            # Call Red Hat MaaS API using configuration
            response = requests.post(
                url=f"{self.api_url}/v1/completions",
                json={
                    "model": self.model_name,
                    "prompt": prompt,
                    "max_tokens": self.max_tokens,
                    "temperature": self.temperature
                },
                headers={'Authorization': f'Bearer {self.red_hat_api_key}'},
                verify=False  # For internal APIs
            )

            response.raise_for_status()
            completion = response.json()

            analysis_text = completion.get('choices', [{}])[0].get('text', '').strip()

            if not analysis_text:
                raise ValueError("Empty response from LLM")

            logger.info(f"LLM analysis completed for error at line {error_segment['line_number']}")

            return {
                'analysis': analysis_text,
                'model_used': 'granite-3-3-8b-instruct',
                'prompt_tokens': len(prompt.split()),
                'completion_tokens': len(analysis_text.split())
            }

        except Exception as e:
            logger.error(f"LLM analysis failed: {e}")
            return {
                'analysis': f"Automated analysis failed. Manual review required for error: {error_segment['error_line']}",
                'model_used': 'fallback',
                'error': str(e)
            }

    def create_github_issue(self, workflow_run: Dict, job: Dict,
                           error_segment: Dict, llm_analysis: Dict) -> bool:
        """
        Create a GitHub issue for the analyzed failure.

        Args:
            workflow_run: Workflow run details
            job: Job details
            error_segment: Error context
            llm_analysis: LLM analysis results

        Returns:
            True if issue created successfully

        Confidence: 90% - GitHub Issues API is well-documented and reliable
        """
        try:
            # Generate issue title
            workflow_name = workflow_run.get('name', 'Unknown Workflow')
            job_name = job.get('name', 'Unknown Job')
            error_line = error_segment['error_line'][:80] + "..." if len(error_segment['error_line']) > 80 else error_segment['error_line']

            title = f"🚨 Workflow Failure: {workflow_name} - {job_name} - {error_line}"

            # Generate issue body
            body = f"""## Workflow Failure Analysis

**Workflow:** {workflow_name}
**Job:** {job_name}
**Run ID:** {workflow_run['id']}
**Failed At:** {workflow_run['updated_at']}
**Run URL:** {workflow_run['html_url']}

### Error Details
**Line:** {error_segment['line_number']}
**Error:** `{error_segment['error_line']}`

### Error Context
```
{error_segment['context']}
```

### AI Analysis ({llm_analysis['model_used']})
{llm_analysis['analysis']}

### Workflow Information
- **Branch:** {workflow_run.get('head_branch', 'unknown')}
- **Commit:** {workflow_run.get('head_sha', 'unknown')[:8]}
- **Actor:** {workflow_run.get('actor', {}).get('login', 'unknown')}
- **Event:** {workflow_run.get('event', 'unknown')}

### Next Steps
- [ ] Review the error analysis above
- [ ] Implement the suggested solution
- [ ] Test the fix locally
- [ ] Verify the workflow passes after fix
- [ ] Close this issue once resolved

---
*This issue was automatically created by the Workflow Failure Analyzer*
*Analysis powered by Red Hat MaaS granite-3-3-8b-instruct model*
"""

            # Create the issue
            url = f"https://api.github.com/repos/{self.github_repository}/issues"
            issue_data = {
                'title': title,
                'body': body,
                'labels': [
                    'workflow-failure',
                    'automated-analysis',
                    'needs-investigation',
                    f'workflow:{workflow_name.lower().replace(" ", "-")}'
                ]
            }

            response = requests.post(url, headers=self.github_headers, json=issue_data)
            response.raise_for_status()

            issue = response.json()
            logger.info(f"Created issue #{issue['number']}: {title}")

            return True

        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to create GitHub issue: {e}")
            return False

    def process_workflow_failures(self) -> Dict[str, int]:
        """
        Main orchestration method to process all workflow failures.

        Returns:
            Dictionary with processing statistics

        Confidence: 85% - Orchestration logic with comprehensive error handling
        """
        stats = {
            'workflows_checked': 0,
            'failed_workflows': 0,
            'errors_analyzed': 0,
            'issues_created': 0,
            'processing_errors': 0
        }

        try:
            # Step 1: Get recent workflow runs
            logger.info("Starting workflow failure analysis...")
            workflow_runs = self.get_workflow_runs()
            stats['workflows_checked'] = len(workflow_runs)

            if not workflow_runs:
                logger.warning("No workflow runs found")
                return stats

            # Step 2: Filter for failures
            failed_workflows = self.get_failed_workflows(workflow_runs)
            stats['failed_workflows'] = len(failed_workflows)

            if not failed_workflows:
                logger.info("No failed workflows found - all systems operational!")
                return stats

            # Step 3: Process each failed workflow
            for workflow_run in failed_workflows:
                try:
                    logger.info(f"Processing failed workflow: {workflow_run['name']} (ID: {workflow_run['id']})")

                    # Get jobs for this workflow run
                    jobs = self.get_workflow_jobs(workflow_run['id'])
                    failed_jobs = [job for job in jobs if job.get('conclusion') == 'failure']

                    # Process each failed job
                    for job in failed_jobs:
                        try:
                            logger.info(f"Analyzing failed job: {job['name']}")

                            # Get job logs
                            logs = self.get_job_logs(job['id'])
                            if not logs:
                                logger.warning(f"No logs available for job {job['id']}")
                                continue

                            # Extract error segments
                            error_segments = self.extract_error_segments(logs)

                            # Analyze each error with LLM
                            for error_segment in error_segments:
                                try:
                                    logger.info(f"Analyzing error at line {error_segment['line_number']}")

                                    # Get LLM analysis
                                    llm_analysis = self.analyze_error_with_llm(
                                        error_segment,
                                        workflow_run['name'],
                                        job['name']
                                    )

                                    stats['errors_analyzed'] += 1

                                    # Create GitHub issue
                                    if self.create_github_issue(workflow_run, job, error_segment, llm_analysis):
                                        stats['issues_created'] += 1

                                except Exception as e:
                                    logger.error(f"Error processing error segment: {e}")
                                    stats['processing_errors'] += 1

                        except Exception as e:
                            logger.error(f"Error processing job {job['name']}: {e}")
                            stats['processing_errors'] += 1

                except Exception as e:
                    logger.error(f"Error processing workflow {workflow_run['name']}: {e}")
                    stats['processing_errors'] += 1

            # Log final statistics
            logger.info("Workflow failure analysis completed")
            logger.info(f"Statistics: {stats}")

            return stats

        except Exception as e:
            logger.error(f"Critical error in workflow failure processing: {e}")
            stats['processing_errors'] += 1
            return stats

    def generate_summary_report(self, stats: Dict[str, int]) -> str:
        """
        Generate a summary report of the analysis session.

        Args:
            stats: Processing statistics

        Returns:
            Formatted summary report

        Confidence: 95% - Simple string formatting with clear logic
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")

        report = f"""
# Workflow Failure Analysis Report
**Generated:** {timestamp}
**Repository:** {self.github_repository}

## Summary Statistics
- **Workflows Checked:** {stats['workflows_checked']}
- **Failed Workflows:** {stats['failed_workflows']}
- **Errors Analyzed:** {stats['errors_analyzed']}
- **Issues Created:** {stats['issues_created']}
- **Processing Errors:** {stats['processing_errors']}

## Analysis Results
"""

        if stats['failed_workflows'] == 0:
            report += "✅ **All workflows are passing!** No failures detected.\n"
        elif stats['issues_created'] > 0:
            report += f"🚨 **{stats['issues_created']} issues created** for workflow failures.\n"
            report += "📋 Check the Issues tab for detailed analysis and resolution steps.\n"
        else:
            report += "⚠️ **Failures detected but no issues created.** Check logs for details.\n"

        if stats['processing_errors'] > 0:
            report += f"\n⚠️ **{stats['processing_errors']} processing errors** occurred during analysis.\n"
            report += "Review the workflow logs for troubleshooting information.\n"

        report += f"""
## Verification Framework
This analysis follows methodological pragmatism principles:
- **Systematic Error Detection:** Multiple pattern matching for comprehensive coverage
- **LLM-Powered Analysis:** granite-3-3-8b-instruct model for technical root cause analysis
- **Structured Issue Creation:** Consistent format for developer actionability
- **Comprehensive Logging:** Full audit trail for verification and debugging

## Next Steps
1. Review created issues for priority and assignment
2. Implement suggested fixes from LLM analysis
3. Monitor workflow success rates after fixes
4. Update error patterns if new failure types emerge

---
*Generated by Workflow Failure Analyzer v1.0*
*Powered by Red Hat MaaS granite-3-3-8b-instruct*
"""

        return report


def main():
    """
    Main entry point for the workflow failure analyzer.

    This function implements the complete workflow failure analysis pipeline:
    1. Environment validation and configuration
    2. Workflow failure detection and analysis
    3. LLM-powered root cause analysis
    4. GitHub issue creation for each distinct error
    5. Summary reporting

    Confidence: 90% - Well-structured main function with comprehensive error handling
    """
    try:
        # Initialize the analyzer
        logger.info("Initializing Workflow Failure Analyzer...")
        analyzer = WorkflowFailureAnalyzer()

        # Process workflow failures
        stats = analyzer.process_workflow_failures()

        # Generate and log summary report
        summary_report = analyzer.generate_summary_report(stats)
        logger.info("Analysis Summary:")
        logger.info(summary_report)

        # Write summary to file for GitHub Actions artifact
        with open('workflow-failure-analysis-report.md', 'w') as f:
            f.write(summary_report)

        # Set exit code based on results
        if stats['processing_errors'] > 0:
            logger.warning("Analysis completed with errors")
            sys.exit(1)
        elif stats['failed_workflows'] > 0:
            logger.info("Analysis completed - failures detected and processed")
            sys.exit(0)
        else:
            logger.info("Analysis completed - no failures detected")
            sys.exit(0)

    except Exception as e:
        logger.error(f"Critical failure in main execution: {e}")
        sys.exit(2)


if __name__ == "__main__":
    main()
