# Cloud Nix Framework 的 context-safe SOPS helper。
# projectRoot 必须保持为 Nix path，不能提前转换成普通字符串。
{ projectRoot }:

rec {
  commonFile = projectRoot + "/secrets/common.yaml";
  hostFile = host: projectRoot + "/secrets/hosts/${host}.yaml";
  defaultFile = host: if host == null then commonFile else hostFile host;

  secret =
    {
      source,
      host ? null,
      name ? null,
    }:
    let
      makeOptions = sopsFile: { inherit sopsFile; };

      wrapName =
        options:
        if name == null then
          options
        else if builtins.isString name && name != "" then
          { sops.secrets.${name} = options; }
        else
          throw "cloud.sops.secret.name 必须是非空字符串";

      staticOptions =
        if source == "common" then
          makeOptions commonFile
        else if source == "host" && host != null then
          makeOptions (hostFile host)
        else
          null;

      dynamicModule =
        { config, ... }:
        let
          hostname = config.networking.hostName;
        in
        wrapName (makeOptions (hostFile hostname));
    in
    if staticOptions != null then
      wrapName staticOptions
    else if source == "host" then
      dynamicModule
    else
      throw "cloud.sops.secret.source 必须是 \"common\" 或 \"host\"";

  mkModule =
    {
      sopsNixModule,
      host ? null,
      defaultSopsFile ? defaultFile host,
    }:
    { ... }:
    {
      imports = [ sopsNixModule ];
      sops = {
        defaultSopsFormat = "yaml";
        inherit defaultSopsFile;
      };
    };
}
