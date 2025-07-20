# Aider-Lint-Fixer Integration

This document describes the integration of `aider-lint-fixer` into the automated Ansible lint fixes workflow.

## Overview

The `aider-lint-fixer` is an AI-powered tool that automatically fixes linting issues in code files. It has been integrated into the GitHub Actions workflow to provide intelligent, context-aware fixes for Ansible lint violations.

## Workflow Integration

### Fix Mode: `aider-assisted`

The workflow now supports `aider-assisted` as the primary fix mode, which:

1. **Analyzes lint issues** using `ansible-lint` to identify problems
2. **Applies AI-powered fixes** using `aider-lint-fixer` with these options:
   - `--linter ansible-lint`: Specifies the linter to use
   - `--fix-mode aggressive`: Applies comprehensive fixes
   - `--preserve-formatting`: Maintains code formatting
   - `--backup-original`: Creates backups before changes
   - `--max-iterations 3`: Limits fix attempts to prevent infinite loops
   - `--output-report`: Generates a detailed report of changes

3. **Fallback to manual fixes** if aider-lint-fixer fails or is unavailable
4. **Final validation** with `ansible-lint --profile production`

### Supported Fix Modes

1. **`aider-assisted`** (default): Uses AI-powered fixes with fallback
2. **`auto`**: Traditional automatic fixes using ansible-lint --fix
3. **`manual-review`**: Generates reports for manual review
4. **`gemini-assisted`**: Uses Google Gemini for analysis (requires API key)

## Benefits

- **Intelligent fixes**: Context-aware solutions that understand code intent
- **Comprehensive coverage**: Handles complex lint issues that simple regex can't fix
- **Preserves formatting**: Maintains code style and readability
- **Safe operation**: Creates backups and provides detailed reporting
- **Fallback support**: Degrades gracefully to manual fixes if needed

## Usage

### Via GitHub Actions

1. Navigate to the Actions tab in your repository
2. Select "Automated Ansible Lint Fixes with Aider"
3. Click "Run workflow"
4. Select `aider-assisted` as the fix mode
5. Optionally specify target files (defaults to `roles/`, `validation/`, `.github/workflows/`)

### Local Development

Install the required dependencies:

```bash
pip install -r requirements-dev.txt
```

Run aider-lint-fixer manually:

```bash
aider-lint-fixer \
  --linter ansible-lint \
  --target-files "roles/" \
  --fix-mode aggressive \
  --preserve-formatting \
  --backup-original \
  --max-iterations 3 \
  --output-report aider-fix-report.json \
  --verbose
```

## Configuration

### Requirements

The tool is included in `requirements-dev.txt`:

```
aider-lint-fixer
```

### Workflow Configuration

The workflow automatically:
- Installs `aider-lint-fixer` from `requirements-dev.txt`
- Configures proper Python environment
- Handles target file selection
- Manages backup and reporting

## Troubleshooting

### Common Issues

1. **Tool not found**: Ensure `requirements-dev.txt` is used for pip installation
2. **Fix failures**: Check the aider-fix-report.json for detailed error information
3. **Fallback activation**: The workflow will automatically use manual fixes if aider fails

### Debugging

- Check the workflow run logs for detailed output
- Review the uploaded `aider-fix-report.json` artifact
- Examine the backup files created before changes

## Integration with Existing Tools

The aider-lint-fixer integration complements existing tools:

- **ansible-lint**: Primary linter for issue detection
- **yamllint**: YAML formatting validation
- **GitHub Actions**: Automated workflow execution
- **Manual fixes**: Fallback for complex issues

## Future Enhancements

- Integration with more linters (pylint, flake8, etc.)
- Custom rule configuration
- Advanced reporting and metrics
- Integration with code review tools
