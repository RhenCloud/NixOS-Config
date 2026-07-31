default:
  @just --list

deploy host:
  deploy -s .#{{host}} -- --extra-deprecated-features broken-string-escape

update:
  nix flake update

os action:
  sudo nixos-rebuild {{action}} --flake .

home action:
  home-manager {{action}} --flake .
