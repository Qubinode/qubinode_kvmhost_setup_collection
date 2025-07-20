# GitHub Actions Shell Command Fix

## Issue Resolved

Fixed the GitHub Actions error:
```
/home/github-runner/actions-runner/_work/_temp/xxx.sh: line 3: 2.19.0: No such file or directory
Error: Process completed with exit code 1.
```

## Root Cause

In the `ansible-test.yml` workflow, the pip install command had an unquoted version constraint:
```bash
pip install ansible-lint>=6.0.0 bandit>=1.7.0 ansible-core>=2.18.0,<2.19.0
```

The shell was interpreting `<2.19.0` as a redirect operator, trying to redirect input from a file named `2.19.0`, which doesn't exist.

## Solution

Added proper quoting around the version constraint:
```bash
pip install ansible-lint>=6.0.0 bandit>=1.7.0 "ansible-core>=2.18.0,<2.19.0"
```

## Changes Made

1. **Fixed pip install command** in `.github/workflows/ansible-test.yml` line 41
2. **Updated dependency check** to use consistent version constraint (line 166)
3. **Verified syntax** of all workflow files

## Prevention

When using version constraints with `<` or `>` operators in shell commands, always quote the entire package specification:

✅ **Correct**: `"package>=1.0,<2.0"`
❌ **Incorrect**: `package>=1.0,<2.0`

The GitHub Actions workflow should now execute the pip install commands correctly.
