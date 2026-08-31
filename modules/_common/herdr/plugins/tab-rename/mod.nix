{
  inputs,
  pkgs,
  ...
}:

{
  rhencloud.herdrPlugins.tab-rename = {
    id = "rhencloud.tab-rename";
    package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-tab-rename;
  };

  xdg.configFile."fish/conf.d/94-herdr-tab-rename.fish".text = ''
    function __herdr_rename_tab_on_pwd --on-variable PWD
      set -q HERDR_ENV; or return
      herdr-tab-rename on-pwd
    end

    function ssh --wraps="ssh"
      if set -q HERDR_ENV
        set -l host ""
        for arg in $argv
          if not string match -q -- '-*' "$arg"
            set host $arg
            break
          end
        end
        if test -n "$host"
          herdr-tab-rename on-ssh --host "$host"
        end
      end
      command ssh $argv
      set -l ssh_exit $status
      if set -q HERDR_ENV
        herdr-tab-rename on-pwd
      end
      return $ssh_exit
    end

    function opencode --wraps="opencode"
      if set -q HERDR_ENV
        set -l proj (basename "$PWD")
        test "$PWD" = "$HOME"; and set proj "~"
        herdr-tab-rename opencode-before --project "$proj"
        command opencode $argv
        set -l oc_exit $status
        herdr-tab-rename opencode-after --project "$proj" --exit-code $oc_exit
        return $oc_exit
      else
        command opencode $argv
      end
    end

    __herdr_rename_tab_on_pwd
  '';
}
