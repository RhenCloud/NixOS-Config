# CloudKeyTao 的 Rime 数据包。
#
# 这里**不做任何加工**，只是把 flake input 已经构建好的产物接出来。
# 所有变换（内联 schema、词库改名、删除多方案文件）都发生在
# CloudKeyTao 仓库自己的 scripts/build.sh 里 —— 单一真相。
#
# 之前这里的 rime-keytao 包直接引用上游 xkinput/KeyTao，装进来的产物
# 带 keytao-bj / keytao-cx / keytao-dz 等多个方案，与被 overlay 覆盖的
# keytao.* 文件互相抢，只能靠 activation 里的 rm/sed/ln 打补丁。
# 换成 CloudKeyTao 后这些补丁全部消失。
{ inputs, stdenvNoCC, ... }:
inputs.cloudkeytao.packages.${stdenvNoCC.hostPlatform.system}.rime-data
