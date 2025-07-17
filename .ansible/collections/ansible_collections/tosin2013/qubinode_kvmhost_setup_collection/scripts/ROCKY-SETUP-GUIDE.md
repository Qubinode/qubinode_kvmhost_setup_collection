# GitHub Runner Setup for Rocky Linux / CentOS Stream

## Quick Setup Guide for Your Separate Rocky Linux Machine

### 📋 **Prerequisites**

Your Rocky Linux machine should have:
- ✅ Root access or sudo privileges
- ✅ Internet connectivity
- ✅ At least 4GB RAM and 20GB disk space
- ✅ SSH access for management

### 🚀 **Step 1: Transfer Setup Script**

On your development machine (this one), copy the script to your Rocky Linux server:

```bash
# Copy the setup script to your Rocky Linux machine
scp scripts/setup-github-runner-rocky.sh user@your-rocky-server:/tmp/

# Or if you have the repository on the Rocky machine:
# git clone https://github.com/Qubinode/qubinode_kvmhost_setup_collection.git
```

### 🔧 **Step 2: Run Setup on Rocky Linux Machine**

SSH into your Rocky Linux machine and run:

```bash
# SSH to your Rocky Linux server
ssh user@your-rocky-server

# Make script executable (if needed)
chmod +x /tmp/setup-github-runner-rocky.sh

# Run the setup as root
sudo /tmp/setup-github-runner-rocky.sh
```

### 🎯 **What the Script Will Do**

The script automatically detects and handles:
- ✅ **Rocky Linux 8, 9+**
- ✅ **CentOS Stream 8, 9, 10**
- ✅ **Future CentOS versions**

**Installation includes:**
- 🐍 Python 3.11 (or best available)
- 🧪 Ansible-core 2.17+ with Molecule
- 🐳 Podman container runtime
- 🔍 Security tools (bandit, safety)
- 🛡️ Systemd service configuration
- 📦 All dependencies for your CI/CD pipeline

### 🔐 **Step 3: Register Runner with GitHub**

After setup completes:

```bash
# Switch to the runner user
sudo su - github-runner

# Register with your repository
./register-runner.sh https://github.com/Qubinode/qubinode_kvmhost_setup_collection <YOUR_TOKEN>
```

### 🎫 **Getting Your GitHub Token**

1. Go to your repository: https://github.com/Qubinode/qubinode_kvmhost_setup_collection
2. Navigate to **Settings** → **Actions** → **Runners**
3. Click **"New self-hosted runner"**
4. Copy the token from the configuration command
5. Use that token in the registration command

### 🏷️ **Runner Labels**

Your runner will be automatically configured with these labels:
```
self-hosted,linux,x86_64,ansible,podman,rocky,qubinode
```

This allows your workflows to target it specifically:
```yaml
jobs:
  lint:
    runs-on: [self-hosted, rocky, qubinode]
```

### 🔄 **Managing Your Runner**

```bash
# Check runner status
sudo systemctl status github-runner

# View logs
journalctl -u github-runner -f

# Restart runner
sudo systemctl restart github-runner

# Verify environment
sudo su - github-runner
source ~/.runner-env
ansible --version
molecule --version
podman --version
```

### 🧪 **Testing Your Setup**

Once registered, test with a simple workflow:

```yaml
# Test workflow to verify runner
name: Test Rocky Runner
on: workflow_dispatch
jobs:
  test:
    runs-on: [self-hosted, rocky, qubinode]
    steps:
      - uses: actions/checkout@v4
      - name: Test environment
        run: |
          source ~/.runner-env
          echo "✅ OS: $(cat /etc/rocky-release || cat /etc/centos-release)"
          echo "✅ Python: $(python3.11 --version)"
          echo "✅ Ansible: $(ansible --version | head -1)"
          echo "✅ Podman: $(podman --version)"
          echo "🎉 Runner is working!"
```

### 🔮 **Future Migration to CentOS Stream**

When you migrate to CentOS Stream 9 or 10:

1. **Same script works!** - It auto-detects CentOS Stream
2. **Re-run setup** on the new machine
3. **Transfer runner registration** or register new
4. **Update workflow labels** if needed

### 🛠️ **Optimizations for Your Workflows**

The runner is pre-configured for your specific workflows:

- ✅ **No more timeout issues** - Everything pre-installed
- ✅ **Faster CI/CD** - No environment setup time
- ✅ **Consistent environment** - Same tools every run
- ✅ **Container-ready** - Podman configured for Molecule tests
- ✅ **Security-ready** - All scanning tools pre-installed

### 📊 **Performance Benefits**

**Before (GitHub-hosted):**
```
Setup Python 3.11:     ~2-3 minutes
Install Ansible tools:  ~3-4 minutes
Install containers:     ~2-3 minutes
Total setup time:       ~7-10 minutes per job
```

**After (Self-hosted):**
```
Activate environment:   ~5-10 seconds
Run actual tests:       ~2-5 minutes
Total time:            ~2-5 minutes per job
```

**🚀 Expected speedup: 3-5x faster workflows!**

### 🆘 **Troubleshooting**

If you encounter issues:

```bash
# Verify the setup
sudo /tmp/setup-github-runner-rocky.sh verify

# Check logs
sudo tail -f /var/log/github-runner-setup.log

# Test individual components
sudo su - github-runner
source ~/.runner-env
ansible --version
molecule --version
podman info
```

### 📞 **Need Help?**

1. **Check the setup log**: `/var/log/github-runner-setup.log`
2. **Verify OS detection**: The script should auto-detect Rocky Linux
3. **Test registration**: Make sure your GitHub token is valid
4. **Check connectivity**: Ensure the machine can reach github.com

The script is designed to be **idempotent** - you can run it multiple times safely if something goes wrong!

---

Ready to set up your Rocky Linux runner? Just copy the script and run it! 🚀
