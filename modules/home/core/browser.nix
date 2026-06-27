{ pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      "bgnkhhnnamicmpeenaelnjfhikgbkllg" # AdGuard
      "ndcooeababalnlpkfedmmbbbgkljhpjf" # 脚本猫
      "lildghglkgcoanblbmenbefhnhifghjj" # BewlyBewly! Ave Mujica
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "jlgkpaicikihijadgifklkbpdajbkhjo" # crxMouse
    ];
    # commandLineArgs = [
    #   "--disable-features=WebRtcAllowInputVolumeAdjustment"
    # ];
  };

  programs.vscode = {
    enable = true;
    # package = pkgs.vscode.fhs;
  };
}
