default:
  @just --list

deploy *target:
  @if [ -z "{{target}}" ]; then \
    deploy -s . -- --extra-deprecated-features broken-string-escape; \
  else \
    deploy -s .#{{target}} -- --extra-deprecated-features broken-string-escape; \
  fi

update:
  nix flake update

os action:
  sudo nixos-rebuild {{action}} --flake .

home action:
  home-manager {{action}} --flake .
