{ pkgs, config, ... }:
let
  username = builtins.head (builtins.attrNames config.snowfallorg.users);
in
{
  config = {
    _module.args.primaryUser = username;

    users.users.${username} = {
      hashedPassword = "$y$j9T$9g/eMEwVjfWXhiR8M3UzN/$baNRWXMywZY8fsLIvC/1uPQxDJNksgpDRKyosat01Y9";
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