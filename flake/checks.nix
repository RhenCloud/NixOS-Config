{
  inputs,
  lib,
  ...
}:
let
  root = toString inputs.self;
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

  # 只强制求值 drvPath，不构建 closure —— 比直接构建快几个数量级
  evalDrv = name: drv: pkgs.writeText "eval-${name}" "${drv.drvPath}\n";
in
{
  perSystem = { ... }: { };

  flake.checks.x86_64-linux = {
    # 格式化检查（nixfmt = nixfmt-rfc-style）
    formatting = pkgs.runCommand "check-formatting" { } ''
      mapfile -t files < <(find ${root} -name '*.nix' -type f | sort)
      ${pkgs.nixfmt}/bin/nixfmt --check "''${files[@]}"
      touch $out
    '';

    # statix 静态分析（配置见 statix.toml）
    statix = pkgs.runCommand "check-statix" { } ''
      cd ${root}
      ${pkgs.statix}/bin/statix check .
      touch $out
    '';

    # deadnix 死代码检测（-L 跳过 lambda pattern 名，避免误报 NixOS/HM 模块签名）
    deadnix = pkgs.runCommand "check-deadnix" { } ''
      ${pkgs.deadnix}/bin/deadnix --fail -L ${root}
      touch $out
    '';

    # secrets 扫描（gitleaks，配置见 .gitleaks.toml，--no-git 因 store 中无 .git）
    secrets = pkgs.runCommand "check-secrets" { } ''
      ${pkgs.gitleaks}/bin/gitleaks detect \
        --source ${root} \
        --config ${root}/.gitleaks.toml \
        --no-git \
        --no-banner \
        --exit-code 1
      touch $out
    '';

    # 关键配置求值检查（只 eval drvPath，不构建闭包）
    # 完整求值 nixos-desktop 配置约需 90s，故仅保留一台主机避免 check 过慢
    eval-nixos-desktop = evalDrv "nixos-desktop" inputs.self.nixosConfigurations.nixos-desktop.config.system.build.toplevel;

    # 确认 deploy.nodes 结构齐全（hostname / profiles 字段存在）
    deploy-nodes-schema =
      let
        nodes = inputs.self.deploy.nodes;
        ok =
          (nodes ? nixos-desktop)
          && (nodes ? yc-hk-1)
          && (nodes.yc-hk-1 ? hostname)
          && (nodes.yc-hk-1.profiles ? system)
          && (nodes.yc-hk-1.profiles ? home-rhencloud)
          && (nodes.yc-hk-1.profiles ? home-wyf9);
      in
      if ok then
        pkgs.writeText "deploy-nodes-schema" "ok\n"
      else
        throw "deploy.nodes schema check failed";
  };
}
