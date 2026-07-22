{
  inputs,
  ...
}:
{
  xdg.configFile = {
    "opencode/oh-my-openagent.jsonc".text = builtins.toJSON {
      agents = {
        atlas.model = "voidswitch/glm-4.7-flash-cf";
        hephaestus.model = "voidswitch/claude-opus-4-8";
        oracle.model = "voidswitch/claude-opus-4-8";
        prometheus.model = "voidswitch/glm-4.7-flash-cf";
        sisyphus.model = "voidswitch/claude-opus-4-8";
      };
      categories = {
        "visual-engineering".model = "voidswitch/claude-opus-4-8";
      };
    };

    "opencode/AGENTS.md" = {
      source = ./AGENTS.md;
      force = true;
    };

    "opencode/skills/code-review-skill/SKILL.md".source = ./skills/code-review-skill/SKILL.md;
    "opencode/skills/frontend-design/SKILL.md".source = ./skills/frontend-design/SKILL.md;
    "opencode/skills/frontend-design/LICENSE.txt".source = ./skills/frontend-design/LICENSE.txt;
    "opencode/skills/nix-flakes-env/SKILL.md".source = ./skills/nix-flakes-env/SKILL.md;

    "opencode/plugins/worktree.ts".source = "${inputs.opencode-worktree}/src/plugin/worktree.ts";
    "opencode/plugins/worktree".source = "${inputs.opencode-worktree}/src/plugin/worktree";
    "opencode/plugins/kdco-primitives".source = "${inputs.opencode-worktree}/src/plugin/kdco-primitives";

    "opencode/package.json".text = builtins.toJSON {
      dependencies = {
        "jsonc-parser" = "*";
      };
    };
  };
}
