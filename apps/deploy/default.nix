{
  self,
  stdenvNoCC,
  writeShellScriptBin,
  ...
}:
let
  deployRs = self.packages.${stdenvNoCC.hostPlatform.system}.deploy-rs;
  defaultNode = "yc-hk-1";
  script = writeShellScriptBin "deploy" ''
    node="''${1:-${defaultNode}}"
    exec ${deployRs}/bin/deploy ".#''${node}" --auto-rollback true
  '';
in
{
  type = "app";
  program = "${script}/bin/deploy";
}
