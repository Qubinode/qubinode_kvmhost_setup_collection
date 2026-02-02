# Examples

Ready-to-use inventory and playbook files for the Qubinode KVM Host Setup Collection.

| File | Description |
|------|-------------|
| `inventory.yml` | Sample Ansible inventory targeting a single KVM host |
| `setup-kvmhost.yml` | Playbook that applies the `kvmhost_setup` role with common variable overrides |

## Quick start

```bash
# 1. Install the collection
ansible-galaxy collection install qubinode.qubinode_kvmhost_setup_collection

# 2. Edit the inventory to match your environment
vi examples/inventory.yml

# 3. Run the playbook
ansible-playbook -i examples/inventory.yml examples/setup-kvmhost.yml
```

## CI / headless setup

Run only the CI-friendly play (no Cockpit, no shell customisation):

```bash
ansible-playbook -i examples/inventory.yml examples/setup-kvmhost.yml --tags ci
```

See the [Quick Start Guide](../docs/diataxis/tutorials/00-quick-start.md) for more details.
