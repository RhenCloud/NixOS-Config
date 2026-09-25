{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # v5 beta 包（原生重写），二进制为 `noctalia`，由各合成器 autostart 启动。
  noctaliaV5 = inputs.noctalia-latest.packages.${system}.default;

  # 显式包装器，便于手动无歧义地启动。
  noctaliaV5Launcher = pkgs.writeShellScriptBin "noctalia-v5" ''
    exec ${noctaliaV5}/bin/noctalia "$@"
  '';
in
with lib;
let
  cfg = config.rhencloud.noctalia;
in
{
  options.rhencloud.noctalia.enable = mkEnableOption "Noctalia shell";
  config = mkIf cfg.enable {
    home.packages = [
      noctaliaV5
      noctaliaV5Launcher
      pkgs.evtest
    ];
  };
}
