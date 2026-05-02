{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python315
    prek
    ruff
    # python311
  ];

  nixpkgs.config.allowInsecure = true;

  programs.uv = {
    enable = true;
    settings = {
      index = [ { url = "https://mirror.sjtu.edu.cn/pypi/web/simple/"; } ];
    };
  };
}
