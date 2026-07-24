{ pkgs, inputs, config, ... }:
let
  user = config.my.user.name;
in {
  config = {
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
