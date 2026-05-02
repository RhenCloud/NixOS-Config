{
  pkgs,
  ...
}:
{
  # imports = [
  #   inputs.noctalia.nixosModules.default
  # ];

  programs.noctalia-shell = {
    enable = true;
    # plugins = {
    #   sources = [
    #     {
    #       enabled = true;
    #       name = "Official Noctalia Plugins";
    #       url = "https://github.com/noctalia-dev/noctalia-plugins";
    #     }
    #   ];
    #   states = {
    #     catwalk = {
    #       enabled = true;
    #       # sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
    #     };
    #     slowbongo = {
    #       enabled = true;
    #       # sourceUrl = "https://github.com/tuibird/slowbongo";
    #     };
    #     clipper = {
    #       enabled = true;
    #       # sourceUrl = "https://github.com/blackbartblues/noctalia-clipper";
    #     };
    #     niri-overview-launcher = {
    #       enabled = true;
    #     };
    #     usb-drive-manager = {
    #       enabled = true;
    #     };
    #     mpris-lyric = {
    #       enable = true;
    #     };
    #   };
    #   version = 2;
    # };
    # pluginSettings = {
    #   imports = [
    #     ./noctalia-plugins.nix
    #   ];
    # };
  };

  home.packages = with pkgs; [
    evtest
    # noctalia-shell
  ];
}
