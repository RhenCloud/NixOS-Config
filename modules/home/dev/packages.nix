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
    openssl
    ripgrep
  ];

  # programs.opencode = {
  #   settings = {
  #     lsp = true;
  #   };
  # };
}
