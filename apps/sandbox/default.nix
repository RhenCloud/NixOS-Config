{
  lib,
  self,
  stdenvNoCC,
  ...
}:
{
  type = "app";
  program = lib.getExe self.packages.${stdenvNoCC.hostPlatform.system}.sandbox;
}
