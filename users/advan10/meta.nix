# advan10 用户的元数据定义
{
  # 必需：声明此用户关联的主机列表
  hosts = [ "yc-hk-1" ];

  # 用户属性
  uid = 1002;
  description = "advan10";
  extraGroups = [
    "wheel"
  ];

  # 密码文件来源
  hashedPasswordSecret = "advan10-password";
}
