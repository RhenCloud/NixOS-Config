# 静态元数据：BIOS 虚拟机上的最小 server。
{
  system = "x86_64-linux";
  roles = [ "server" ];
  profiles = [ "server" ];
  home.embed = false;
}
