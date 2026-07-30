{
  config,
  pkgs,
  lib,
  ...
}:
{
  networking.hostName = "server";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.fsIdentifier = "provided";

  networking.firewall.enable = false;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    neovim
    tree
    unzip
    jq
    bat
    docker
    docker-compose
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+/7cpkWShU8aEDBq2StSJRSeVbFvj8BSEP85HEEtYZ i@rhen.cloud"
  ];

  users.users.rhencloud = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+/7cpkWShU8aEDBq2StSJRSeVbFvj8BSEP85HEEtYZ i@rhen.cloud"
    ];
  };

  users.users.wyf9 = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFIma5iDdPnEdjYbj7epS/ogQaJmWAvWm8jnXgvU10x wyf9@wyf9Desktop"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  virtualisation.docker.enable = true;

  system.stateVersion = lib.mkForce "26.11";
}
