{
  pkgs,
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  user = config.rhen.user.name;
  cfg = config.rhen.identity;
in
{
  options.rhen.identity.enable = mkEnableOption "user identity configuration";

  config = mkIf cfg.enable {
    _module.args.primaryUser = user;

    sops.secrets."password-hash" = mkDefault (
      snowveil.sops.secret { source = "common"; }
      // {
        neededForUsers = true;
      }
    );

    users.users.${user} = {
      hashedPasswordFile = mkDefault config.sops.secrets."password-hash".path;
      shell = mkDefault pkgs.bash;
    };

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
      extraConfig = ''
        Defaults env_keep += "SSH_AUTH_SOCK"
      '';
      extraRules = [
        {
          commands = [
            {
              command = "${pkgs.systemd}/bin/systemctl suspend";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${pkgs.systemd}/bin/reboot";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${pkgs.systemd}/bin/poweroff";
              options = [ "NOPASSWD" ];
            }
          ];
          groups = [ "wheel" ];
        }
      ];
    };
  };
}
