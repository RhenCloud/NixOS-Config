{ pkgs, inputs, config, ... }:
{
  home.packages = with pkgs; [
    inputs.agenix.packages.${pkgs.system}.default
  ];
  age = {
    # secretsDir = "/home/${config.home.username}/.agenix";
    secrets = {
      # musicfoxCookie = {
      #   file = ./musicfoxCookie.age;
      #   path = "/home/${config.home.username}/.local/share/go-musicfox/cookie";
      # };
      peopleName = {
        file = ./people_name.dict.yaml.age;
        path = "/home/${config.home.username}/.local/share/fcitx5/rime/people_name.dict.yaml";
      };
      mihomoConfig = {
        file = ./mihomoConfig.yaml.age;
        path = "/home/${config.home.username}/.config/mihomo/config.yaml";
      };
    };
  };
}
