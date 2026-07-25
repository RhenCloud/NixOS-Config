{ config, lib, pkgs, ... }:
with lib;
let cfg = config.rhencloud.browser;
in {
  options.rhencloud.browser.enable = mkEnableOption "browser and editor";

  config = mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        "bgnkhhnnamicmpeenaelnjfhikgbkllg"
        "ndcooeababalnlpkfedmmbbbgkljhpjf"
        "lildghglkgcoanblbmenbefhnhifghjj"
        "nngceckbapebfimnlniiiahkandclblb"
        "jlgkpaicikihijadgifklkbpdajbkhjo"
      ];
    };

    programs.vscode = {
      enable = true;
    };
  };
}
