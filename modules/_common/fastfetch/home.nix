{ config, lib, ... }:
with lib;
let
  cfg = config.rhencloud.fastfetch;
in
{
  options.rhencloud.fastfetch.enable = mkEnableOption "fastfetch";

  config = mkIf cfg.enable {
    # fastfetch 配置需可写：noctalia 的 fastfetch 模板会把取色后的 logo/display 合并写回该文件。
    # 因此不直接 symlink（只读），改为激活时复制为真实文件；仅当仓库源变化时覆盖。
    home.activation.fastfetchConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      target="$HOME/.config/fastfetch/config.jsonc"
      stamp="$HOME/.config/fastfetch/.config.jsonc.src"
      if [ ! -e "$target" ] || [ "$(cat "$stamp" 2>/dev/null)" != "${./config.jsonc}" ]; then
        run mkdir -p "$(dirname "$target")"
        run cp -f ${./config.jsonc} "$target"
        run chmod u+w "$target"
        printf '%s' "${./config.jsonc}" > "$stamp"
      fi
    '';
    programs.fastfetch.enable = true;
  };
}
