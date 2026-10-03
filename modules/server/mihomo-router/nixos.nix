{
  config,
  inputs,
  lib,
  pkgs,
  snowveil,
  ...
}:
let
  cfg = config.rhen.services.mihomo-router;
  package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.mihomo-meta;
  overrideFile = pkgs.writeText "mihomo-router-override.yaml" (builtins.readFile ./override.yaml);
  mergeScript = pkgs.writeShellScript "mihomo-router-merge" ''
    ${lib.getExe pkgs.yq-go} ea '. as $item ireduce ({}; . * $item)' \
      ${config.sops.secrets."mihomo-config".path} ${overrideFile} \
      > /run/mihomo-router/config.yaml
  '';
in
{
  options.rhen.services.mihomo-router = {
    enable = lib.mkEnableOption "mihomo eBPF 透明软路由";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."mihomo-config" = {
      sopsFile = snowveil.projectSource + "/secrets/mihomo.yaml";
      key = "";
      owner = "root";
      mode = "0400";
    };

    networking.firewall.allowedTCPPorts = [
      7890
      9090
    ];
    networking.firewall.extraCommands = ''
      ${pkgs.iptables}/bin/iptables -I nixos-fw 1 -i br0 -m mark ! --mark 0 -j nixos-fw-accept
    '';

    systemd.services.mihomo-router = {
      description = "mihomo eBPF 透明软路由";
      after = [
        "network-online.target"
        "sops-install-secrets.service"
      ];
      wants = [ "network-online.target" ];
      requires = [ "sops-install-secrets.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre = mergeScript;
        ExecStart = "${lib.getExe package} -d /var/lib/mihomo -f /run/mihomo-router/config.yaml";
        User = "root";
        Group = "root";
        RuntimeDirectory = "mihomo-router";
        RuntimeDirectoryMode = "0700";
        StateDirectory = "mihomo";
        UMask = "0077";
        Restart = "on-failure";
        LimitMEMLOCK = "infinity";
      };
    };
  };
}
