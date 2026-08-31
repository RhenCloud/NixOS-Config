{ self, writeText, ... }:
let
  nodes = self.deploy.nodes;
  expectedNodes = [
    "nixos-desktop"
    "nixos-homeserver"
    "yc-hk-1"
  ];
  expectedYcProfiles = [
    "home-advan10"
    "home-rhencloud"
    "home-wyf9"
    "system"
  ];
  hasExpectedNodes = builtins.all (name: nodes ? ${name}) expectedNodes;
  hasExpectedYcProfiles = builtins.all (name: nodes.yc-hk-1.profiles ? ${name}) expectedYcProfiles;
  structureOk =
    hasExpectedNodes
    && (nodes.yc-hk-1 ? hostname)
    && hasExpectedYcProfiles
    &&
      nodes.yc-hk-1.profilesOrder == [
        "home-rhencloud"
        "home-wyf9"
        "home-advan10"
        "system"
      ]
    && (nodes.nixos-desktop.profiles ? system)
    && (nodes.nixos-homeserver.profiles ? system);

  # 结构正确后再强制所有部署 profile 求值。移除 drvPath 字符串上下文，
  # 让检查保持轻量，同时避免 GC 后陈旧 eval cache 引用已删除的 .drv。
  profileDrvs = builtins.mapAttrs (_name: path: builtins.unsafeDiscardStringContext path.drvPath) {
    nixos-desktop = nodes.nixos-desktop.profiles.system.path;
    nixos-homeserver = nodes.nixos-homeserver.profiles.system.path;
    yc-hk-1-system = nodes.yc-hk-1.profiles.system.path;
    yc-hk-1-home-rhencloud = nodes.yc-hk-1.profiles.home-rhencloud.path;
    yc-hk-1-home-wyf9 = nodes.yc-hk-1.profiles.home-wyf9.path;
    yc-hk-1-home-advan10 = nodes.yc-hk-1.profiles.home-advan10.path;
  };
in
if structureOk then
  builtins.deepSeq profileDrvs (writeText "deploy-nodes-schema" "${builtins.toJSON profileDrvs}\n")
else
  throw "deploy.nodes 结构检查失败"
