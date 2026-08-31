{
  mkShell,
  python315,
  uv,
  ...
}:
mkShell {
  buildInputs = [
    python315
    uv
  ];
  shellHook = ''
    echo "Python 3.15 开发环境已激活。"
  '';
}
