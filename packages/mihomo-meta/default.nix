{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:

buildGoModule rec {
  pname = "mihomo-meta";
  version = "unstable-2026-08-20";

  src = fetchFromGitHub {
    owner = "liuran001";
    repo = "mihomo";
    rev = "f4b8399280b92691ca5186f914eb316f9d029c81";
    hash = "sha256-Km5ajr9lC7qdZn466AjcDYXRha9N9sd5E2L/AHaRu8A=";
  };

  vendorHash = "sha256-KyJD/0EP+DEQlKlB6o9OGZwLDTjTfVrpn73/Jc8loP8=";

  patches = [ ../../patches/mihomo/tc-legacy-tcp-fallback.patch ];

  excludedPackages = [ "./test" ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/metacubex/mihomo/constant.Version=${version}"
    "-X github.com/metacubex/mihomo/constant.BuildTime=2026-08-20"
  ];

  tags = [
    "with_gvisor"
    "with_ebpf"
  ];

  doCheck = false;

  meta = {
    description = "mihomo 分支：smart 节点优选 + eBPF 透明入站 + Tailscale 网关";
    homepage = "https://github.com/liuran001/mihomo";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "mihomo";
  };
}
