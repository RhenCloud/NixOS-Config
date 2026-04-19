{ lib, ... }:
{
  options.rhencloud.primaryUser = lib.mkOption {
    type = lib.types.str;
    default = "rhencloud";
    description = "Primary desktop user account name.";
  };
}
