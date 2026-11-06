# nixos-devbox

NixOS flake for the `devbox` VM (Proxmox VE guest). This repo is the single source of truth for the machine. Checkout path on the VM: `~/nixos-devbox`.

## Layout
- `flake.nix` — inputs (nixpkgs `nixos-26.05`, home-manager `release-26.05`, nixpkgs-unstable for `claude-code` only), `nixosConfigurations.devbox`, shared `devShells`, project `templates`.
- `hosts/devbox/configuration.nix` — system: packages, services, users, SSH, Docker, direnv, nix-ld.
- `hosts/devbox/hardware.nix` — boot, disks (labels `boot`/`nixos`), QEMU guest. Change only when the VM hardware changes.
- `home/janek.nix` — Home Manager: dotfile symlinks into `~/dotfiles`, git identity and GitHub credentials.
- `shells.nix` — dev shells usable as `use flake ~/nixos-devbox#<name>`.
- `templates/<name>/` — per-project flake templates (`nix flake init -t ~/nixos-devbox#<name>`). Keep package lists in sync with `shells.nix`.
- `claude/user-CLAUDE.md` — symlinked to `~/.claude/CLAUDE.md`.

## Workflow for any change
1. Edit the Nix files. Prefer the matching NixOS module (`services.*`, `programs.*`) over adding a bare package.
2. `git add -A` — flakes ignore untracked files.
3. Format: `nixfmt <changed files>`.
4. Check: `nix flake check` (fast eval errors), then `nh os build` (builds without activating; shows package diff).
5. Apply: `nh os switch` (or `sudo nixos-rebuild switch --flake .#devbox`).
6. Verify the change (service status, `which <tool>`, etc.).
7. Commit with a message describing the change. Push only when asked.

## Pushing to GitHub
- HTTPS remotes authenticate through `gh`: `programs.git.settings` sets a
  `credential."https://github.com".helper` of `gh auth git-credential`, which answers
  with the token `gh auth login` wrote to `~/.config/gh/hosts.yml`.
- There is no SSH keypair on this box and no keyring, so a remote on `git@github.com:` or a
  host other than github.com has nothing to authenticate with.
- `could not read Username for 'https://github.com'` means the token is gone, not that the
  password is wrong: there is no TTY to prompt on. Check `gh auth status`; the user has to
  run `gh auth login` themselves.
- `gh auth setup-git` cannot help here: it writes the global git config, which is a read-only
  `/nix/store` symlink. The helper belongs in `home/janek.nix`.

## Finding options and packages
- Package exists: `nix search nixpkgs#<name>` or `nix eval nixpkgs#<pkg>.version`.
- Option exists: `nix eval .#nixosConfigurations.devbox.options.<path>.description` or `man configuration.nix`.
- Current value: `nix eval .#nixosConfigurations.devbox.config.<path>`.

## Rollback and debugging
- Failed switch or broken service: `sudo nixos-rebuild switch --rollback`.
- Logs: `journalctl -u <unit> -b --no-pager | tail -100`.
- Home Manager activation: `journalctl -u home-manager-janek -b`.
- Generations: `nixos-rebuild list-generations`. Older ones stay in the boot menu (limit 10).

## Updating
- `nix flake update` then `nh os switch`. Report the `nvd` diff to the user.
- Claude Code updates this way too, but it comes from the `nixpkgs-unstable` input, not 26.05: the stable channel lags upstream badly (2.1.223 vs 2.1.318 in Nov 2026) and the CLI version decides which models `/model` offers. `nix flake update nixpkgs-unstable` is enough for it. `claude update` never works here — the nixpkgs wrapper sets `DISABLE_AUTOUPDATER` and `/nix/store` is read-only.
- Taking a package from unstable mixes glibc versions. The `claude-code` wrapper puts its own `alsa-lib` on `LD_LIBRARY_PATH`, every process Claude Code spawns inherits it, and a 26.05 `ffmpeg` then refuses to start (`version 'GLIBC_2.43' not found`). A dev shell that uses such tools should `unset LD_LIBRARY_PATH` in its `shellHook`.
- Release upgrade (e.g. 26.05 → 26.11): change the `nixpkgs` and `home-manager` input URLs in `flake.nix` (leave `nixpkgs-unstable` alone), do not change `system.stateVersion` / `home.stateVersion`.

## Constraints
- Never edit `system.stateVersion` or `home.stateVersion`.
- Never disable `services.openssh`, remove the user's authorized keys, or set `PasswordAuthentication = true` — that locks the user out of a headless VM.
- Do not touch `hardware.nix` filesystems or bootloader without being asked.
- Ask before: changing firewall rules, adding users, enabling services that listen on the network.
- No secrets in this repo (it may be public). Use `sops-nix` or `agenix` if secrets are needed; ask first.
