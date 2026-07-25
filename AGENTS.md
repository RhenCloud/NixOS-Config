# AGENTS.md

NixOS system configuration for RhenCloud, managed as a Nix flake using **flake-parts**.

## Repo Layout

```
flake.nix                      # Entry point: inputs, flake-parts config, submodule imports
flake/pkgs.nix                 # perSystem pkgs (allowUnfree + overlays)
flake/nixos.nix                # NixOS configurations (auto-discovers hosts/)
flake/home-manager.nix         # Home Manager configurations (auto-discovers homes/)
flake/packages.nix             # Custom packages (herdr-tab-rename, aicommits, etc.)
flake/devshells.nix            # devShells (default + python)
flake/lib.nix                  # flake.lib exports (readSecret, etc.)
flake/helpers.nix              # Internal helpers (module/overlay discovery)
systems/x86_64-linux/nixos-desktop/   # Single host entry (default.nix + hardware-configuration.nix)
homes/x86_64-linux/rhencloud@nixos-desktop/  # Home Manager entry for rhencloud
modules/nixos/{core,desktop,service}/  # System-level modules (auto-collected by collectDefaultNix)
modules/home/{core,desktop,dev,service}/  # Home Manager modules (auto-collected)
lib/                           # Library helpers (rhencloud.lib.* — not auto-exposed, use via inputs)
secrets/                       # transcrypt-encrypted secrets
overlays/                      # Custom package overlays (niri, portal-gtk, mexkey3-ccid)
patches/                       # Patches for niri
```

Module discovery is handled by `collectDefaultNix` in `flake/helpers.nix` — recursively finds all `default.nix` under `modules/`. Adding a new directory with a `default.nix` is enough.

## Key Commands

```bash
# Build and switch (apply) the system config (先查缓存，有则跳过构建)
./scripts/rebuild.sh

# Dry-run only: check cache status without building
./scripts/rebuild.sh check

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

- **Framework**: flake-parts replaces Snowfall Lib.
- **Single host**: `nixos-desktop` (x86_64-linux). Hostname set in `systems/x86_64-linux/nixos-desktop/default.nix`.
- **Primary user**: `rhencloud`, passed as `specialArgs`/`extraSpecialArgs` from `flake/config.nix`.
- **Channel**: `nixos-unstable`. This is a faster-moving, smaller binary cache.
- **stateVersion**: `26.11`.
- **Window managers**: Both Hyprland and Niri are configured.
- **Secrets**: Managed with [transcrypt](https://github.com/elasticdog/transcrypt). Encrypted files live in `secrets/` at repo root. Uses `aes-256-cbc` cipher with transparent git clean/smudge filters.
- **Path resolution**: `lib/secrets.nix` provides `rhencloud.lib.secrets.read`, a helper to read secrets from repo root without relative paths. Usage: `rhencloud.lib.secrets.read "opencode/github-token"`. Equivalent to TypeScript's `@/` imports via `inputs.self`. Also available as `inputs.self.lib.readSecret`.
- **Theming**: Stylix for system-wide theming (Dracula theme).
- **Overlays**: Applied in both NixOS (config.nix) and home-manager (commonHomeModules). Includes niri patches, portal-gtk integration, and mexkey3-ccid support.
- **Module auto-discovery**: `collectDefaultNix` in `config.nix` recursively walks `modules/` and collects all `default.nix` files. Snowfall-style `rhencloud.*` options are plain NixOS module options, not namespace magic.
- **Host/home auto-discovery**: `flake/nixos.nix` and `flake/home-manager.nix` auto-scan `systems/<arch>/` and `homes/<arch>/` directories, no manual registration needed.

## Gotchas

- Some modules are commented out in their parent `default.nix` (e.g., `./proxy.nix` in both `modules/nixos/core/` and `modules/nixos/desktop/`). Check parent `default.nix` before assuming a module is active.
- `home-manager.backupFileExtension = "backup"` — HM will back up conflicting files with `.backup` suffix.
- The `nixConfig.substituters` in `flake.nix` configures Chinese mirrors (USTC, SJTU) alongside upstream caches. Cachix caches for hyprland, noctalia, and niri are active.
- `permittedInsecurePackages` includes `electron-39.8.10` — needed for QQ-related packages.
- `hardware-configuration.nix` should **not** be manually edited; regenerate with `nixos-generate-config`.
- `@` in path names (e.g., `rhencloud@nixos-desktop`) is valid Nix but may trigger false-positive LSP warnings.

## Common Modification Patterns

**Adding a new Home Manager module**: Create `modules/home/<category>/<name>/default.nix`. `collectDefaultNix` auto-includes it.

**Adding a new NixOS module**: Create `modules/nixos/<category>/<name>/default.nix`. Same auto-inclusion.

**Adding a new host**: 1) Create `systems/x86_64-linux/<hostname>/default.nix` + `hardware-configuration.nix`. 2) Create matching `homes/x86_64-linux/<user>@<hostname>/default.nix`. Both are auto-discovered by `flake/nixos.nix` and `flake/home-manager.nix`.

**Adding a new flake input**: Add to `inputs` in `flake.nix`. If it provides Home Manager or NixOS modules, add to the appropriate module list in `flake/config.nix`.

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
