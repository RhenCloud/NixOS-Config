{ inputs, stdenvNoCC, ... }:
inputs.rime-keytao.packages.${stdenvNoCC.hostPlatform.system}.default
