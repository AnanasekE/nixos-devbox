# Machine context (devbox)

This machine is `devbox`, a NixOS 26.05 VM on Proxmox VE, reached over SSH. User: `janek`.

## Rules
- Do not install software with `nix-env`, `nix profile`, `pip install --user`, `npm -g`, `cargo install`, `go install` into global paths, or curl-pipe installers. They break reproducibility.
- Project tools go in that project's dev shell (`flake.nix` + `.envrc` with `use flake`). See "Project tool setup".
- System tools, services and users go in the NixOS config at `~/nixos-devbox`. See that repo's CLAUDE.md.
- One-off tool for a single command: `nix run nixpkgs#<pkg> -- <args>` or `nix shell nixpkgs#<pkg>`.
- Prebuilt Linux binaries work because `programs.nix-ld` is enabled.
- `sudo` needs no password. Run `sudo` only for `nixos-rebuild`/`nh os`, `systemctl`, and `journalctl` unless asked.

## Project tool setup
1. Project already has `flake.nix`: ensure `.envrc` contains `use flake`, then run `direnv allow`.
2. No flake, and the repo may get one: `nix flake init -t ~/nixos-devbox#<go|node|python|rust|default>`, edit `packages`, `git add flake.nix .envrc`, `direnv allow`.
3. No flake, and the repo must not get one: `echo 'use flake ~/nixos-devbox#<shell>' > .envrc && direnv allow`. Add `.envrc` and `.direnv/` to `.git/info/exclude`.
4. Flakes only see git-tracked files. Run `git add` on new `flake.nix` before `nix develop`.
5. Verify with `nix develop -c <tool> --version`.

## Dotfiles
- `~/dotfiles` is a git checkout of github.com/AnanasekE/dotfiles, symlinked into `$HOME` by Home Manager.
- Edit files in `~/dotfiles` directly; changes apply without a rebuild. Commit and push from there.
- Neovim config is the `nvim/.config/nvim` submodule (github.com/AnanasekE/kickstart.nvim).
