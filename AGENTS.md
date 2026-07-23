# AGENTS.md

NixOS system configuration for RhenCloud, managed as a Nix flake using **Snowfall Lib**.

## Repo Layout

```
flake.nix                      # Entry point: inputs, Snowfall config, devShells override
systems/x86_64-linux/nixos-desktop/   # Single host entry (default.nix + hardware-configuration.nix)
homes/x86_64-linux/rhencloud@nixos-desktop/  # Home Manager entry for rhencloud
modules/nixos/{core,desktop,service}/  # System-level modules (auto-loaded by Snowfall)
modules/home/{core,desktop,dev,service}/  # Home Manager modules (auto-loaded)
lib/                           # Snowfall Lib helpers (rhencloud.lib.*)
secrets/                       # transcrypt-encrypted secrets
overlays/                      # Custom package overlays
shells/                        # Extra devShells (python.nix)
```

Snowfall Lib auto-discovers modules by directory convention — no manual `imports` needed in `flake.nix` for modules under `modules/`. Adding a new directory with a `default.nix` is enough.

## Key Commands

```bash
# Build and switch (apply) the system config
sudo nixos-rebuild switch --flake .#nixos-desktop

# Build only (creates ./result symlink)
nixos-rebuild build --flake .#nixos-desktop

# Test without creating a bootloader entry
sudo nixos-rebuild test --flake .#nixos-desktop

# Diff package changes between current and new build
nix diff-closures /run/current-system result

# Roll back to previous generation
sudo nixos-rebuild switch --rollback

# Update all flake inputs
nix flake update

# Clean old generations and reclaim disk space
sudo nix-collect-garbage -d

# Enter the Python dev shell
nix develop .#python
```

## Architecture Notes

- **Snowfall Lib namespace**: `rhencloud`. The flake uses `snowfall-lib.mkFlake` — this means module paths map to `rhencloud.*` options (e.g., `rhencloud.primaryUser` in `flake.nix:164`).
- **Single host**: `nixos-desktop` (x86_64-linux). The hostname and host platform are set in `systems/x86_64-linux/nixos-desktop/default.nix`.
- **Primary user**: `rhencloud`, set via `rhencloud.primaryUser` in `flake.nix:164`.
- **Channel**: `nixos-unstable`. This is a faster-moving, smaller binary cache.
- **stateVersion**: `26.05` (set in both `flake.nix:169` and `homes/.../default.nix:3`).
- **Window managers**: Both Hyprland and Niri are configured. Hyprland input is fetched via `gh-proxy.com` mirror.
- **Secrets**: Managed with [transcrypt](https://github.com/elasticdog/transcrypt). Encrypted files live in `secrets/` at repo root. Uses `aes-256-cbc` cipher with transparent git clean/smudge filters.
- **Path resolution**: `lib/secrets.nix` provides `rhencloud.lib.secrets.read`, a helper to read secrets from repo root without relative paths. Usage: `rhencloud.lib.secrets.read "opencode/github-token"`. Equivalent to TypeScript's `@/` imports via `inputs.self`.
- **Theming**: Stylix is used for system-wide theming (Dracula theme). The config references tinted-theming base16 schemes.
- **Custom devShells**: The `flake.nix` manually extends `baseFlake.devShells` to add a `python` shell (`shells/python.nix`) — this is outside Snowfall's auto-discovery.

## Gotchas

- Some modules are commented out in their parent `default.nix` (e.g., `./proxy.nix` in both `modules/nixos/core/` and `modules/nixos/desktop/`). Check parent `default.nix` before assuming a module is active.
- `flake.nix` uses `flake.nix` inline module for `systems.modules.nixos` (lines 156-172) — the `home-manager.backupFileExtension = "backup"` setting means HM will back up conflicting files with `.backup` suffix.
- The `nixConfig.substituters` in `flake.nix` configures Chinese mirrors (USTC, SJTU) alongside upstream caches. Cachix caches for hyprland, noctalia, and niri are active.
- `permittedInsecurePackages` includes `electron-39.8.10` — needed for QQ-related packages.
- `hardware-configuration.nix` should **not** be manually edited; regenerate with `nixos-generate-config`.

## Common Modification Patterns

**Adding a new Home Manager module**: Create `modules/home/<category>/<name>/default.nix`. Snowfall auto-imports it.

**Adding a new NixOS module**: Create `modules/nixos/<category>/<name>/default.nix`. Snowfall auto-imports it.

**Adding a new host**: 1) Create `systems/x86_64-linux/<hostname>/default.nix` + `hardware-configuration.nix`. 2) Register in `flake.nix` under `systems.hosts.<hostname>`. 3) Create matching `homes/x86_64-linux/<user>@<hostname>/default.nix`.

**Adding a new flake input**: Add to `inputs` in `flake.nix`. If it provides Home Manager or NixOS modules, add to `homes.modules` or `systems.modules.nixos` respectively.

**Updating a single flake input**: `nix flake update <input-name>` (e.g., `nix flake update home-manager`).

## Secrets Workflow

```bash
# Initialize a fresh clone
transcrypt -c aes-256-cbc -p '<password>'

# List encrypted files
git ls-crypt

# Add a new secret: 1) place file in secrets/, 2) add to git, 3) commit (auto-encrypted)
echo 'my-secret' > secrets/my-key
git add secrets/my-key
git commit -m "add my-key secret"

# Display current credentials
transcrypt --display

# Rekey (change password)
transcrypt --rekey
```

## Style

- Code comments and user-facing strings are in **Chinese** (Simplified).
- Nix formatter: `nixfmt` (available in `home.packages`).
- No CI or pre-commit hooks configured in this repo.
