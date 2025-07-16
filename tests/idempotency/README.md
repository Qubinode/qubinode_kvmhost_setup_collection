# Idempotency Testing Framework

This directory contains the idempotency testing framework for the Qubinode KVM Host Setup Collection, implementing ADR-0004 requirements.

## Overview

The idempotency testing framework ensures that all Ansible roles in the collection are truly idempotent - they can be run multiple times without changing the system state after the initial run.

## Architecture

### Components

1. **`idempotency_test.yml`** - Ansible playbook for testing role idempotency
2. **`run_tests.py`** - Python test runner with advanced analysis capabilities  
3. **`config.yml`** - Configuration file for test settings and role-specific parameters
4. **`templates/idempotency_report.j2`** - Jinja2 template for generating JSON reports

### Framework Features

- **Automated Testing**: Runs each role twice and compares results
- **Detailed Reporting**: Generates JSON and HTML reports with comprehensive metrics
- **Role-Specific Configuration**: Customizable settings per role
- **Quality Thresholds**: Configurable success criteria and quality gates
- **CI/CD Integration**: Designed for automated pipeline execution
- **Compliance Tracking**: Maps results to ADR-0004 architectural requirements

## Usage

### Quick Start

```bash
# Run all configured roles
./run_tests.py

# Test specific roles
./run_tests.py --roles kvmhost_setup edge_hosts_validate

# Enable verbose output
./run_tests.py --verbose

# Use custom configuration
./run_tests.py --config my_config.yml
```

### Ansible Playbook Usage

```bash
# Run the Ansible playbook directly
ansible-playbook tests/idempotency/idempotency_test.yml -i localhost,

# Test specific roles with tags
ansible-playbook tests/idempotency/idempotency_test.yml -i localhost, --tags kvmhost_setup
```

## Configuration

### Test Settings

```yaml
test_settings:
  max_allowed_changes: 0        # Maximum changes allowed on second run
  test_timeout: 3600           # Test timeout in seconds
  verbose_logging: true        # Enable detailed logging
  save_artifacts: true         # Save test results
  report_format: json          # Output format
```

### Role Configuration

```yaml
role_configurations:
  kvmhost_setup:
    skip_tasks: []             # Tasks to skip during testing
    test_vars:                 # Custom variables for testing
      testing_mode: true
    allowed_changes: []        # Acceptable changes (should be empty)
    dependencies:              # Required system dependencies
      - libvirt
      - qemu-kvm
```

### Quality Thresholds

```yaml
quality_thresholds:
  minimum_success_rate: 100    # Required success rate (%)
  max_execution_time: 1800     # Maximum test duration per role
  max_memory_usage: 2048       # Memory limit (MB)
```

## Test Results

### JSON Report Structure

```json
{
  "test_metadata": {
    "start_time": "2025-01-11T...",
    "end_time": "2025-01-11T...",
    "total_duration_seconds": 120.5,
    "test_framework": "qubinode-idempotency-framework"
  },
  "summary": {
    "total_roles": 3,
    "passed": 3,
    "failed": 0,
    "success_rate": 100.0,
    "overall_success": true
  },
  "compliance": {
    "adr_0004_compliant": true,
    "meets_quality_threshold": true
  },
  "results": [...]
}
```

### HTML Reports

When enabled, HTML reports provide:
- Visual test result dashboard
- Role-by-role breakdown
- Error details and logs
- Compliance status indicators

## Integration

### Molecule Integration

The framework integrates with Molecule testing:

```yaml
# In molecule.yml
dependency:
  name: galaxy
provisioner:
  name: ansible
  playbooks:
    verify: ../../tests/idempotency/idempotency_test.yml
```

### CI/CD Pipeline Integration

```yaml
# GitHub Actions example
- name: Run Idempotency Tests
  run: |
    cd qubinode_kvmhost_setup_collection
    ./tests/idempotency/run_tests.py --verbose
  continue-on-error: false
```

## Troubleshooting

### Common Issues

1. **Role fails on first run**: Check role dependencies and prerequisites
2. **Tasks change on second run**: Review task implementation for idempotency
3. **Test timeouts**: Increase `test_timeout` in configuration
4. **Permission errors**: Ensure proper file permissions and user context

### Debug Mode

Enable debug mode for detailed analysis:

```yaml
debugging:
  debug_failures: true
  collect_logs: true
  create_snapshots: false
```

### Log Analysis

Test logs are saved in `/tmp/idempotency_tests/` and include:
- Ansible playbook output
- System state snapshots
- Error details and stack traces
- Performance metrics

## Best Practices

### Writing Idempotent Tasks

1. **Use appropriate modules**: Prefer idempotent modules like `file`, `package`, etc.
2. **Check state before changes**: Use conditionals to avoid unnecessary changes
3. **Handle edge cases**: Account for partial failures and retries
4. **Test thoroughly**: Run tasks multiple times during development

### Test Configuration

1. **Isolate test environment**: Use containers or clean systems
2. **Mock external dependencies**: Avoid network calls in tests
3. **Set realistic timeouts**: Balance thoroughness with execution speed
4. **Document exceptions**: Clearly document any allowed changes

## Compliance Metrics

The framework tracks compliance with:

- **ADR-0004**: Idempotent Task Design Pattern
- **Architectural Rules**: Automated rule validation
- **Quality Gates**: Success rate thresholds
- **Performance Benchmarks**: Execution time limits

## Advanced Usage

### Custom Verifiers

Create role-specific verification logic:

```python
def verify_kvmhost_setup(result):
    """Custom verification for kvmhost_setup role"""
    # Check KVM configuration state
    # Validate libvirt settings
    # Verify network configuration
    return verification_passed
```

### Reporting Extensions

Extend reporting capabilities:

```python
def generate_custom_report(results):
    """Generate organization-specific report format"""
    # Custom metrics
    # Integration with monitoring systems
    # Compliance documentation
```

## Files and Structure

```
tests/idempotency/
├── README.md                    # This documentation
├── config.yml                  # Test configuration
├── idempotency_test.yml        # Main test playbook
├── run_tests.py                # Python test runner
├── templates/
│   └── idempotency_report.j2   # Report template
└── results/                    # Generated test results
    ├── idempotency_test_*.json # JSON reports
    └── idempotency_test_*.html # HTML reports (if enabled)
```

## Contributing

When adding new roles or modifying existing ones:

1. Add role configuration to `config.yml`
2. Update test dependencies if needed
3. Run idempotency tests to verify compliance
4. Document any special requirements or exceptions

## Related Documentation

- [ADR-0004: Idempotent Task Design Pattern](../../docs/adrs/adr-0004-idempotent-task-design-pattern.md)
- [Architectural Rules](../../rules/README.md)
- [Molecule Testing Documentation](../../molecule/README.md)
- [Development Guidelines](../../development.md)
