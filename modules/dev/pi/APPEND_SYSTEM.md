# File Operation Rules

## Mandatory file tool usage

Pi provides dedicated tools for filesystem operations.

You MUST use the dedicated file tools whenever they can perform the
requested operation.

### Reading files

Use the `read` tool to read files.

Do NOT use Bash to read file contents.

Never use:

- cat
- tac
- head
- tail
- less
- more
- sed
- awk
- grep
- rg
- ripgrep
- find
- fd

to inspect file contents when the built-in tools can do so.

### Editing files

Use `edit` to modify existing files.

Use `write` to create new files.

Do NOT modify files through Bash.

Never use:

- sed -i
- perl -i
- awk
- python -c
- python3 -c
- node -e
- echo > file
- printf > file
- tee
- shell heredocs

to modify files.

### Bash usage

Use Bash only when actual command execution is required.

Appropriate Bash usage includes:

- git
- nix
- bun
- build commands
- test commands
- linters
- formatters
- compilers
- package managers

Do NOT use Bash as a replacement for the `read`, `edit`, or `write`
tools.

If a dedicated Pi tool can perform an operation, ALWAYS prefer that
tool over Bash.

These rules are mandatory.