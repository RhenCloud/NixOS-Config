{ pkgs, primaryUser, ... }: {
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
  };

  # Allow the primary user to run docker without sudo.
  users.users.${primaryUser}.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
