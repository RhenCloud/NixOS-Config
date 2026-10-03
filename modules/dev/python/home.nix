{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhen.python;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      python315
      prek
      ruff
      # TTT/nixvim 的 Python 补全引擎：ruff server 只做诊断/quickfix，
      # 不提供 textDocument/completion，补全与跳转必须靠 basedpyright
      basedpyright
      libffi.dev
      # python311
    ];

    programs.uv = {
      enable = true;
      settings = {
        system-certs = true;
        index = [ { url = "https://pypi.org/simpl"; } ];
      };
    };
  };
}
