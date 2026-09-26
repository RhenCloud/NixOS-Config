{
  config,
  lib,
  pkgs,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.meli;

  accounts = [
    {
      name = "rhen.cloud";
      identity = "i@rhen.cloud";
      username = "i@rhen.cloud";
      imap = {
        hostname = "mail.rhen.cloud";
        port = 993;
      };
      smtp = {
        hostname = "mail.rhen.cloud";
        port = 587;
      };
    }
    {
      name = "siiway.org";
      identity = "rhencloud@siiway.org";
      username = "rhencloud@siiway.org";
      imap = {
        hostname = "imap.feishu.cn";
        port = 993;
      };
      smtp = {
        hostname = "smtp.feishu.cn";
        port = 587;
      };
    }
    {
      name = "gmail";
      identity = "cloudrhen@gmail.com";
      username = "cloudrhen@gmail.com";
      imap = {
        hostname = "imap.gmail.com";
        port = 993;
      };
      smtp = {
        hostname = "smtp.gmail.com";
        port = 587;
      };
    }
    # {
    #   name = "outlook";
    #   identity = "rhencloud75@outlook.com";
    #   username = "rhencloud75@outlook.com";
    #   imap = {
    #     hostname = "outlook.office365.com";
    #     port = 993;
    #   };
    #   smtp = {
    #     hostname = "smtp-mail.outlook.com";
    #     port = 587;
    #   };
    # }
    {
      name = "worldexecute.me";
      identity = "hello@worldexecute.me";
      username = "hello@worldexecute.me";
      imap = {
        hostname = "mail.worldexecute.me";
        port = 993;
      };
      smtp = {
        hostname = "mail.worldexecute.me";
        port = 587;
      };
    }
    {
      name = "akiebb.dev";
      identity = "me@akiebb.dev";
      username = "me@akiebb.dev";
      imap = {
        hostname = "mail.akiebb.dev";
        port = 993;
      };
      smtp = {
        hostname = "mail.akiebb.dev";
        port = 587;
      };
    }
  ];

  passwordName = account: "meli-${replaceStrings [ "." ] [ "-" ] account.name}-password";

  accountToml = account: ''
    [accounts."${account.name}"]
    root_mailbox = "INBOX"
    format = "imap"
    server_hostname = "${account.imap.hostname}"
    server_username = "${account.username}"
    server_password = "${config.sops.placeholder.${passwordName account}}"
    server_port = ${toString account.imap.port}
    use_tls = true
    use_starttls = false
    search_backend = "sqlite3"
    identity = "${account.identity}"

    [accounts."${account.name}".send_mail]
    hostname = "${account.smtp.hostname}"
    port = ${toString account.smtp.port}

    [accounts."${account.name}".send_mail.auth]
    type = "auto"
    username = "${account.username}"

    [accounts."${account.name}".send_mail.auth.password]
    type = "raw"
    value = "${config.sops.placeholder.${passwordName account}}"

    [accounts."${account.name}".send_mail.security]
    type = "STARTTLS"
  '';
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      meli
      w3m
    ];

    sops.secrets = listToAttrs (
      map (account: {
        name = passwordName account;
        value = snowveil.sops.secret { source = "common"; };
      }) accounts
    );

    sops.templates."meli/config.toml" = {
      mode = "0600";
      content = concatStringsSep "\n" (map accountToml accounts) + "\n";
    };

    xdg.configFile."meli/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink
        config.sops.templates."meli/config.toml".path;
  };
}
