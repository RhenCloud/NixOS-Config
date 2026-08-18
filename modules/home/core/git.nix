{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.git;
in
{
  options.rhencloud.git.enable = mkEnableOption "git, SSH, and GPG";

  config = mkIf cfg.enable {
    programs = {
      git = {
        enable = true;
        signing = {
          signByDefault = true;
          format = "openpgp";
        };
        settings = {
          gpg.program = "${pkgs.gnupg}/bin/gpg";
          credential.helper = "store";
          commit.gpgsign = true;
          tag.gpgSign = true;
          init.defaultBranch = "main";
          push.autoSetupRemote = true;
          user = {
            name = config.my.user.fullName;
            email = config.my.user.email;
            signingKey = config.my.user.signingKey;
          };
        };
      };
      gpg.enable = true;
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        extraConfig = ''
          AddKeysToAgent no

          Host yc-hk-1
              HostName 83.229.127.169
              Port 45855
              User rhencloud

          Host nixos-desktop
              HostName 10.114.0.5
              User rhencloud
              ProxyJump yc-hk-1

          Include ${config.sops.templates."ssh-host-blocks".path}
        '';
        settings = {
          "*" = { };
        };
      };
    };

    sops.secrets = {
      "ssh-tc-discourse" = {
        sopsFile = ../../../secrets/hosts/nixos-desktop.yaml;
      };
      "ssh-bee-hk-1" = {
        sopsFile = ../../../secrets/hosts/nixos-desktop.yaml;
      };
    };

    sops.templates."ssh-host-blocks" = {
      mode = "0644";
      content =
        config.sops.placeholder."ssh-tc-discourse" + "\n\n" + config.sops.placeholder."ssh-bee-hk-1" + "\n";
    };

    home.packages = [ pkgs.gcr ];

    services.gpg-agent = {
      enable = true;
      enableScDaemon = true;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-gnome3;
      defaultCacheTtl = 86400;
      maxCacheTtl = 604800;
      defaultCacheTtlSsh = 86400;
      maxCacheTtlSsh = 604800;
    };

    home.file.".gnupg/scdaemon.conf".text = ''
      disable-ccid
    '';
  };
}
