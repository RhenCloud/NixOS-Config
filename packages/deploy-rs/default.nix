{ inputs, stdenvNoCC, ... }:
inputs.deploy-rs.packages.${stdenvNoCC.hostPlatform.system}.deploy-rs
