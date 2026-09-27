{ lib, ... }:

{
  # herdr 配置需要可写：noctalia 的 herdr 模板会把 [theme.custom] 写回该文件。
  # 因此不直接 symlink（只读），改为激活时复制为真实文件；仅当仓库源变化时覆盖。
  home.activation.herdrConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/herdr/config.toml"
    stamp="$HOME/.config/herdr/.config.toml.src"
    if [ ! -e "$target" ] || [ "$(cat "$stamp" 2>/dev/null)" != "${./config.toml}" ]; then
      run mkdir -p "$(dirname "$target")"
      run cp -f ${./config.toml} "$target"
      run chmod u+w "$target"
      printf '%s' "${./config.toml}" > "$stamp"
    fi
  '';
}
