{ inputs, lib, ... }: {
  flake.colmenaHive = inputs.colmena.lib.makeHive {
    meta = {
      nixpkgs = inputs.nixpkgs;
      specialArgs = {
        inherit inputs;
        primaryUser = "rhencloud";
      };
    };

    defaults = { ... }: { };

    nixos-desktop = { ... }: {
      deployment.targetHost = null;
      deployment.allowLocalDeployment = true;

      imports = [ ../../systems/x86_64-linux/nixos-desktop ];
    };

    yc-hk-1 = { ... }: {
      deployment.targetHost = "83.229.127.169";
      deployment.targetPort = 45855;

      deployment.tags = [
        "siiway"
        "server"
        "hk"
      ];

      imports = [ ../../systems/x86_64-linux/yc-hk-1 ];
    };
  };
}
