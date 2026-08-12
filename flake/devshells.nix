_: {
  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixfmt;

    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        nixfmt
        statix
      ];
    };

    devShells.python = pkgs.mkShell {
      buildInputs = with pkgs; [
        python315
        uv
      ];
      shellHook = ''
        echo "Python 3.15 开发环境已激活。"
      '';
    };
  };
}
