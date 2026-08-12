{ inputs, ... }:
let
  deployLib = inputs.deploy-rs.lib.x86_64-linux;
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

  # 只强制求值 drvPath，不构建 closure —— 比 deployChecks 快几个数量级
  evalDrv = name: drv: pkgs.writeText "eval-${name}" "${drv.drvPath}\n";
in
{
  perSystem = { ... }: { };

  flake = {
    deploy.nodes.nixos-desktop = {
      hostname = "localhost";
      sshUser = "rhencloud";
      profiles.system = {
        user = "root";
        path = deployLib.activate.nixos inputs.self.nixosConfigurations.nixos-desktop;
      };
      magicRollback = true;
    };

    deploy.nodes.yc-hk-1 = {
      hostname = "83.229.127.169";
      sshOpts = [
        "-p"
        "45855"
      ];
      profiles.system = {
        user = "root";
        path = deployLib.activate.nixos inputs.self.nixosConfigurations.yc-hk-1;
      };
      profiles.home-rhencloud = {
        user = "rhencloud";
        sshUser = "rhencloud";
        path = deployLib.activate."home-manager" inputs.self.homeConfigurations."rhencloud@yc-hk-1";
      };
      profiles.home-wyf9 = {
        user = "wyf9";
        sshUser = "rhencloud";
        path = deployLib.activate."home-manager" inputs.self.homeConfigurations."wyf9@yc-hk-1";
      };
      profilesOrder = [
        "home-rhencloud"
        "home-wyf9"
        "system"
      ];
      magicRollback = true;
    };

    # 轻量 checks：只验证 deploy 相关配置可求值（写 drvPath），不编译系统
    # 完整构建交给 CI matrix 的 nix build toplevel
    checks.x86_64-linux = {
      eval-nixos-desktop = evalDrv "nixos-desktop" inputs.self.nixosConfigurations.nixos-desktop.config.system.build.toplevel;
      eval-yc-hk-1 = evalDrv "yc-hk-1" inputs.self.nixosConfigurations.yc-hk-1.config.system.build.toplevel;
      eval-home-rhencloud-yc-hk-1 =
        evalDrv "home-rhencloud-yc-hk-1"
          inputs.self.homeConfigurations."rhencloud@yc-hk-1".activationPackage;
      eval-home-wyf9-yc-hk-1 =
        evalDrv "home-wyf9-yc-hk-1"
          inputs.self.homeConfigurations."wyf9@yc-hk-1".activationPackage;

      # 确认 deploy.nodes 结构齐全（hostname / profiles 字段存在）
      deploy-nodes-schema =
        let
          nodes = inputs.self.deploy.nodes;
          _ =
            assert nodes ? nixos-desktop;
            assert nodes ? yc-hk-1;
            assert nodes.yc-hk-1 ? hostname;
            assert nodes.yc-hk-1.profiles ? system;
            assert nodes.yc-hk-1.profiles ? home-rhencloud;
            assert nodes.yc-hk-1.profiles ? home-wyf9;
            true;
        in
        pkgs.writeText "deploy-nodes-schema" "ok\n";
    };
  };
}
