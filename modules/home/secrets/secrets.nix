let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+/7cpkWShU8aEDBq2StSJRSeVbFvj8BSEP85HEEtYZ";
in {
  "rime-custom-phrases.age".publicKeys = [ user ];
}
