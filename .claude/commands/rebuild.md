---
description: Build, diff and apply the current NixOS config
---
1. `git add -A && git status --short`.
2. `nix flake check`. Fix eval errors before continuing.
3. `nh os build`. Summarize the package diff.
4. `nh os switch`.
5. If any unit failed: `systemctl --failed`, read its journal, fix or roll back with `sudo nixos-rebuild switch --rollback`.
6. Report what changed.
