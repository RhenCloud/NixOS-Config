{
  # 服务器角色会设置这些模块声明的选项。
  requires = [
    "_common.cloudflared"
    "_common.identity"
    "_common.locale"
    "_common.nix"
    "_common.packages"
    "_common.shells"
    "server.postgresql"
  ];
}
