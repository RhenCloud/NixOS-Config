{ pkgs, inputs, config, lib, ... }:
with lib;
let
  user = config.my.user.name;
  cfg = config.rhencloud.identity;
in {
  options.rhencloud.identity.enable = mkEnableOption "user identity configuration";

  config = mkIf cfg.enable {
    _module.args.primaryUser = user;

    users.users.${user} = {
      isNormalUser = true;
      group = user;
      hashedPassword = builtins.readFile "${inputs.self}/secrets/password-hash";
      shell = pkgs.bash;
      extraGroups = [
        "networkmanager"
        "video"
        "audio"
        "input"
        "kvm"
        "wheel"
      ];
    };

    users.groups.${user} = { };

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
