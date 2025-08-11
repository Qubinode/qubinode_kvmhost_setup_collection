# Red Hat Registry Service Account Setup Guide

## Overview
This guide provides step-by-step instructions for setting up Red Hat Registry Service Account authentication to resolve CI/CD pipeline failures when accessing official Red Hat container images.

## Background
The Molecule testing pipeline was failing because GitHub Actions runners don't have access to Red Hat's registry.redhat.io by default. While local testing works perfectly with public image fallbacks, the CI environment requires proper authentication to pull official Red Hat images like `ubi9-init` and `ubi10-init`.

## Solution Implemented
✅ **Updated GitHub Actions Workflow** (`.github/workflows/ansible-test.yml`):
- Added environment variables for Red Hat registry credentials
- Implemented proper podman login with Service Account authentication
- Added comprehensive error handling and fallback logic
- Included registry cleanup step to prevent credential leakage

## Required GitHub Repository Setup

### 1. Create Red Hat Registry Service Account
If you don't already have a Red Hat Registry Service Account:

1. Go to [Red Hat Service Accounts](https://access.redhat.com/terms-based-registry/)
2. Create a new Service Account for your project
3. Note down the generated username and token

### 2. Add GitHub Repository Secrets
Navigate to your GitHub repository settings and add these secrets:

#### Required Secrets:
- **Secret Name**: `REDHAT_REGISTRY_USERNAME`
  - **Value**: Your Red Hat Registry Service Account username
  - **Example**: `12345678|myproject-serviceaccount`

- **Secret Name**: `REDHAT_REGISTRY_TOKEN`
  - **Value**: Your Red Hat Registry Service Account token
  - **Example**: `eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...`

#### How to Add Secrets:
1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the exact names shown above

## Verification Steps

### 1. Test the Authentication
Once secrets are added, you can test the authentication by:

1. **Manual Trigger**: Go to **Actions** → **CI/CD Pipeline Filter** → **Run workflow**
2. **Monitor Output**: Check the "Setup container registries and authentication" step
3. **Look for**: `✅ Red Hat registry authentication successful`

### 2. Expected Behavior
With proper authentication configured:
- ✅ CI will authenticate with Red Hat registry
- ✅ Official Red Hat images will be used for testing
- ✅ All RHEL-based containers will build and run successfully
- ✅ Complete molecule test suite will pass

### 3. Fallback Behavior
If authentication fails or secrets are not configured:
- ⚠️ CI will automatically fall back to public image alternatives
- ⚠️ Tests will still run but with different base images
- ⚠️ Warning messages will indicate missing authentication

## Current Status

### ✅ Completed
- [x] Local testing fully functional with all container types
- [x] Custom Dockerfile.rhel with proper package manager detection
- [x] Systemd container configuration with required volume mounts
- [x] GitHub Actions workflow enhanced with Red Hat registry authentication
- [x] Comprehensive error handling and fallback logic
- [x] Registry cleanup procedures to prevent credential leakage

### 📋 Pending (Manual Setup Required)
- [ ] Add `REDHAT_REGISTRY_USERNAME` secret to GitHub repository
- [ ] Add `REDHAT_REGISTRY_TOKEN` secret to GitHub repository
- [ ] Test CI pipeline with Red Hat registry authentication

## Authentication Code Implementation

The workflow now includes this authentication logic:

```bash
# Setup Red Hat Registry Service Account authentication
if [[ -n "$REDHAT_REGISTRY_USERNAME" && -n "$REDHAT_REGISTRY_TOKEN" ]]; then
  echo "🔐 Logging into Red Hat registry with Service Account..."
  if echo "$REDHAT_REGISTRY_TOKEN" | podman login registry.redhat.io --username "$REDHAT_REGISTRY_USERNAME" --password-stdin; then
    echo "✅ Red Hat registry authentication successful"
    RED_HAT_ACCESS=true
  else
    echo "❌ Red Hat registry authentication failed"
    RED_HAT_ACCESS=false
  fi
else
  echo "⚠️ Red Hat registry credentials not configured - using public alternatives"
  RED_HAT_ACCESS=false
fi
```

## Testing Commands

### Local Testing (Already Working)
```bash
# Test molecule locally
./scripts/test-local-molecule.sh

# Test specific scenario
cd molecule/default && molecule test
```

### CI Testing (After Secret Setup)
```bash
# Manual trigger via GitHub UI
# Or push changes to trigger automatic workflow
```

## Security Notes
- ✅ Credentials are stored as GitHub secrets (encrypted)
- ✅ Environment variables only available during workflow execution
- ✅ Automatic logout/cleanup after tests complete
- ✅ Fallback to public images if authentication fails

## Troubleshooting

### Common Issues:
1. **"credentials not configured"** → Add GitHub secrets
2. **"authentication failed"** → Check Service Account credentials
3. **"image pull failed"** → Verify Service Account has registry access

### Debug Steps:
1. Check GitHub Actions logs for authentication step output
2. Verify Secret names exactly match: `REDHAT_REGISTRY_USERNAME` and `REDHAT_REGISTRY_TOKEN`
3. Confirm Red Hat Service Account is active and has registry permissions

## Next Steps
1. **Immediate**: Add the two required GitHub secrets
2. **Test**: Run a manual workflow trigger to test authentication
3. **Verify**: Confirm all molecule tests pass with official Red Hat images
4. **Monitor**: Check future CI runs for successful authentication

Once the secrets are added, the CI pipeline will automatically use Red Hat registry authentication and should resolve all container access issues.
