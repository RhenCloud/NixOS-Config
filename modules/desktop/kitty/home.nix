{ config, lib, ... }:
with lib;
let
  cfg = config.rhencloud.kitty;
in
{
  options.rhencloud.kitty.enable = mkEnableOption "Kitty terminal";

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      shellIntegration.enableBashIntegration = true;
      enableGitIntegration = true;

      # noctalia 在换壁纸时生成的配色，放在末尾覆盖下方兜底色
      extraConfig = ''
        include themes/noctalia.conf
      '';

      settings = {
        cursor_shape = "beam";
        strip_trailing_spaces = "always";
        enable_audio_bell = "no";
        linux_display_server = "wayland";
        wayland_enable_ime = "yes";
        confirm_os_window_close = 0;
        cursor_trail = 3;
        cursor_trail_decay = "0.1 0.4";
        background = "#282a36";
        foreground = "#f8f8f2";
      };

      # 注意：HM 原样透传键名（生成 "map <key> <action>"），组合键内部不能带空格：
      # "ctrl + shift + e" 会被 kitty 解析成键=ctrl 的坏映射并静默丢弃
      # （报 "Shortcut: ctrl has unknown key"），导致落回 kitty 默认绑定。
      #
      # no_op 的语义（见 kitty 源码 actions.py / BaseDefinition）：
      # 解除 kitty 对该键的拦截、原样透传给内部程序（与 "map <key>" 空动作等价），
      # 不是"吞掉"。吞键要 discard_event，那是另一个动作。
      #
      # kitty_mod 默认 = ctrl+shift，其默认绑定 ctrl+shift+e 是 kitten hints
      # （URL 提取，无匹配时报 "No matches found with pattern: ..."）。
      # 只解绑 hints 这一个键，透传给 herdr（config.toml 里绑定打开 TTT）。
      # ctrl+shift+c / ctrl+shift+v 保持 kitty 默认绑定，不动。
      # 其余 kitty_mod+*（新建窗口/关标签/翻页等）同样不受影响。
      keybindings = {
        "ctrl+shift+e" = "no_op";
        # 兼容 herdr 之外的裸 kitty shell 直接粘贴
        "ctrl+v" = "paste_from_clipboard";
      };
    };
  };
}
