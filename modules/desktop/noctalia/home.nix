{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # v5 beta package (native rewrite). Its main binary is `noctalia`, which does
  # not collide with v4's `noctalia-shell`, so both can be installed together.
  noctaliaV5 = inputs.noctalia-latest.packages.${system}.default;

  # v4 package (Quickshell). Kept installed as a fallback ("以备不时之需").
  noctaliaV4 = inputs.noctalia-v4.packages.${system}.default;

  # Explicit wrappers so either version can be started manually and unambiguously.
  noctaliaV5Launcher = pkgs.writeShellScriptBin "noctalia-v5" ''
    exec ${noctaliaV5}/bin/noctalia "$@"
  '';
  noctaliaV4Launcher = pkgs.writeShellScriptBin "noctalia-v4" ''
    exec ${noctaliaV4}/bin/noctalia-shell "$@"
  '';
in
with lib;
let
  cfg = config.rhencloud.noctalia;
in
{
  options.rhencloud.noctalia.enable = mkEnableOption "Noctalia shell";
  config = mkIf cfg.enable {
    # v4 is kept installed as a fallback. It provides the `noctalia-shell` binary
    # and manages the v4 (JSON) config. It is NO LONGER autostarted — the
    # compositors now autostart v5 (`noctalia`). v4 and v5 configs live in
    # different files, so keeping both enabled does not conflict.
    programs.noctalia-shell = {
      enable = true;
    };

    # v5 beta is now the DEFAULT shell: the compositors autostart `noctalia`
    # (see hyprland/niri/mango autostart configs) and keybinds use `noctalia msg`.
    #
    # Manual control:
    #   noctalia        # v5 binary (default)
    #   noctalia-v5     # explicit v5 wrapper (same thing)
    #   noctalia-shell  # v4 binary (fallback)
    #   noctalia-v4     # explicit v4 wrapper (same thing)
    #
    # To fall back to v4: stop v5 (`pkill noctalia`) and run `noctalia-v4`,
    # or temporarily swap the compositor autostart entry back to `noctalia-shell`.
    home.packages = [
      noctaliaV5
      noctaliaV5Launcher
      noctaliaV4Launcher
      pkgs.evtest
    ];
  };
}
