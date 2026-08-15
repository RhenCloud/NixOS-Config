{ inputs, ... }:
let
  # 默认主机 / 部署节点，未指定参数时使用
  defaultHost = "nixos-desktop";
  defaultNode = "yc-hk-1";
in
{
  perSystem =
    { pkgs, system, ... }:
    let
      deployRs = inputs.deploy-rs.packages.${system}.deploy-rs;
      mkApp = name: drv: {
        type = "app";
        program = "${drv}/bin/${name}";
      };

      # build / test / switch 都基于 nixos-rebuild，仅模式不同
      # test / switch 需要 root，build 以普通用户运行即可
      mkRebuild =
        mode:
        pkgs.writeShellScriptBin mode ''
          host="''${1:-${defaultHost}}"
          if [ "${mode}" != "build" ] && ! id -u | grep -q '^0$'; then
            exec sudo nixos-rebuild ${mode} --flake ".#''${host}"
          else
            exec nixos-rebuild ${mode} --flake ".#''${host}"
          fi
        '';
    in
    {
      apps = {
        build = mkApp "build" (mkRebuild "build");
        test = mkApp "test" (mkRebuild "test");
        switch = mkApp "switch" (mkRebuild "switch");
        deploy = mkApp "deploy" (
          pkgs.writeShellScriptBin "deploy" ''
            node="''${1:-${defaultNode}}"
            exec ${deployRs}/bin/deploy-rs ".#''${node}" --auto-rollback true
          ''
        );
      };
    };
}
