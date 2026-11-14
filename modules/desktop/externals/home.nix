{ inputs, ... }:
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
    inputs.umbriel.homeModules.default
    inputs.mangowm.hmModules.mango
    inputs.niri.homeModules.niri
    inputs.piri.homeManagerModules.default
    # 注意：CloudKeyTao 不再提供 homeManagerModule。
    # 它只交付一份纯数据（rime-data），怎么装由使用方决定 ——
    # 见 modules/desktop/fcitx5/home.nix 里的 xdg.dataFile。
    # 旧的 inputs.rime-keytao.homeManagerModules.default 已删除，
    # 它那套 rsync + activation 补丁就是“部署太脏”的根源。
    inputs.vicinae.homeManagerModules.default
  ];
}
