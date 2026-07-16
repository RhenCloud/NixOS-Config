{
  pkgs,
  config,
  ...
}:
let
  username = config.rhencloud.primaryUser;
in
{
  users = {
    users.${username} = {
      home = "/home/${username}";
      shell = pkgs.bash;
      hashedPassword = "$y$j9T$9g/eMEwVjfWXhiR8M3UzN/$baNRWXMywZY8fsLIvC/1uPQxDJNksgpDRKyosat01Y9";
      isNormalUser = true;
      group = username;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
        "input"
        "kvm"
      ];
    };
    groups.${username} = { };
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
}
