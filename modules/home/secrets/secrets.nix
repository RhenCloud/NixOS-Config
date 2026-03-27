let
  pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPuthZJ1ELm9QFDDUWBfzdfRZk5JE9iHOLWjU+QQTQbE openpgp:0xA9309E61";
in
{
  # "musicfoxCookie.age".publicKeys = [ pubKey ];
  "people_name.dict.yaml.age".publicKeys = [ pubKey ];
  # "mihomoConfig.yaml.age".publicKeys = [ pubKey ];
}
