{ inputs, self, ... }:
let
  deployLibFor =
    host: inputs.deploy-rs.lib.${self.nixosConfigurations.${host}.pkgs.stdenv.hostPlatform.system};
in
{
  nodes = {
    nixos-desktop = {
      hostname = "localhost";
      sshUser = "rhencloud";
      profiles.system = {
        user = "root";
        path = (deployLibFor "nixos-desktop").activate.nixos self.nixosConfigurations.nixos-desktop;
      };
      magicRollback = true;
    };

    yc-hk-1 = {
      hostname = "83.229.127.169";
      sshOpts = [
        "-p"
        "45855"
      ];
      profiles = {
        system = {
          user = "root";
          path = (deployLibFor "yc-hk-1").activate.nixos self.nixosConfigurations.yc-hk-1;
        };
        home-rhencloud = {
          user = "rhencloud";
          sshUser = "rhencloud";
          path = (deployLibFor "yc-hk-1").activate.home-manager self.homeConfigurations."rhencloud@yc-hk-1";
        };
        home-wyf9 = {
          user = "wyf9";
          sshUser = "rhencloud";
          path = (deployLibFor "yc-hk-1").activate.home-manager self.homeConfigurations."wyf9@yc-hk-1";
        };
        home-advan10 = {
          user = "advan10";
          sshUser = "rhencloud";
          path = (deployLibFor "yc-hk-1").activate.home-manager self.homeConfigurations."advan10@yc-hk-1";
        };
      };
      profilesOrder = [
        "home-rhencloud"
        "home-wyf9"
        "home-advan10"
        "system"
      ];
      magicRollback = true;
    };

    nixos-homeserver = {
      hostname = "10.0.0.1";
      sshUser = "rhencloud";
      profiles.system = {
        user = "root";
        path = (deployLibFor "nixos-homeserver").activate.nixos self.nixosConfigurations.nixos-homeserver;
      };
      profilesOrder = [ "system" ];
      magicRollback = true;
    };
  };
}
