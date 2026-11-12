# Agent Guidance

## Project
tab-to-find is a Zsh plugin that uses fd and fzf for interactive path search and completion.

## Engineering rules
- Preserve Zsh semantics, shell quoting, spaces, Unicode, and supported command behavior.
- Normal search excludes hidden and ignored entries. Those require explicit opt-in.
- Avoid unbounded filesystem traversal and avoid following symlinks without a clear reason.
- Keep candidate generation, fzf selection, command-line mutation, and ZLE redisplay separately understandable.
- Never claim Terminal.app latency was verified unless tested in macOS Terminal.app.
- Do not restore historical reverted commits without understanding why they were reverted.

## Validation
- Run Zsh syntax checks when Zsh is available.
- Run tests/check-plugin.zsh.
- Verify trailing slashes, file paths, spaces, Unicode, and single/multiple result behavior.
- Measure fd traversal, fzf interaction, and post-selection rendering separately.
- Document environmental limitations honestly.

## Change workflow
- Work on a feature branch created from the latest main.
- Keep changes scoped and update README usage documentation.
