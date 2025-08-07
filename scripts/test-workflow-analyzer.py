#!/usr/bin/env python3
"""
Test Script for GitHub Workflow Failure Analyzer

This script validates the analyzer setup and tests key components
without triggering actual GitHub API calls or creating real issues.

Author: Sophia (Methodological Pragmatism Framework)
Confidence: 95% - Test validation with controlled inputs
"""

import os
import sys
import json
import logging
from unittest.mock import Mock, patch
import tempfile

# Add the scripts directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Configure logging for testing
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)


def test_environment_setup():
    """Test that all required environment variables are available."""
    logger.info("Testing environment setup...")
    
    required_vars = [
        'GITHUB_TOKEN',
        'GITHUB_REPOSITORY', 
        'RED_HAT_MAAS_API_KEY'
    ]
    
    missing_vars = []
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        logger.error(f"Missing environment variables: {missing_vars}")
        return False
    
    logger.info("✅ All required environment variables are set")
    return True


def test_configuration_loading():
    """Test loading and validating the configuration file."""
    logger.info("Testing configuration loading...")
    
    config_path = os.path.join(os.path.dirname(__file__), 'workflow-analyzer-config.json')
    
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
        
        # Validate required configuration sections
        required_sections = [
            'analyzer_config',
            'github_api', 
            'red_hat_maas',
            'error_patterns',
            'issue_templates'
        ]
        
        for section in required_sections:
            if section not in config:
                logger.error(f"Missing configuration section: {section}")
                return False
        
        logger.info("✅ Configuration file loaded and validated successfully")
        return True
        
    except Exception as e:
        logger.error(f"Configuration loading failed: {e}")
        return False


def test_error_pattern_matching():
    """Test error pattern matching with sample log data."""
    logger.info("Testing error pattern matching...")
    
    # Sample log data with various error types
    sample_logs = """
2024-01-15T10:30:00.000Z INFO Starting workflow
2024-01-15T10:30:05.000Z ERROR: Failed to connect to database
2024-01-15T10:30:10.000Z TASK [Install packages] **********************
2024-01-15T10:30:15.000Z fatal: [localhost]: FAILED! => {"msg": "Package not found"}
2024-01-15T10:30:20.000Z Traceback (most recent call last):
2024-01-15T10:30:20.001Z   File "test.py", line 10, in <module>
2024-01-15T10:30:20.002Z     import nonexistent_module
2024-01-15T10:30:20.003Z ModuleNotFoundError: No module named 'nonexistent_module'
2024-01-15T10:30:25.000Z ansible-lint [E301] Commands should not change things if nothing needs doing
2024-01-15T10:30:30.000Z INFO Workflow completed with errors
"""

    try:
        # Import the analyzer (this will test if the script is syntactically correct)
        from workflow_failure_analyzer import WorkflowFailureAnalyzer
        
        # Create a mock analyzer instance
        with patch.dict(os.environ, {
            'GITHUB_TOKEN': 'test_token',
            'GITHUB_REPOSITORY': 'test/repo',
            'RED_HAT_MAAS_API_KEY': 'test_key'
        }):
            analyzer = WorkflowFailureAnalyzer()
            
            # Test error extraction
            errors = analyzer.extract_error_segments(sample_logs)
            
            if len(errors) == 0:
                logger.error("No errors detected in sample logs")
                return False
            
            logger.info(f"✅ Detected {len(errors)} error segments in sample logs")
            
            # Validate error structure
            for i, error in enumerate(errors):
                required_fields = ['line_number', 'error_line', 'context', 'pattern_matched']
                for field in required_fields:
                    if field not in error:
                        logger.error(f"Error {i} missing required field: {field}")
                        return False
            
            logger.info("✅ Error pattern matching working correctly")
            return True
            
    except Exception as e:
        logger.error(f"Error pattern matching test failed: {e}")
        return False


def test_llm_integration():
    """Test LLM integration with mock responses."""
    logger.info("Testing LLM integration...")
    
    try:
        from workflow_failure_analyzer import WorkflowFailureAnalyzer
        
        # Mock the requests.post call for LLM API
        mock_response = Mock()
        mock_response.raise_for_status.return_value = None
        mock_response.json.return_value = {
            'choices': [{
                'text': """
ROOT CAUSE: The module 'nonexistent_module' is not installed in the Python environment.

IMPACT: This prevents the script from running and causes the workflow to fail.

SOLUTION: 
1. Add the missing module to requirements.txt
2. Install the module using pip install
3. Update the workflow to install dependencies

PREVENTION: Use dependency management tools and virtual environments.
"""
            }]
        }
        
        with patch('requests.post', return_value=mock_response):
            with patch.dict(os.environ, {
                'GITHUB_TOKEN': 'test_token',
                'GITHUB_REPOSITORY': 'test/repo', 
                'RED_HAT_MAAS_API_KEY': 'test_key'
            }):
                analyzer = WorkflowFailureAnalyzer()
                
                # Test LLM analysis
                error_segment = {
                    'line_number': 10,
                    'error_line': 'ModuleNotFoundError: No module named nonexistent_module',
                    'context': 'Sample error context',
                    'pattern_matched': 'ModuleNotFoundError:'
                }
                
                analysis = analyzer.analyze_error_with_llm(
                    error_segment, 
                    'Test Workflow', 
                    'Test Job'
                )
                
                if 'analysis' not in analysis:
                    logger.error("LLM analysis missing 'analysis' field")
                    return False
                
                if 'ROOT CAUSE' not in analysis['analysis']:
                    logger.error("LLM analysis missing expected content structure")
                    return False
                
                logger.info("✅ LLM integration test passed")
                return True
                
    except Exception as e:
        logger.error(f"LLM integration test failed: {e}")
        return False


def test_github_issue_creation():
    """Test GitHub issue creation with mock API calls."""
    logger.info("Testing GitHub issue creation...")
    
    try:
        from workflow_failure_analyzer import WorkflowFailureAnalyzer
        
        # Mock the requests.post call for GitHub API
        mock_response = Mock()
        mock_response.raise_for_status.return_value = None
        mock_response.json.return_value = {
            'number': 123,
            'title': 'Test Issue',
            'html_url': 'https://github.com/test/repo/issues/123'
        }
        
        with patch('requests.post', return_value=mock_response):
            with patch.dict(os.environ, {
                'GITHUB_TOKEN': 'test_token',
                'GITHUB_REPOSITORY': 'test/repo',
                'RED_HAT_MAAS_API_KEY': 'test_key'
            }):
                analyzer = WorkflowFailureAnalyzer()
                
                # Test issue creation
                workflow_run = {
                    'id': 12345,
                    'name': 'Test Workflow',
                    'html_url': 'https://github.com/test/repo/actions/runs/12345',
                    'updated_at': '2024-01-15T10:30:00Z',
                    'head_branch': 'main',
                    'head_sha': 'abc123def456',
                    'actor': {'login': 'testuser'},
                    'event': 'push'
                }
                
                job = {
                    'id': 67890,
                    'name': 'Test Job'
                }
                
                error_segment = {
                    'line_number': 10,
                    'error_line': 'Test error message',
                    'context': 'Test error context'
                }
                
                llm_analysis = {
                    'analysis': 'Test analysis result',
                    'model_used': 'granite-3-3-8b-instruct'
                }
                
                result = analyzer.create_github_issue(
                    workflow_run, job, error_segment, llm_analysis
                )
                
                if not result:
                    logger.error("GitHub issue creation returned False")
                    return False
                
                logger.info("✅ GitHub issue creation test passed")
                return True
                
    except Exception as e:
        logger.error(f"GitHub issue creation test failed: {e}")
        return False


def run_all_tests():
    """Run all test functions and report results."""
    logger.info("🧪 Starting Workflow Failure Analyzer Tests")
    logger.info("=" * 50)
    
    tests = [
        ("Environment Setup", test_environment_setup),
        ("Configuration Loading", test_configuration_loading), 
        ("Error Pattern Matching", test_error_pattern_matching),
        ("LLM Integration", test_llm_integration),
        ("GitHub Issue Creation", test_github_issue_creation)
    ]
    
    results = {}
    
    for test_name, test_func in tests:
        logger.info(f"\n🔍 Running: {test_name}")
        try:
            results[test_name] = test_func()
        except Exception as e:
            logger.error(f"Test {test_name} crashed: {e}")
            results[test_name] = False
    
    # Report results
    logger.info("\n" + "=" * 50)
    logger.info("📊 Test Results Summary")
    logger.info("=" * 50)
    
    passed = 0
    total = len(tests)
    
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        logger.info(f"{status} {test_name}")
        if result:
            passed += 1
    
    logger.info(f"\n📈 Overall: {passed}/{total} tests passed")
    
    if passed == total:
        logger.info("🎉 All tests passed! The analyzer is ready for deployment.")
        return True
    else:
        logger.error("⚠️ Some tests failed. Please review and fix issues before deployment.")
        return False


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
