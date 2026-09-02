{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.emacs;
in
{
  config = mkIf cfg.enable {
    # nixpkgs.config.packageOverrides = pkgs {
    #   myEmacs = pkgs.emacs.pkgs.withPackages (
    #     epkgs: with epkgs; [
    #       org
    #       nixmode
    #     ]
    #   );
    # };

    programs.emacs = {
      enable = true;
      # package = pkgs.myEmacs;
      package = pkgs.emacs;
      extraPackages = epkgs: [
        epkgs.nix-mode
        epkgs.nixfmt
      ];
      extraConfig = ''
        (setq standard-indent 2)
      '';
    };

    services.emacs = {
      enable = true;
      defaultEditor = false;
      # package = pkgs.myEmacs;
    };
  };
}
