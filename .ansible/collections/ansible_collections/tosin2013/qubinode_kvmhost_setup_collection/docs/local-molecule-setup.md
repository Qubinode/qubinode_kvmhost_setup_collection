# Local Molecule Testing Setup Guide

This guide helps you set up your local environment for Molecule testing based on **ADR-0011: Local Molecule Testing Validation Before CI/CD** and research findings.

## Quick Setup Commands

### 1. Install Python 3.11 (Recommended for RHEL 9)
```bash
# On RHEL 9/Rocky Linux 9
sudo dnf install python3.11 python3.11-pip

# Verify installation
python3.11 --version
```

### 2. Install Molecule and Dependencies
```bash
# Create virtual environment with Python 3.11
python3.11 -m venv ~/.venv/molecule
source ~/.venv/molecule/bin/activate

# Install Molecule with plugins
pip install --upgrade pip
pip install 'molecule>=25.6.0' 'molecule-plugins[docker]' 'ansible-core>=2.17'

# Verify installation
molecule --version
ansible --version
```

### 3. Install Container Runtime (Podman Preferred)
```bash
# Install Podman (recommended for RHEL 9)
sudo dnf install podman

# Or Docker if needed
sudo dnf install docker-ce
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

### 4. Run Local Tests
```bash
# Make script executable
chmod +x scripts/test-local-molecule.sh

# Run local validation
./scripts/test-local-molecule.sh
```

## Environment Validation Checklist

- [ ] Python 3.11+ installed and available
- [ ] Molecule v25.6.0+ installed  
- [ ] Ansible-core 2.17+ installed
- [ ] Podman or Docker installed and running
- [ ] Local testing script passes validation
- [ ] Molecule scenarios run successfully

## Performance Benefits

Based on research findings:
- **Python 3.11**: 10-60% performance improvement over Python 3.9
- **Ansible-core 2.17+**: Enhanced execution engine and RHEL 9 optimization
- **Podman**: Better RHEL 9 integration and security

## Pre-commit Hook Setup

Enable automatic testing before commits:

```bash
# Copy example hook
cp .git/hooks/pre-commit.example .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Troubleshooting

### Common Issues

1. **Molecule not found**: Install in virtual environment
2. **Permission denied**: Check container runtime permissions
3. **Python version issues**: Use `python3.11` explicitly
4. **Missing dependencies**: Install molecule-plugins[docker]

### Environment Variables

```bash
# Add to ~/.bashrc for persistent setup
export PATH="$HOME/.venv/molecule/bin:$PATH"
alias python3-molecule="python3.11"
```

## Next Steps

1. **Test all roles**: Run `molecule test` for each role
2. **Enable pre-commit**: Set up automatic validation
3. **Read ADR-0011**: Understand the full testing strategy
4. **Join the workflow**: Follow local-first development practices

## Research References

- [Local Molecule Testing Research](docs/research/local-molecule-testing-validation-2025-01-12.md)
- [ADR-0011: Local Testing Strategy](docs/adrs/adr-0011-local-molecule-testing-validation-before-cicd.md)
- [RHEL 9 Python 3.11 Compatibility](docs/research/rhel9-python311-ansible-compatibility-2025.md)
