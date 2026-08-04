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
flake/helpers.nix              # Internal helpers (module/overlay discovery)
systems/x86_64-linux/nixos-desktop/   # Single host entry (default.nix + hardware-configuration.nix)
homes/x86_64-linux/rhencloud@nixos-desktop/  # Home Manager entry for rhencloud
modules/nixos/{core,desktop,service}/  # System-level modules (auto-collected by collectDefaultNix)
modules/home/{core,desktop,dev,service}/  # Home Manager modules (auto-collected)
secrets/                       # sops-encrypted secrets (common.yaml + hosts/<host>.yaml)
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
- **Secrets**: Managed with [sops-nix](https://github.com/Mic92/sops-nix). Encrypted files live in `secrets/` (`common.yaml` + `hosts/<host>.yaml`). Encryption keys: GPG admin subkey `CE243917D8877F3AFE5814335850468557847C77` (editing) + per-host SSH host key → age (runtime decrypt). `sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]` per host.
- **Secrets in modules**: Use `config.sops.secrets."<name>".path` (runtime-decrypted to `/run/secrets/<name>`) and `sops.templates` (placeholder `${config.sops.placeholder."<key>"}` rendered at activation). **Never** `builtins.readFile` secrets.
- **HM secrets**: NixOS layer renders full config files via `sops.templates` (`/run/secrets/templates/`); HM references them with `config.lib.file.mkOutOfStoreSymlink "/run/secrets/templates/<file>"`.
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
# Edit an encrypted file (GPG admin key decrypts; save re-encrypts)
sops secrets/common.yaml
sops secrets/hosts/nixos-desktop.yaml

# Add a secret: edit the file, then declare it in a module
sops.secrets."my-key" = { sopsFile = ./secrets/hosts/nixos-desktop.yaml; owner = "root"; mode = "0400"; };

# Add a new host: convert its SSH host pubkey to age, add to .sops.yaml, re-encrypt
ssh-keyscan <host> | nix shell nixpkgs#ssh-to-age -c ssh-to-age
sops updatekeys secrets/common.yaml
sops updatekeys secrets/hosts/<host>.yaml
```

## Style

- Code comments and user-facing strings are in **Chinese** (Simplified).
- Nix formatter: `nixfmt` (available in `home.packages`).
- No CI or pre-commit hooks configured in this repo.
