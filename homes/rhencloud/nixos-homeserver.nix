{ lib, ... }: {
  # 此配置生成 homeConfigurations."rhencloud@nixos-homeserver"
  # 继承 homes/rhencloud/default.nix 的基础配置

  rhencloud = {
    # 覆盖默认值
    herdr.enable = false;

    # Homeserver 专属配置
    git = {
      sshHostBlocks = false;
    };
    opencode.enable = true;
    opencode-podman.enable = true;
  };
}
