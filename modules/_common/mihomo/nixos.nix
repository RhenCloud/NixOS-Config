{
  config,
  inputs,
  lib,
  pkgs,
  snowveil,
  ...
}:
let
  cfg = config.rhen.services.mihomo;
  package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.mihomo-meta;
  overrideFile = pkgs.writeText "mihomo-ebpf-override.yaml" (builtins.readFile ./override.yaml);
  mergeScript = pkgs.writeShellScript "mihomo-merge" ''
    ${lib.getExe pkgs.yq-go} ea '. as $item ireduce ({}; . * $item)' \
      ${config.sops.secrets."mihomo-config".path} ${overrideFile} \
      > /run/mihomo/config.yaml
  '';
in
{
  options.rhen.services.mihomo = {
    enable = lib.mkEnableOption "mihomo proxy";
    ebpf = lib.mkEnableOption "mihomo eBPF local 入站与 CN-IP 内核绕过";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."mihomo-config" = {
      sopsFile = snowveil.projectSource + "/secrets/mihomo.yaml";
      key = "";
      owner = "root";
      mode = "0400";
    };

    environment.etc."mihomo/config.yaml".source = config.sops.secrets."mihomo-config".path;

    systemd.services.mihomo = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
      serviceConfig = {
        ExecStart = lib.mkForce (
          if cfg.ebpf then
            "${lib.getExe package} -d /var/lib/mihomo -f /run/mihomo/config.yaml"
          else
            "${pkgs.mihomo}/bin/mihomo -d /var/lib/mihomo -f /etc/mihomo/config.yaml"
        );
      }
      // lib.optionalAttrs cfg.ebpf {
        ExecStartPre = mergeScript;
        RuntimeDirectory = "mihomo";
        RuntimeDirectoryMode = "0700";
        CapabilityBoundingSet = lib.mkForce [
          "CAP_NET_ADMIN"
          "CAP_BPF"
          "CAP_NET_RAW"
          "CAP_SYS_ADMIN"
        ];
        AmbientCapabilities = lib.mkForce [
          "CAP_NET_ADMIN"
          "CAP_BPF"
          "CAP_NET_RAW"
          "CAP_SYS_ADMIN"
        ];
        LimitMEMLOCK = "infinity";
      };
    };
  };
}
