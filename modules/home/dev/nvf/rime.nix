{
  pkgs,
  lib,
  ...
}:

let
  luanativeobjects = pkgs.stdenv.mkDerivation {
    name = "luanativeobjects";
    src = pkgs.fetchFromGitHub {
      owner = "Neopallium";
      repo = "LuaNativeObjects";
      rev = "9259044a23d176fff1f5bf6379635f53f377aeef";
      sha256 = "sha256-wdFdvomS395jhG4oeUuaUO/i6KYFX6k+MmiC+B+9o3o=";
    };
    buildInputs = [ pkgs.luajit ];
    buildPhase = "true";
    installPhase = ''
      mkdir -p "$out/bin" "$out/share/lua/5.1"
      substituteInPlace bin/native_objects \
        --replace '/usr/bin/env lua' '${pkgs.luajit}/bin/luajit'
      cp bin/native_objects "$out/bin/"
      chmod +x "$out/bin/native_objects"
      cp *.lua "$out/share/lua/5.1/"
      cp -r native_objects "$out/share/lua/5.1/"
    '';
  };

  rime-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "rime-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "rimeinn";
      repo = "rime.nvim";
      rev = "3822efea8b120662f3695c4eda66d605b070ca57";
      sha256 = "0nh3swbq4cn3gr00w14rd75pkn0s5bnnwjddvn6ggglsawh03fsl";
    };

    buildInputs = with pkgs; [ librime luajit ];
    nativeBuildInputs = with pkgs; [ xmake pkg-config patchelf git luanativeobjects ];

    LUA_PATH = "${luanativeobjects}/share/lua/5.1/?.lua;${luanativeobjects}/share/lua/5.1/?/init.lua;;";

    prePatch = ''
      sed -i -e '/add_requires/d' -e '/add_packages/d' xmake.lua
    '';

    preBuild = ''
      export XMAKE_GLOBALDIR="$NIX_BUILD_TOP/xmake"
      export PATH="${luanativeobjects}/bin:$PATH"
    '';

    buildPhase = ''
      runHook preBuild
      xmake f --yes --includedirs="${pkgs.librime}/include" --linkdirs="${pkgs.librime}/lib" --ldflags="-lrime"
      xmake --yes
      runHook postBuild
    '';

    postInstall = ''
      mkdir -p "$out/lua"
      cp -r lua/* "$out/lua/"
      for pkg in packages/*/lua; do
        [ -d "$pkg" ] && cp -r --no-preserve=mode "$pkg"/* "$out/lua/"
      done
      find build -name "*.so" -exec cp -t "$out/lua/" {} \;
      patchelf --set-rpath "${pkgs.librime}/lib:${pkgs.luajit}/lib" "$out/lua/"*.so 2>/dev/null || true
    '';

    doCheck = false;

    meta = {
      homepage = "https://github.com/rimeinn/rime.nvim";
      description = "Rime input method for Neovim";
      license = lib.licenses.gpl3Only;
    };
  };
in
{
  programs.nvf.settings.vim.extraPlugins.rime-nvim = {
    package = rime-nvim;
    setup = ''
      local Rime = require('rime.nvim.rime').Rime
      local rime = Rime()

      rime:create_autocmds()
      vim.keymap.set('i', '<C-^>', rime:toggle_cb())
      vim.keymap.set('i', '<C-@>', rime:enable_cb())
      vim.keymap.set('i', '<C-_>', rime:disable_cb())
    '';
  };
}
