{
  pkgs,
  ...
}: {
  programs.noctalia-shell = {
    enable = true;
  };

  home.packages = with pkgs; [
    evtest
  ];
}
