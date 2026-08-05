{ inputs, ... }:
let
  deployLib = inputs.deploy-rs.lib.x86_64-linux;
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
      magicRollback = false;
    };

    checks = builtins.mapAttrs (
      system: deployLib: deployLib.deployChecks inputs.self.deploy
    ) inputs.deploy-rs.lib;
  };
}
