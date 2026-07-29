{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my = {
    user = {
      name = mkOption {
        type = types.str;
        default = "rhencloud";
      };
      fullName = mkOption {
        type = types.str;
        default = "RhenCloud";
      };
      email = mkOption {
        type = types.str;
        default = "i@rhen.cloud";
      };
      signingKey = mkOption {
        type = types.str;
        default = "A574A617378C4E0B";
      };
    };

    host = {
      name = mkOption {
        type = types.str;
        default = "nixos-desktop";
      };
      system = mkOption {
        type = types.str;
        default = "x86_64-linux";
      };
    };

    domain = mkOption {
      type = types.str;
      default = "rhen.cloud";
    };

    stateVersion = mkOption {
      type = types.str;
      default = "26.15";
    };

    editor = mkOption {
      type = types.str;
      default = "hx";
    };

    terminal = mkOption {
      type = types.str;
      default = "kitty";
    };

    browser = {
      default = mkOption {
        type = types.str;
        default = "zen";
      };
    };

    permittedInsecurePackages = mkOption {
      type = types.listOf types.str;
      default = [
        "electron-39.8.10"
        "pnpm-9.15.9"
        "pnpm-10.29.2"
      ];
    };

    allowUnfree = mkOption {
      type = types.bool;
      default = true;
    };
  };
}
