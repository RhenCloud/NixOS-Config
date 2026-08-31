{
  lib,
  inputs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.hmOpenAgent;
in
{
  options.rhencloud.hmOpenAgent.enable = mkEnableOption "opencode agent config";
  config = mkIf cfg.enable {
    xdg.configFile = {
      # "opencode/oh-my-openagent.jsonc".text = builtins.toJSON {
      #   agents = {
      #     atlas.model = "voidswitch/glm-4.7-flash-cf";
      #     hephaestus.model = "voidswitch/claude-opus-4-8";
      #     oracle.model = "voidswitch/claude-opus-4-8";
      #     prometheus.model = "voidswitch/glm-4.7-flash-cf";
      #     sisyphus.model = "voidswitch/claude-opus-4-8";
      #   };
      #   categories = {
      #     "visual-engineering".model = "voidswitch/claude-opus-4-8";
      #   };
      # };

      "opencode/AGENTS.md" = {
        source = ./AGENTS.md;
        force = true;
      };

      "opencode/agents/code-reviewer.md".source = ./agents/code-reviewer.md;
      "opencode/agents/security-auditor.md".source = ./agents/security-auditor.md;
      "opencode/agents/docs-writer.md".source = ./agents/docs-writer.md;
      "opencode/agents/explorer.md".source = ./agents/explorer.md;
      "opencode/agents/git-helper.md".source = ./agents/git-helper.md;

      "opencode/skills/code-review-skill/SKILL.md".source = ./skills/code-review-skill/SKILL.md;
      "opencode/skills/frontend-design/SKILL.md".source = ./skills/frontend-design/SKILL.md;
      "opencode/skills/frontend-design/LICENSE.txt".source = ./skills/frontend-design/LICENSE.txt;
      "opencode/skills/nix-flakes-env/SKILL.md".source = ./skills/nix-flakes-env/SKILL.md;

      "opencode/plugins/worktree.ts".source = "${inputs.opencode-worktree}/src/plugin/worktree.ts";
      "opencode/plugins/worktree".source = "${inputs.opencode-worktree}/src/plugin/worktree";
      "opencode/plugins/kdco-primitives".source =
        "${inputs.opencode-worktree}/src/plugin/kdco-primitives";
    };
  };
}
