{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt5,
  fcitx5,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "im-emoji-picker";
  version = "1.1.1-unstable-2026-01-03";

  src = fetchFromGitHub {
    owner = "GaZaTu";
    repo = "im-emoji-picker";
    rev = "556a36958ee4295121ec62c1320d0105c12f7071";
    hash = "sha256-6yXPbbClsyMuzKIiU3IHg+UR0UtdzMFj3NzpV/Hzz6E=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt5.qtbase
  ];

  buildInputs = [
    fcitx5
    qt5.qtbase
  ];

  # 只构建 fcitx5 版本，跳过 IBus/GLib 依赖。
  cmakeFlags = [
    (lib.cmakeBool "ONLY_FCITX5" true)
    (lib.cmakeBool "ONLY_IBUS" false)
  ];

  # 上游 CMakeLists 把安装前缀硬编码为 /usr，且把 fcitx5 插件放到 lib64。
  # 这里改用 Nix 的 $out 目录布局，并把插件放进 fcitx5 的 addon 搜索路径 lib/fcitx5。
  postPatch = ''
      sed -i \
        -e '/^set(CMAKE_INSTALL_PREFIX \/usr)$/d' \
        -e 's|/lib64/fcitx5|/lib/fcitx5|' \
        -e 's|/usr/share/icons/hicolor|share/icons/hicolor|' \
        CMakeLists.txt

      # gui_main 在线程里构造 QApplication，会继承 fcitx5 进程的环境变量：
      #   * QT_IM_MODULE=fcitx 会让 Qt5 在 fcitx5 自身进程内加载 fcitx5 的 Qt5
      #     输入法插件，造成递归初始化并崩溃（libfcitx5platforminputcontextplugin）；
      #   * 登录环境的 QT_PLUGIN_PATH 往往不含 qtwayland 平台插件，缺失时 Qt5
      #     qFatal 直接终止整个 fcitx5 进程。
      # 因此在创建 QApplication 之前修正这两项环境变量。
      substituteInPlace src/EmojiPickerWindow.cpp \
        --replace-fail 'QApplication app{argc, argv};' \
        'qputenv("QT_PLUGIN_PATH", QByteArray("${qt5.qtwayland.bin}/${qt5.qtbase.qtPluginPrefix}") + ":" + qgetenv("QT_PLUGIN_PATH"));
    qunsetenv("QT_IM_MODULE");

    QApplication app{argc, argv};'
  '';

  # 不使用 wrapQtAppsHook：这是一个被 fcitx5 进程 dlopen 的共享库，
  # 无法通过 wrapper 注入 Qt 插件路径。
  dontWrapQtApps = true;

  # 让 fcitx5-with-addons 的 wrapper 把 Qt5 运行库加进 LD_LIBRARY_PATH。
  extraLdLibraries = [ qt5.qtbase ];

  # 上游的 install 规则会把文件写到 /usr，直接手工安装到 $out。
  installPhase = ''
    runHook preInstall

    install -Dm755 fcitx5imemojipicker.so \
      "$out/lib/fcitx5/fcitx5imemojipicker.so"

    install -Dm644 ${finalAttrs.src}/fcitx5-addon.conf \
      "$out/share/fcitx5/addon/fcitx5imemojipicker.conf"
    substituteInPlace "$out/share/fcitx5/addon/fcitx5imemojipicker.conf" \
      --replace-fail 'Version=' "Version=${finalAttrs.version}"

    install -Dm644 ${finalAttrs.src}/src/res/im-emoji-picker_32x32.png \
      "$out/share/icons/hicolor/32x32/apps/im-emoji-picker.png"

    runHook postInstall
  '';

  meta = {
    description = "Emoji picker addon for Fcitx5";
    homepage = "https://github.com/GaZaTu/im-emoji-picker";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
