{ inputs, ... }:
{
  perSystem = { ... }: { };

  flake = {
    deploy.nodes.yc-hk-1 = {
      hostname = "83.229.127.169";
      sshOpts = [
        "-p"
        "45855"
      ];
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.yc-hk-1;
      };
    };

    checks = builtins.mapAttrs (
      system: deployLib: deployLib.deployChecks inputs.self.deploy
    ) inputs.deploy-rs.lib;
  };
}
