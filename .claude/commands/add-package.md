---
description: Add a system package or NixOS module to the devbox and apply it
argument-hint: <package or service>
---
Add `$ARGUMENTS` to this machine.

1. Decide the right place:
   - Needed only by one project → stop and suggest a dev shell instead (`shells.nix` or a project flake).
   - A NixOS module exists (`programs.<name>` / `services.<name>`) → use the module.
   - Otherwise → add to `environment.systemPackages` in `hosts/devbox/configuration.nix`.
2. Confirm the attribute exists: `nix eval nixpkgs#<pkg>.meta.description` or `nix search nixpkgs <name>`.
3. Edit, `git add -A`, `nixfmt` the file, `nix flake check`, `nh os build`.
4. Show the `nvd` diff, then run `nh os switch`.
5. Verify it works, then commit: `devbox: add <name>`.
