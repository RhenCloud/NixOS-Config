let
  pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+/7cpkWShU8aEDBq2StSJRSeVbFvj8BSEP85HEEtYZ";
in
{
  "musicfoxCookie.age".publicKeys = [ pubKey ];
  "people_name.dict.yaml.age".publicKeys = [ pubKey ];
}
