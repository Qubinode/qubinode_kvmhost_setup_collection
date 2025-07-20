# EPEL Repository Fix for GitHub Actions Runner

## Problem

The GitHub Actions Rocky Linux runner has corrupted EPEL repository metadata causing GPG verification failures:

```
Error: Failed to download metadata for repo 'epel': GPG verification is enabled, but GPG signature is not available. This may be an error or the repository does not support GPG verification: Status code: 404 for [mirror-url]/repodata/repomd.xml.asc
```

## Solution

Run the EPEL cleanup script on the GitHub Actions runner machine to fix the repository configuration.

## Usage

### On the GitHub Actions Runner Machine

1. **SSH into the GitHub Actions runner machine**
2. **Run the cleanup script as root:**
   ```bash
   sudo ./scripts/fix-epel-on-runner.sh
   ```

### What the Script Does

1. **🧹 Cleans up corrupted EPEL cache and metadata**
   - Removes `/var/cache/dnf/epel*` and `/var/cache/yum/epel*`
   - Clears package manager caches
   - Removes corrupted metadata files

2. **🔄 Reinstalls EPEL repository cleanly**
   - Removes existing `epel-release` packages
   - Deletes old repository configuration files
   - Installs fresh EPEL repository

3. **🔑 Imports GPG keys properly**
   - Imports EPEL GPG keys from `/etc/pki/rpm-gpg/`
   - Ensures proper key verification

4. **✅ Verifies EPEL is working**
   - Tests repository accessibility
   - Confirms packages can be queried

## Expected Output

```
🔧 EPEL Repository Cleanup Script for GitHub Actions Runner
==========================================================
Detected OS: Rocky Linux (rocky)
ℹ️  This script will:
ℹ️  1. Clean up corrupted EPEL cache and metadata
ℹ️  2. Remove and reinstall EPEL repository
ℹ️  3. Import GPG keys properly
ℹ️  4. Verify EPEL is working

Continue with EPEL cleanup? (y/N): y
ℹ️  Starting comprehensive EPEL cleanup...
ℹ️  Cleaning all package manager caches...
ℹ️  Removing EPEL cache directories...
ℹ️  Removing EPEL metadata...
ℹ️  Backing up current EPEL configuration...
✅ EPEL cleanup completed
ℹ️  Reinstalling EPEL repository...
ℹ️  Removing existing EPEL packages...
ℹ️  Removing EPEL repository files...
ℹ️  Installing EPEL repository fresh...
ℹ️  Importing EPEL GPG keys...
ℹ️  Refreshing package metadata...
✅ EPEL repository reinstalled successfully
ℹ️  Verifying EPEL repository...
✅ EPEL repository is enabled and accessible
ℹ️  Testing EPEL package installation...
✅ EPEL packages are accessible
✅ EPEL repository cleanup completed successfully!
ℹ️  You can now run GitHub Actions workflows without EPEL GPG issues
```

## After Running the Script

Once the script completes successfully:

1. **✅ EPEL repository will be properly configured**
2. **✅ GPG verification will work correctly**
3. **✅ GitHub Actions workflows will run without EPEL errors**
4. **✅ EPEL packages will be available for installation**

## Verification

Test that EPEL is working:
```bash
# Check EPEL repository is enabled
sudo dnf repolist enabled | grep epel

# Test installing an EPEL package
sudo dnf info htop
```

## Troubleshooting

If the script fails:

1. **Check internet connectivity** - EPEL needs to download packages
2. **Verify Rocky Linux version** - Script is designed for Rocky Linux 9
3. **Check disk space** - Ensure sufficient space for package operations
4. **Run with verbose output** - Add `-x` to the script shebang for debugging

## Alternative Manual Steps

If the script doesn't work, you can run these commands manually:

```bash
# Clean everything
sudo dnf clean all
sudo rm -rf /var/cache/dnf/epel*
sudo rm -rf /var/lib/dnf/repos/epel*

# Remove and reinstall EPEL
sudo dnf remove -y epel-release
sudo rm -f /etc/yum.repos.d/epel*.repo
sudo dnf install -y epel-release

# Import keys and refresh
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-9
sudo dnf makecache
```
