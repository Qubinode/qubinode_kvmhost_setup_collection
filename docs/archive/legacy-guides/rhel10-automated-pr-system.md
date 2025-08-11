# RHEL 10 Automated Pull Request System

## 🎯 Overview

This document describes the automated system that monitors RHEL 10 virtualization package availability and creates pull requests when packages become available.

## 🚀 How It Works

### Automated Monitoring
- **Schedule**: Runs every Monday at 6 AM UTC
- **Trigger**: Can be manually triggered via GitHub Actions
- **Detection**: Checks for virtualization packages in RHEL 10 UBI containers
- **Threshold**: Creates PR when 3+ core packages are available

### Package Monitoring List
The system monitors these critical virtualization packages:
- `libvirt` - Core virtualization library
- `qemu-kvm` - KVM hypervisor
- `virt-manager` - Virtual machine manager
- `libvirt-daemon-kvm` - KVM daemon
- `virt-install` - VM installation tool
- `libguestfs-tools` - Guest filesystem tools
- `cockpit` - Web-based management
- `NetworkManager` - Network management

## 📋 Automated Actions

### When Packages Become Available
1. **Branch Creation**: Creates `feature/rhel10-virtualization-packages` branch
2. **Code Updates**: 
   - Updates package lists in `roles/kvmhost_setup/tasks/rhel_version_detection.yml`
   - Modifies package selection logic
   - Updates documentation
3. **PR Creation**: Creates comprehensive pull request with:
   - Detailed change summary
   - Testing checklist
   - Documentation updates needed
   - Impact analysis

### PR Content Includes
- ✅ **Package Status Report**: Which packages are now available
- ✅ **Automated Changes**: Code modifications made
- ✅ **Testing Checklist**: Required validation steps
- ✅ **Documentation Tasks**: Updates needed
- ✅ **Labels**: Appropriate GitHub labels for categorization

## 🛠️ Manual Usage

### Check Current Status
```bash
# Run local package check
./scripts/check-rhel10-packages.sh

# Manual trigger with GitHub CLI
./scripts/trigger-rhel10-check.sh
```

### Trigger Workflow Manually
```bash
# Using GitHub CLI
gh workflow run rhel10-auto-pr.yml --field force_check=true

# Or via GitHub web interface:
# Actions → RHEL 10 Virtualization Package Auto-PR → Run workflow
```

## 📊 Monitoring Dashboard

### Status Tracking
The system creates and maintains:
- **Status Issues**: Track monitoring progress
- **JSON Reports**: Detailed package availability data
- **Weekly Updates**: Automated status reports

### Output Files
- `rhel10-package-status.json` - Detailed package status
- `RHEL10_UPDATE_SUMMARY.md` - Human-readable summary
- `package-status.md` - Markdown status report

## 🎯 Thresholds and Logic

### PR Creation Criteria
- **Minimum Packages**: 3+ core packages available
- **No Existing PR**: Prevents duplicate PRs
- **Package Priority**: Core virtualization packages weighted higher

### Status Levels
- **🔴 Not Ready**: < 3 packages available
- **🟡 Partial Support**: 3-5 packages available (creates PR)
- **🟢 Full Support**: 6+ packages available (production ready)

## 🔧 Configuration

### Environment Variables
```yaml
RHEL10_IMAGE: "registry.redhat.io/ubi10-init:latest"
BRANCH_NAME: "feature/rhel10-virtualization-packages"
```

### Workflow Permissions
The workflow requires:
- `contents: write` - For branch creation and commits
- `pull-requests: write` - For PR creation
- `issues: write` - For status issue creation

## 📚 Integration Points

### With Existing Workflow
- **Molecule Testing**: PR includes updated test configurations
- **Documentation**: Automatic README and ADR updates
- **CI/CD Pipeline**: Ready for integration testing

### With Project Structure
- **Package Lists**: Updates `rhel_version_detection.yml`
- **Selection Logic**: Modifies package selection algorithms
- **Documentation**: Updates project documentation

## 🎉 Benefits

### Automation Advantages
- **⚡ Fast Response**: Immediate detection and PR creation
- **🔄 Consistency**: Standardized update process
- **📊 Tracking**: Complete audit trail of changes
- **🚀 Efficiency**: Reduces manual monitoring overhead

### Quality Assurance
- **✅ Comprehensive Testing**: Built-in testing checklist
- **📝 Documentation**: Automatic documentation updates
- **🏷️ Labeling**: Proper categorization and prioritization
- **👥 Review Process**: Maintains code review standards

## 🔍 Troubleshooting

### Common Issues
1. **Container Access**: Ensure podman/docker is available
2. **Permissions**: Verify GitHub token permissions
3. **Branch Conflicts**: Check for existing feature branches
4. **Package Detection**: Validate container image accessibility

### Debug Commands
```bash
# Test package detection locally
podman run --rm registry.redhat.io/ubi10-init:latest dnf list available libvirt

# Check workflow status
gh run list --workflow=rhel10-auto-pr.yml

# View workflow logs
gh run view --log
```

## 📈 Future Enhancements

### Planned Improvements
- **Slack/Teams Integration**: Real-time notifications
- **Package Version Tracking**: Monitor version changes
- **Performance Metrics**: Track package availability trends
- **Multi-Architecture**: Support for ARM64 and other architectures

### Extensibility
The system is designed to be easily extended for:
- Other RHEL versions
- Different package sets
- Additional notification channels
- Custom validation rules

---

*This automated system ensures the project stays current with RHEL 10 developments while maintaining high code quality standards.*
