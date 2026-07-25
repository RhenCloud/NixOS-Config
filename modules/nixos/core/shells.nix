{ config, lib, pkgs, ... }:
with lib;
let cfg = config.rhencloud.shells;
in {
  options.rhencloud.shells.enable = mkEnableOption "shells configuration";

  config = mkIf cfg.enable {
    programs = {
      bash = {
        enable = true;
        interactiveShellInit = ''
          if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
          then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
            exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
          fi
        '';
      };
      fish.enable = true;
      zsh.enable = true;
      dconf.enable = true;
    };
  };
}
