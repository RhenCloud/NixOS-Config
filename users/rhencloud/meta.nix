# rhencloud 用户的元数据定义
# 框架根据此文件在关联主机上自动生成 users.users.rhencloud 和 users.groups.rhencloud
{
  # 必需：声明此用户关联的主机列表
  hosts = [
    "nixos-desktop"
    "nixos-homeserver"
    "yc-hk-1"
  ];

  # 用户属性（可选，框架自动设置默认值）
  uid = 1000;
  description = "RhenCloud";
  extraGroups = [
    "wheel"
    "networkmanager"
    "docker"
    "podman"
  ];

  # 密码文件来源
  # 以 "/" 开头时视为字面文件路径；否则当作 sops 密钥名
  hashedPasswordSecret = "rhencloud-password";
}
