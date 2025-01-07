## CI/CD and Local Testing Configuration

### Decision: Containerization Strategy

**Architect (A):**
- We will standardize on Podman across both CI/CD and local development
- Podman provides better integration with RHEL systems and is fully compatible with CI platforms
- The container image (docker.io/rockylinux/rockylinux:9-ubi-init) will be used consistently

**Developer 1 (D1):**
- The molecule.yml configuration has been updated to use Podman exclusively
- Podman provides better security and rootless operation
- Removed Docker-specific dependencies from requirements.yml

**Developer 2 (D2):**
- Agree with standardizing on Podman
- GitHub Actions workflows have been updated to install and use Podman
- The Dockerfile in molecule/default/ will continue to work with Podman

### Implementation Details

1. CI/CD pipelines and local development will use Podman as the container runtime
2. GitHub Actions workflows install Podman and configure it for testing
3. The same container image will be used in both environments
4. Removed Docker-specific dependencies and configurations

### Recent Updates

**CI/CD Pipeline Changes:**
- Updated ansible-test.yml workflow to:
  - Add molecule-podman to lint job dependencies
  - Ensure consistent Podman usage across all jobs
  - Remove remaining Docker-specific configurations

**Documentation Updates:**
- Updated testing.md to:
  - Replace all Docker references with Podman
  - Update installation instructions to use molecule-podman
  - Modify container-based testing commands to use podman
  - Update troubleshooting section for Podman-specific issues

**Testing Improvements:**
- Added Podman installation step to lint job
- Standardized container runtime across all test environments
- Updated test documentation to reflect current practices
- Successfully executed molecule tests using Podman driver
- Verified all test scenarios work with Podman runtime

## CI/CD Fixes (2024-01-15)

### Issues Identified
1. Podman configuration was incomplete in CI environment
2. Ansible version mismatch between test container and CI
3. Duplicate pre_build_image setting in molecule.yml

### Changes Made
1. Updated Dockerfile to:
   - Install podman and slirp4netns packages
   - Use compatible Ansible version range (>=2.13,<2.16)
2. Fixed molecule.yml by:
   - Removing duplicate pre_build_image setting
   - Cleaning up podman configuration
3. Updated CI workflow to:
   - Properly configure podman with registries.conf and containers.conf
   - Remove redundant driver specifications
   - Add necessary podman dependencies

### Testing Results
- CI pipeline now runs successfully through syntax check phase
- Molecule tests complete without podman-related errors
- Consistent Ansible versions between test container and CI
