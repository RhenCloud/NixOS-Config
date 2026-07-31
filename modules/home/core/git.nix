{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.git;

  inherit (inputs.self.lib) readSecret;

  sshTcDiscourse = readSecret "ssh/tc-discourse";
  sshBeeHk1 = readSecret "ssh/bee-hk-1";
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
          AddKeysToAgent yes

          ${sshTcDiscourse}

          ${sshBeeHk1}
        '';
        settings = {
          "*" = {
            identityAgent = "~/.gnupg/S.gpg-agent.ssh";
          };
        };
      };
    };

    services.gpg-agent = {
      enable = true;
      enableScDaemon = true;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-gtk2;
      defaultCacheTtl = 86400;
      maxCacheTtl = 604800;
      defaultCacheTtlSsh = 86400;
      maxCacheTtlSsh = 604800;
    };

    home.file.".gnupg/scdaemon.conf".text = ''
      disable-ccid
      pcsc-shared
    '';
  };
}
