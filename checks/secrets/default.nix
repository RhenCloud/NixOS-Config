{
  gitleaks,
  lib,
  runCommand,
  self,
  ...
}:
let
  # path flake 会包含本地 .git 与大型 wallpapers 工作树。先在 Nix 层过滤，
  # 避免 gitleaks --no-git 为无关二进制内容消耗数分钟和大量 CPU。
  source = import ../source.nix { inherit lib self; };
in
runCommand "check-secrets" { } ''
  ${gitleaks}/bin/gitleaks detect \
    --source ${source} \
    --config ${source}/.gitleaks.toml \
    --no-git \
    --no-banner \
    --exit-code 1
  touch $out
''
