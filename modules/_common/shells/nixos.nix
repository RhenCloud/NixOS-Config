{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.shells;
  # 仅主用户自动切换到 fish，其他用户保持 bash
  primaryUser = config.my.user.name;
in
{
  options.rhencloud.shells.enable = mkEnableOption "shells configuration";

  config = mkIf cfg.enable {
    programs = {
      bash = {
        enable = true;
        interactiveShellInit = ''
          if [[ "$USER" == "${primaryUser}" && $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
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
