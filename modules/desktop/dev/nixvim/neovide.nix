{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
mkIf config.rhencloud.nixvim.enable {

  home.packages = with pkgs; [ neovide ];

  xdg.configFile."neovide/config.toml".text = ''
    font = { size = 14.0, normal = ["Maple Mono NF CN", "Noto Sans Mono CJK SC", "monospace"], features = { Onum = [] } }
    padding_top = 15
    padding_bottom = 10
    padding_left = 15
    padding_right = 15
    corner_radius = 12
    fullscreen = false
    maximized = false
    transparency = 0.92
    blur = true
    animated_windows = true
    window_animation_time = 0.15
    opacity_change_time = 0.2
    cursor_animation_length = 0.08
    cursor_trail_size = 0.3
    cursor_antialiasing = true
    cursor_vfx_mode = "pixiedust"
    cursor_vfx_opacity = 200.0
    cursor_vfx_particle_lifetime = 1.2
    cursor_vfx_particle_density = 7.0
    cursor_vfx_particle_speed = 10.0
    cursor_default_size = 1.0
    cursor_scale_animation = true
    float_corner_radius = 8
    float_shadow = true
    float_blur_amount = 4
    float_opacity = 0.95
    scroll_animate_position = true
    scroll_animation_length = 0.15
    scroll_lines_to_scroll = 8
    vsync = true
    idle = true
  '';
}
