{ mode }:
{
  writeShellScriptBin,
  ...
}:
let
  defaultHost = "nixos-desktop";
  script = writeShellScriptBin mode ''
    host="''${1:-${defaultHost}}"
    if [ "${mode}" != "build" ] && ! id -u | grep -q '^0$'; then
      exec sudo nixos-rebuild ${mode} --flake ".#''${host}"
    else
      exec nixos-rebuild ${mode} --flake ".#''${host}"
    fi
  '';
in
{
  type = "app";
  program = "${script}/bin/${mode}";
}
