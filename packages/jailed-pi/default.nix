{
  inputs,
  pkgs,
  ...
}:
inputs.jailed-agents.lib.${pkgs.stdenv.hostPlatform.system}.makeJailedPi {
  # 复用已由 Nixpkgs 管理的 Pi，避免引入另一套 Pi 版本。
  pkg = pkgs.pi-coding-agent;

  # Pi 的 MCP 配置会调用 uvx、npx 与 bunx；Nix 工作流则需要 daemon socket。
  extraPkgs = with pkgs; [
    bun
    nodejs
    uv
  ];
  enableNix = true;

  # 仅暴露 Pi 实际需要的两个 SOPS 渲染配置。不要挂载整个 /run/secrets。
  extraReadonlyDirs = [ "/run/secrets/templates/pi" ];
}
