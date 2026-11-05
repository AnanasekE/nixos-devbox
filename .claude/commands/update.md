---
description: Update flake inputs (nixpkgs, home-manager, Claude Code) and apply
---
1. Note current versions: `nix flake metadata --json | jq '.locks.nodes | with_entries(.value |= .locked.lastModified?)'` and `claude --version`.
2. `nix flake update`.
3. `nh os build`. Summarize the `nvd` diff: kernel, claude-code, neovim, toolchains, anything removed.
4. Ask before `nh os switch`.
5. After switching: `systemctl --failed`, `claude --version`.
6. Commit `flake.lock`: `devbox: update inputs`.
