{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.displayManagers;

  sddm-astronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "astronaut";
    themeConfig = {
      HeaderText = "";
      HeaderTextColor = "#f8f8f2";
      DateTextColor = "#bd93f9";
      TimeTextColor = "#f8f8f2";

      FormBackgroundColor = "#21222c";
      DimBackgroundColor = "#282a36";
      BackgroundColor = "#21222c";

      LoginFieldBackgroundColor = "#282a36";
      PasswordFieldBackgroundColor = "#282a36";
      LoginFieldTextColor = "#f8f8f2";
      PasswordFieldTextColor = "#f8f8f2";
      UserIconColor = "#f8f8f2";
      PasswordIconColor = "#f8f8f2";

      PlaceholderTextColor = "#6272a4";
      WarningColor = "#44475a";

      LoginButtonTextColor = "#f8f8f2";
      LoginButtonBackgroundColor = "#44475a";
      SystemButtonsIconsColor = "#f8f8f2";
      SessionButtonTextColor = "#f8f8f2";
      VirtualKeyboardButtonTextColor = "#f8f8f2";

      DropdownTextColor = "#f8f8f2";
      DropdownSelectedBackgroundColor = "#44475a";
      DropdownBackgroundColor = "#21222c";

      HighlightTextColor = "#f8f8f2";
      HighlightBackgroundColor = "#44475a";
      HighlightBorderColor = "#44475a";

      HoverUserIconColor = "#bd93f9";
      HoverPasswordIconColor = "#bd93f9";
      HoverSystemButtonsIconsColor = "#bd93f9";
      HoverSessionButtonTextColor = "#bd93f9";
      HoverVirtualKeyboardButtonTextColor = "#bd93f9";

      PartialBlur = "true";
      FormPosition = "center";
      HaveFormBackground = "false";
      FontSize = "16";
      RoundCorners = "20";

      ForceLastUser = "true";
      PasswordFocus = "true";
      HideCompletePassword = "true";
      UseRealName = "true";
    };
  };
in
{
  options.rhencloud.displayManagers.enable = mkEnableOption "display manager";

  config = mkIf cfg.enable {
    services.xserver.enable = true;

    services.displayManager = {
      sddm = {
        enable = true;
        package = pkgs.kdePackages.sddm;
        extraPackages = with pkgs.kdePackages; [
          qtmultimedia
          qtsvg
          qtvirtualkeyboard
        ];
        theme = "sddm-astronaut-theme";
        settings = {
          Theme.CursorTheme = "BreezeX-RosePine-Linux";
        };
      };
      defaultSession = "niri";
      autoLogin = {
        enable = true;
        user = "rhencloud";
      };
    };

    services.displayManager.sessionPackages = with pkgs; [
      niri
    ];

    environment.systemPackages = with pkgs; [
      sddm-astronaut
      rose-pine-cursor
    ];
  };
}
