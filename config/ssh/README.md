SSH config is managed using hardlinks between `~/.config/ssh` and `~/.ssh`.

## Hardlink Setup

- `~/.ssh/config` and `~/.ssh/.gitignore` are hardlinked to `~/.config/ssh/`
- This allows SSH to find the config in its expected location while keeping it version-controlled
- Private keys and public keys remain in `~/.ssh/` and are gitignored
- Machine-specific overrides can be added to `~/.ssh/config.local` (gitignored)

## File Organization

**Repo-managed files** (hardlinked):
- `config` - Main SSH configuration (hardlinked to `~/.ssh/config`)
- `.gitignore` - Prevents secrets from being committed (hardlinked to `~/.ssh/.gitignore`)

**Local files** (gitignored, stay in `~/.ssh/`):
- `id_*` - Private and public keys
- `*.pub` - Public keys
- `config.local` - Machine-specific overrides and settings
- `known_hosts` - Host verification data

**Secrets** (optional, user-only):
- `~/.config/secrets/ssh/config` - Sensitive host configurations
- `~/.config/secrets/ssh/config.d/*.conf` - Additional secret config files

## Configuration Hierarchy

The main config file includes configurations in this order:
1. Global defaults (in `~/.ssh/config`)
2. Config directory includes (`~/.ssh/config.d/*.conf`, `~/.config/ssh/config.d/*.conf`)
3. Local overrides (`~/.ssh/config.local`)
4. Secret configurations (`~/.config/secrets/ssh/config` and `~/.config/secrets/ssh/config.d/*.conf`)

## Security

- Keep permissions strict: `chmod 700 ~/.ssh` and `chmod 600 ~/.ssh/*`
- Private keys and sensitive data are automatically gitignored
- Use `~/.ssh/config.local` or `~/.config/secrets/ssh/` for machine-specific secrets
