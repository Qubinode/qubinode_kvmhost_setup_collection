# Workflow Failure Analyzer

## Overview

The Workflow Failure Analyzer is an intelligent GitHub Actions automation system that monitors workflow executions and automatically creates detailed GitHub Issues for failures. It leverages the Red Hat MaaS granite-3-3-8b-instruct model for sophisticated root cause analysis and provides actionable resolution steps.

## Architecture

### Components

1. **Main Analyzer Script** (`scripts/workflow-failure-analyzer.py`)
   - Monitors GitHub workflow runs via GitHub API
   - Extracts and analyzes error logs using configurable patterns
   - Integrates with Red Hat MaaS for LLM-powered analysis
   - Creates structured GitHub Issues with detailed failure analysis

2. **GitHub Actions Workflow** (`.github/workflows/workflow-failure-analyzer.yml`)
   - Triggers automatically when monitored workflows complete with failures
   - Provides secure environment variable management
   - Generates analysis reports and artifacts

3. **Configuration System** (`scripts/workflow-analyzer-config.json`)
   - Centralized configuration for error patterns, API settings, and analysis parameters
   - Supports customization without code changes

4. **Testing Framework** (`scripts/test-workflow-analyzer.py`)
   - Comprehensive unit tests for all analyzer components
   - Mock-based testing for external API integrations

## Features

### Intelligent Error Detection
- **Multi-Pattern Recognition**: Detects various error types (Ansible, Python, build failures, dependency issues)
- **Context Extraction**: Captures relevant log context around errors
- **Duplicate Prevention**: Avoids creating multiple issues for the same error

### LLM-Powered Analysis
- **Root Cause Analysis**: Uses granite-3-3-8b-instruct model for technical analysis
- **Structured Output**: Provides ROOT CAUSE, IMPACT, SOLUTION, and PREVENTION sections
- **Confidence Scoring**: Implements methodological pragmatism with explicit uncertainty handling

### GitHub Integration
- **Automatic Issue Creation**: Creates detailed issues with proper labeling and formatting
- **Workflow Linking**: Links issues back to failed workflow runs
- **Artifact Management**: Stores analysis reports for audit trails

## Setup Instructions

### Prerequisites
- Python 3.11+
- GitHub repository with Actions enabled
- Red Hat MaaS API access
- Required environment variables configured

### Installation

1. **Validate Setup**
   ```bash
   ./scripts/validate-analyzer-setup.sh
   ```

2. **Configure Environment Variables**
   Ensure these are set in your GitHub repository secrets or `.env` file:
   ```bash
   GITHUB_TOKEN=your_github_token
   GITHUB_REPOSITORY=your_org/your_repo
   RED_HAT_MAAS_API_KEY=your_maas_api_key
   ```

3. **Test the System**
   ```bash
   python3 scripts/test-workflow-analyzer.py
   ```

### Configuration

The analyzer uses `scripts/workflow-analyzer-config.json` for configuration:

```json
{
  "analyzer_config": {
    "max_workflows_per_run": 20,
    "max_errors_per_job": 10
  },
  "red_hat_maas": {
    "model": "granite-3-3-8b-instruct",
    "max_tokens": 800,
    "temperature": 0.1
  },
  "error_patterns": {
    "critical": ["FATAL:", "CRITICAL:", "Exception:"],
    "ansible_specific": ["ansible-lint.*\\[E\\d+\\]", "FAILED! =>"]
  }
}
```

## Usage

### Automatic Operation
The analyzer automatically triggers when any monitored workflow fails:
- Monitors workflows listed in `.github/workflows/workflow-failure-analyzer.yml`
- Analyzes failure logs and creates GitHub Issues
- Provides detailed analysis reports

### Manual Triggering
```bash
# Trigger via GitHub CLI
gh workflow run workflow-failure-analyzer.yml

# Trigger with parameters
gh workflow run workflow-failure-analyzer.yml \
  -f analyze_all_recent=true \
  -f max_workflows=5
```

### Monitoring
- **GitHub Issues**: Check issues with `workflow-failure` label
- **Action Runs**: Monitor the analyzer workflow in GitHub Actions
- **Artifacts**: Download analysis reports from workflow runs

## Methodological Pragmatism Framework

This system implements methodological pragmatism principles:

### Explicit Fallibilism
- Confidence scores for all major operations
- Clear acknowledgment of limitations in error pattern recognition
- Fallback mechanisms for LLM analysis failures

### Systematic Verification
- Comprehensive unit testing with mock integrations
- Configuration validation and environment checks
- Structured error handling with detailed logging

### Pragmatic Success Criteria
- Focuses on actionable issue creation over perfect analysis
- Prioritizes developer productivity and workflow reliability
- Balances automation with human oversight requirements

### Cognitive Systematization
- Organized error patterns by category and severity
- Structured LLM prompts for consistent analysis quality
- Clear separation between data collection and analysis phases

## Error Handling

### Human-Cognitive Errors
- **Knowledge Gaps**: Provides fallback analysis when LLM fails
- **Attention Limitations**: Structures issues for easy scanning
- **Cognitive Biases**: Uses systematic error pattern matching

### Artificial-Stochastic Errors
- **Pattern Completion**: Validates LLM responses for completeness
- **Context Limitations**: Chunks large logs appropriately
- **Training Artifacts**: Uses recent, domain-specific model (granite-3-3-8b-instruct)

## Troubleshooting

### Common Issues

1. **Missing Environment Variables**
   ```bash
   # Check environment
   ./scripts/validate-analyzer-setup.sh
   ```

2. **API Connectivity Issues**
   ```bash
   # Test GitHub API
   curl -H "Authorization: Bearer $GITHUB_TOKEN" \
        https://api.github.com/repos/$GITHUB_REPOSITORY
   ```

3. **Configuration Errors**
   ```bash
   # Validate configuration
   python3 -c "import json; json.load(open('scripts/workflow-analyzer-config.json'))"
   ```

### Debugging
- Enable debug logging: Set `LOG_LEVEL=DEBUG` in environment
- Check workflow logs in GitHub Actions
- Review generated artifacts for detailed analysis reports

## Security Considerations

- **API Keys**: Stored securely in GitHub Secrets
- **Token Permissions**: Minimal required permissions (issues:write, actions:read)
- **SSL Verification**: Disabled only for internal Red Hat MaaS API
- **Log Sanitization**: Sensitive data filtered from issue creation

## Contributing

1. Follow the existing code structure and documentation standards
2. Add unit tests for new functionality
3. Update configuration schema for new error patterns
4. Maintain confidence scoring for new analysis methods

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review GitHub Actions logs for the analyzer workflow
3. Examine created issues for analysis quality
4. Run the validation script to check system health
