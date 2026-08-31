{ inputs, ... }:
{
  imports = [
    inputs.noctalia-v4.homeModules.default
    inputs.mangowm.hmModules.mango
    inputs.niri.homeModules.niri
    inputs.piri.homeManagerModules.default
    inputs.nixvim.homeModules.nixvim
    inputs.rime-keytao.homeManagerModules.default
    inputs.vicinae.homeManagerModules.default
    inputs.stylix.homeModules.stylix
  ];
}
