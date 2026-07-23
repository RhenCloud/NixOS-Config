{ pkgs, inputs, config, ... }:
let
  username = builtins.head (builtins.attrNames config.snowfallorg.users);
in
{
  config = {
    _module.args.primaryUser = username;

    users.users.${username} = {
      hashedPassword = builtins.readFile "${inputs.self}/secrets/password-hash";
      shell = pkgs.bash;
      extraGroups = [
        "networkmanager"
        "video"
        "audio"
        "input"
        "kvm"
      ];
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