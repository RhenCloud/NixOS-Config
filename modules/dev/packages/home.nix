{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.hmDevPackages;
in
{
  config = mkIf cfg.enable {
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
      cc-switch
      deno
      # claude-code
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.zed-globalization
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
