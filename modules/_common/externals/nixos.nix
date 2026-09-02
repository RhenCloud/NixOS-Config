{
  config,
  lib,
  inputs,
  snowveil,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    inputs.selector4nix.nixosModules.selector4nix
    inputs.fast-nix-gc.nixosModules.default
    ({ ... }: { sops.useSystemdActivation = true; })
  ];

  # 仅在框架实际嵌入 Home Manager 时应用，服务器可安全共享此模块。
  snowveil.homeManager.backupFileExtension = "backup";

  system.stateVersion = lib.mkDefault config.my.stateVersion;
}
