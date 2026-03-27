{ config, inputs, pkgs, ... }:
{
  home.packages = [
    pkgs.sops
    inputs.agenix.packages.x86_64-linux.default
  ];
  age = {
    identityPaths = [
      "${config.home.homeDirectory}/.ssh/id_ed25519"
    ];

    secrets = {
      peopleName = {
        file = ./people_name.dict.yaml.age;
        path = "${config.home.homeDirectory}/.local/share/fcitx5/rime/people_name.dict.yaml";
      };

      # mihomoConfig = {
      #   file = ./mihomoConfig.yaml.age;
      #   path = "/home/${config.home.username}/.config/mihomo/config.yaml";
      # };

      # musicfoxCookie = {
      #   file = ./musicfoxCookie.age;
      #   path = "/home/${config.home.username}/.local/share/go-musicfox/cookie";
      # };
    };
  };

}
