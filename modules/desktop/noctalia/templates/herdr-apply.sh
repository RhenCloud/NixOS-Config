#!/usr/bin/env bash
# 把 noctalia 渲染出的 [theme.custom] 段写入 herdr 配置。
#
# 与上游 apply.sh 的差别：上游只覆盖「配色文件中出现的键」，因此旧版社区模板
# 遗留的 sidebar_bg / active_row_bg / selection_bg 会残留在 config.toml 里，
# 令 `herdr config check` 持续报 unknown key。这里改为整段替换 [theme.custom]，
# 保证结果只包含当前配色文件定义的键。
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
config_file="${HERDR_CONFIG_PATH:-$config_home/herdr/config.toml}"
colors_file="$config_home/herdr/noctalia-colors.toml"

if [ ! -f "$config_file" ]; then
  echo "Error: Herdr config not found at $config_file" >&2
  exit 1
fi

if [ ! -f "$colors_file" ]; then
  echo "Error: rendered Herdr colors not found at $colors_file" >&2
  exit 1
fi

tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

awk '
    function normalized_header(line, value) {
        value = line
        sub(/[[:space:]]*#.*/, "", value)
        gsub(/[[:space:]]/, "", value)
        return value
    }

    function is_header(line) {
        return substr(normalized_header(line), 1, 1) == "["
    }

    function emit_colors(i) {
        for (i = 1; i <= color_lines; i++) {
            print colors[i]
        }
    }

    NR == FNR {
        colors[++color_lines] = $0
        next
    }

    {
        config_lines++
        header = normalized_header($0)

        if (header == "[theme.custom]") {
            custom_sections++
            if (custom_sections > 1) {
                print "Error: multiple [theme.custom] sections in " FILENAME > "/dev/stderr"
                failed = 1
                exit 2
            }
            print
            emit_colors()
            found_custom = 1
            in_custom = 1
            next
        }

        if (is_header($0)) {
            in_custom = 0
        }

        # 跳过旧 [theme.custom] 段内的所有行，整段由配色文件重建
        if (in_custom) {
            next
        }

        print
    }

    END {
        if (failed) {
            exit 2
        }
        if (found_custom) {
            exit 0
        }
        if (config_lines > 0) {
            print ""
        }
        print "[theme.custom]"
        emit_colors()
    }
' "$colors_file" "$config_file" > "$tmp_file"

if ! cmp -s "$config_file" "$tmp_file"; then
  cat "$tmp_file" > "$config_file"
  if command -v herdr >/dev/null 2>&1; then
    herdr server reload-config >/dev/null 2>&1 || true
  fi
fi
