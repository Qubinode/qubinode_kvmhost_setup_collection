# ADR-0004: Idempotent Task Design Pattern

## Status
Implemented

> **Review Note (2026-01-25)**: ADR compliance review confirmed full implementation with
> 9/10 compliance score. Idempotency testing framework exists with comprehensive
> Molecule tests verifying task idempotency across all roles.

## Context
The Qubinode automation needs to be reliable and safe to run multiple times without causing unintended side effects. Infrastructure automation often needs to be re-executed for updates, troubleshooting, or recovery scenarios. Without proper idempotency, repeated executions could:

- Create duplicate resources or configurations
- Cause conflicts or inconsistent system states  
- Fail when resources already exist
- Lead to unreliable deployment processes

Ansible provides idempotency features, but they must be used correctly to ensure reliable automation.

## Decision
Implement idempotent task design as a core principle for all Ansible tasks in the project. All tasks should be designed to achieve the desired state regardless of the current system state, and should be safe to run multiple times without unintended consequences.

Key principles:
1. Use Ansible modules that are inherently idempotent when possible
2. Include appropriate conditions and checks for non-idempotent operations
3. Use `state` parameters correctly (present, absent, etc.)
4. Implement proper `creates`, `removes`, and conditional checks
5. Test all tasks for idempotency during development

## Alternatives Considered
1. **Non-idempotent task execution** - Tasks that only work on first run
   - Pros: Simpler initial implementation
   - Cons: Unreliable, difficult to maintain, prone to failures

2. **Manual state checking** - Custom logic for each task to check current state
   - Pros: Full control over behavior
   - Cons: Error-prone, increases complexity, reimplements Ansible features

3. **Separate update vs. create playbooks** - Different automation for different scenarios
   - Pros: Clear separation of concerns
   - Cons: Duplicated logic, more complex maintenance

## Consequences

### Positive
- **Reliability**: Tasks can be safely re-run without causing errors or conflicts
- **Predictable outcomes**: Same task execution always results in the same end state
- **Easier troubleshooting**: Failed deployments can be retried without cleanup
- **Simplified operations**: No need for complex state management or cleanup procedures
- **Reduced risk**: Lower chance of configuration drift or inconsistent states
- **Better testing**: Tasks can be tested multiple times in the same environment
- **Operational confidence**: Teams can confidently re-run automation

### Negative
- **Development overhead**: Requires careful consideration of task design
- **Complexity**: Some operations require additional logic to achieve idempotency
- **Performance impact**: May require additional state checks that slow execution
- **Learning curve**: Team members need to understand idempotency principles

## Implementation
- Use Ansible's built-in idempotent modules (package, service, file, etc.)
- Implement proper conditional checks using `when` statements
- Use `creates` and `removes` parameters for command and shell modules
- Include state validation in custom tasks
- Document idempotency expectations in role README files
- Test idempotency as part of CI/CD pipeline using Molecule

## Examples
```yaml
# Idempotent package installation
- name: Install required packages
  package:
    name: "{{ required_packages }}"
    state: present

# Idempotent service management  
- name: Ensure libvirtd is running
  service:
    name: libvirtd
    state: started
    enabled: yes

# Idempotent command execution
- name: Create storage pool
  command: virsh pool-define {{ pool_xml_path }}
  args:
    creates: /etc/libvirt/storage/{{ pool_name }}.xml
```

## Evidence
- Consistent use of `state` parameters throughout role tasks
- Proper use of conditional statements and creation checks
- Molecule testing verifies idempotency of role execution
- Tasks can be safely re-executed without errors

## Date
2024-07-11

## Tags
ansible, idempotency, reliability, automation, best-practices, operations
