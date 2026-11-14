{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhen.hmDevPackages;

  # 上游 nixpkgs 的 cc-switch buildInputs 漏了 sqlite，
  # 但 rusqlite 会链接 -lsqlite3，导致链接阶段失败。
  # cc-switch = pkgs.cc-switch.overrideAttrs (old: {
  #   buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.sqlite ];
  # });
in
{
  config = mkIf cfg.enable {
    # 主题由 noctalia 从壁纸生成；mutableUserSettings 会在激活时把下列设置
    # 合并进现有 settings.json（保留用户在编辑器里改过的其他设置，仍可写）。
    programs.zed-editor = {
      enable = true;
      package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.zed-globalization;
      # userSettings.theme = {
      # mode = "dark";
      # dark = "Noctalia Dark Transparent";
      # };
    };

    home.packages = with pkgs; [
      # inputs."siiway-cli".packages.${pkgs.stdenv.hostPlatform.system}.default
      act
      lychee
      lazygit
      cloudflared
      # ghidra-bin
      codex
      nixd
      # gitkraken
      # cc-switch
      deno
      # claude-code
      openssl
      ripgrep
      tokei
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.aicommits
      gitui
      codegraph
      gh
      tokei
      frida-tools
    ];

    # programs.opencode = {
    #   settings = {
    #     lsp = true;
    #   };
    # };
  };
}
