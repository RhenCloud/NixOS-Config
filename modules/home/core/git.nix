{ pkgs, config, ... }:
{
  # git 相关配置
  programs.git = {
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
        name = "RhenCloud";
        email = "i@rhen.cloud";
        signingKey = "REDACTED-59acd1c2";
      };
    };
  };

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableScDaemon = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-gtk2;
    defaultCacheTtl = 1800;
    maxCacheTtl = 7200;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        identityAgent = "~/.gnupg/S.gpg-agent.ssh";
      };
      "tc-discourse" = {
        hostname = "154.44.13.130";
        user = config.snowfallorg.user.name;
      };
    };
  };

  home.file.".gnupg/scdaemon.conf".text = ''
    disable-ccid
    pcsc-shared
  '';
}
