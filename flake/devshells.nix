{ ... }:
{
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [ nixfmt-rfc-style ];
    };

    devShells.python = pkgs.mkShell {
      buildInputs = with pkgs; [ python315 uv ];
      shellHook = ''
        echo "Python 3.15 开发环境已激活。"
      '';
    };
  };
}
