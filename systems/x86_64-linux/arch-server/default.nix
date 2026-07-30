{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    {
      networking.hostName = "arch-server";
      my.host.name = "arch-server";
      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ];

  users.users.rhencloud.hashedPassword = lib.mkForce "$6$Pm5PSFcJF8DBmf7E$MAKt8KfhX.vXpGfqB.fbMnL3e9N2.pOvSiiJb/eG.nQslcWnr.SBpH2XrWXknAHw.a3FoGETICqwVME/i4OdU1";

  rhencloud = {
    boot.enable = true;
    identity.enable = true;
    env.enable = true;
    locale.enable = true;
    nix.enable = true;
    packages.enable = true;
    shells.enable = true;

    docker.enable = true;
    router.enable = true;
  };
}
