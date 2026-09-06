{
  config,
  lib,
  pkgs,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.git;

  # Global git hooks that refuse unsigned commits. `pre-commit` cannot verify
  # a signature (the commit object does not exist yet) and cannot reliably
  # detect `--no-gpg-sign` on the parent command line, so we enforce at
  # `post-commit` (rolls back with `reset --soft` on failure) and `pre-push`
  # (last line of defence).
  hookLoader = pkgs.writeShellApplication {
    name = "_run-local-hook";
    runtimeInputs = [ pkgs.git ];
    text = ''
      # Chain-loader: run the repo's local .git/hooks/<name> if it exists and
      # is executable. Needed because core.hooksPath shadows per-repo hooks
      # (e.g. transcrypt's pre-commit).
      hook_name="''${1:?hook name required}"
      shift

      git_dir="$(git rev-parse --git-dir 2>/dev/null || true)"
      [[ -n "$git_dir" ]] || exit 0

      local_hook="$git_dir/hooks/$hook_name"
      [[ -x "$local_hook" ]] || exit 0

      exec "$local_hook" "$@"
    '';
  };

  hookPostCommit = pkgs.writeShellApplication {
    name = "post-commit";
    runtimeInputs = [ pkgs.git ];
    text = ''
      # Chain to repo-local post-commit first; ignore its exit code so
      # signature enforcement always runs.
      ${hookLoader}/bin/_run-local-hook post-commit "$@" || true

      # Skip during rebase / cherry-pick / merge / revert – Git rewrites
      # commits during those and resetting mid-flight corrupts state.
      git_dir="$(git rev-parse --git-dir)"
      for marker in rebase-merge rebase-apply CHERRY_PICK_HEAD MERGE_HEAD REVERT_HEAD; do
        if [[ -e "$git_dir/$marker" ]]; then
          exit 0
        fi
      done

      commit="$(git rev-parse HEAD)"

      if git verify-commit --raw "$commit" >/dev/null 2>&1; then
        exit 0
      fi

      cat >&2 <<EOF
      ========================================================================
        ERROR: commit ''${commit:0:12} is not signed (or the signature is invalid).
        Unsigned commits are forbidden by the global post-commit hook.

        The commit will be rolled back with 'git reset --soft HEAD^'.
        Your changes stay staged. Re-commit with a signature:

            git commit -S -m "<message>"

        To bypass (discouraged):
            SKIP_SIGN_CHECK=1 git commit ...
      ========================================================================
      EOF

      if [[ "''${SKIP_SIGN_CHECK:-0}" == "1" ]]; then
        echo "SKIP_SIGN_CHECK=1 set; leaving unsigned commit in place." >&2
        exit 0
      fi

      if git rev-parse --verify --quiet HEAD^ >/dev/null; then
        git reset --soft HEAD^
      else
        # Root commit: move HEAD off it but keep index & worktree.
        git update-ref -d HEAD
      fi

      exit 1
    '';
  };

  hookPrePush = pkgs.writeShellApplication {
    name = "pre-push";
    runtimeInputs = [ pkgs.git ];
    text = ''
      # Chain to repo-local pre-push first; abort push if it fails.
      ${hookLoader}/bin/_run-local-hook pre-push "$@"

      zero='0000000000000000000000000000000000000000'
      bad=0

      while read -r _local_ref local_sha _remote_ref remote_sha; do
        # Deleting a remote branch – nothing to verify.
        [[ "$local_sha" == "$zero" ]] && continue

        if [[ "$remote_sha" == "$zero" ]]; then
          commits=$(git rev-list --author="${config.my.user.email}" "$local_sha" --not --remotes)
        else
          commits=$(git rev-list --author="${config.my.user.email}" "$remote_sha".."$local_sha")
        fi

        for c in $commits; do
          if ! git verify-commit --raw "$c" >/dev/null 2>&1; then
            echo "UNSIGNED: $c  $(git log -1 --pretty=%s "$c")" >&2
            bad=1
          fi
        done
      done

      if (( bad )); then
        cat >&2 <<'EOF'
      ========================================================================
        ERROR: push blocked – your commits listed above are not signed.
        Sign them (e.g. `git rebase --exec 'git commit --amend --no-edit -S' <base>`)
        or reset and re-commit with `-S`, then push again.
      ========================================================================
      EOF
        exit 1
      fi

      exit 0
    '';
  };

  gitHooksDir = "${config.home.homeDirectory}/.git-hooks";
in
{
  options.rhencloud.git = {
    enable = mkEnableOption "git, SSH, and GPG";
    sshHostBlocks = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to include SSH host blocks from sops secrets";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      git = {
        enable = true;
        signing = {
          signByDefault = true;
          format = "openpgp";
        };
        settings = {
          gpg.program = "${pkgs.gnupg}/bin/gpg";
          credential.helper = "store";
          commit.gpgsign = true;
          tag.gpgSign = true;
          core.hooksPath = gitHooksDir;
          init.defaultBranch = "main";
          push.autoSetupRemote = true;
          user = {
            name = config.my.user.fullName;
            email = config.my.user.email;
            signingKey = config.my.user.signingKey;
          };
        };
      };
      gpg.enable = true;
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        extraConfig = ''
          AddKeysToAgent no

          Host yc-hk-1
              HostName 83.229.127.169
              Port 45855
              User rhencloud

          Host nixos-desktop
              HostName 10.114.0.5
              User rhencloud
              ProxyJump yc-hk-1
        ''
        + lib.optionalString cfg.sshHostBlocks ''

          Include ${config.sops.templates."ssh-host-blocks".path}
        '';
        settings = {
          "*" = { };
        };
      };
    };

    sops.secrets = lib.mkIf cfg.sshHostBlocks {
      "ssh-tc-discourse" = snowveil.sops.secret {
        source = "host";
        host = "nixos-desktop";
      };
      "ssh-bee-hk-1" = snowveil.sops.secret {
        source = "host";
        host = "nixos-desktop";
      };
    };

    sops.templates."ssh-host-blocks" = lib.mkIf cfg.sshHostBlocks {
      mode = "0644";
      content =
        config.sops.placeholder."ssh-tc-discourse" + "\n\n" + config.sops.placeholder."ssh-bee-hk-1" + "\n";
    };

    home.packages = [ pkgs.gcr ];

    # Global git hooks (see hook derivations above). Symlinked into $HOME so
    # core.hooksPath can point at a stable path outside the Nix store.
    home.file = {
      ".git-hooks/_run-local-hook".source = "${hookLoader}/bin/_run-local-hook";
      ".git-hooks/post-commit".source = "${hookPostCommit}/bin/post-commit";
      ".git-hooks/pre-push".source = "${hookPrePush}/bin/pre-push";
    };

    services.gpg-agent = {
      enable = true;
      enableScDaemon = true;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-gnome3;
      defaultCacheTtl = 86400;
      maxCacheTtl = 604800;
      defaultCacheTtlSsh = 86400;
      maxCacheTtlSsh = 604800;
    };

    home.file.".gnupg/scdaemon.conf".text = ''
      disable-ccid
    '';
  };
}
