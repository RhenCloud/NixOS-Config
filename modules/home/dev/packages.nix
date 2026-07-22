{
  pkgs,
  inputs,
  ...
}:
{
  home.packages = with pkgs; [
    inputs."siiway-cli".packages.${pkgs.stdenv.hostPlatform.system}.default
    act
    lychee
    lazygit
    cloudflared
    ghidra-bin
    codex
    opencode
    gitkraken
    cc-switch
    deno
    claude-code
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.zed-globalization
    openssl
    ripgrep
    tokei
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.aicommits
    gitui
    codegraph
  ];

  # programs.opencode = {
  #   settings = {
  #     lsp = true;
  #   };
  # };
}
