# nixos-devbox

A NixOS 26.05 dev VM on Proxmox VE that you reach over SSH. It has:
- Dotfiles from [AnanasekE/dotfiles](https://github.com/AnanasekE/dotfiles): zsh, tmux, starship, and nvim (kickstart.nvim submodule).
- A separate toolchain for each project, through Nix flakes and direnv.
- Claude Code installed, with `CLAUDE.md` files and slash commands so it can manage the machine itself.

## Layout
```
flake.nix                    inputs, devbox system, shared devShells, templates
hosts/devbox/configuration.nix   system packages and services
hosts/devbox/hardware.nix        boot loader and disks (matches install.sh)
home/janek.nix               Home Manager: dotfile links, git identity
shells.nix                   shared dev shells: go, node, python, rust, default
templates/                   per-project flake templates
CLAUDE.md                    instructions Claude Code follows inside this repo
.claude/                     Claude Code permissions and slash commands
claude/user-CLAUDE.md        linked to ~/.claude/CLAUDE.md (applies in every project)
install.sh                   run in the installer ISO: partitions the disk and installs
proxmox/create-nixos-vm.sh   run on the Proxmox host: creates the VM
```

## 1. Before installing
1. In `hosts/devbox/configuration.nix`, replace the `AAAAREPLACEME` key with your SSH public key.
2. In `home/janek.nix`, set `user.email`.
3. Push this folder to GitHub as `AnanasekE/nixos-devbox`. It must be public, because `install.sh` clones it without signing in. It contains no secrets.

## 2. Create the VM (on the Proxmox host)
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/AnanasekE/nixos-devbox/main/proxmox/create-nixos-vm.sh)"
```
Defaults: 4 cores, 8 GiB RAM, 80 GiB disk, `local-lvm` storage, bridge `vmbr0`. Override them with environment variables, for example `DISK_STORAGE=local-zfs MEMORY=16384`.

## 3. Install (in the VM console)
```
curl -fsSL https://raw.githubusercontent.com/AnanasekE/nixos-devbox/main/install.sh | sudo bash
```
The script erases `/dev/sda`, installs the system, and gives the repo checkout to `janek`. Then:
1. Detach the ISO on the Proxmox host: `qm set <vmid> --ide2 none,media=cdrom`.
2. Reboot the VM.

## 4. First login
```
ssh janek@<vm-ip>
claude            # sign in: open the printed URL on your laptop
cd ~/nixos-devbox && claude
```
- On first boot, Home Manager clones `~/dotfiles` and TPM. If there was no network at that moment, run `sudo systemctl restart home-manager-janek`.
- In tmux, press `prefix + I` (prefix is Ctrl+a) to install the tmux plugins.
- Open `nvim` once and let lazy.nvim and Mason install everything.

## Managing the VM with Claude Code
Run `claude` inside `~/nixos-devbox`. Claude follows `CLAUDE.md`: edit, check, build, show the diff, switch, commit.

Slash commands:
- `/add-package <name>` adds a system package or service and applies it.
- `/rebuild` checks, builds, shows the diff, switches, and handles failures.
- `/update` updates nixpkgs, Home Manager and Claude Code, and asks before switching.
- `/devshell <path> [lang]` sets up the toolchain for a project.

Claude can check, evaluate and build without asking. It asks before it switches, updates, commits or pushes. `.claude/settings.json` blocks `nix-env` and `sudo rm`.

Claude Code itself is the nixpkgs `claude-code` package. It updates through `/update` or `nix flake update`, not through its own updater.

## Shell aliases
- `rebuild`: `nixos-rebuild switch` from `~/nixos-devbox`
- `rebuild-test`: activate the new config without adding a boot entry
- `rebuild-update`: update flake inputs, then switch
- `nh os switch`: same as `rebuild`, with a package diff

## Project toolchains
Use a flake committed to the project repo:
```
cd ~/projects/myapp
nix flake init -t ~/nixos-devbox#go     # or node, python, rust, default
git add flake.nix .envrc && direnv allow
```
Or use a shared shell without changing the repo:
```
echo 'use flake ~/nixos-devbox#go' > .envrc && direnv allow
```
direnv loads the tools when you `cd` into the project, and unloads them when you leave. nvim started inside the project uses the same tools.

## Notes on your dotfiles
- `~/dotfiles` is a normal git checkout. Edits apply right away, without a rebuild. Commit and push from there.
- Only the zsh, tmux, starship and nvim configs are linked. Hyprland, waybar, kitty and gtk are desktop-only.
- `tmux.conf` copies with `pbcopy`, which is macOS-only. Over SSH, `set -g set-clipboard on` plus `bind -T copy-mode-vi y send -X copy-selection-and-cancel` copies to your laptop's clipboard through OSC 52. Neovim 0.10+ uses OSC 52 automatically over SSH.
- `STARSHIP_CONFIG` points to `~/.config/starship/starship.toml`, because that is where your dotfiles keep it.

## Updating the release
When NixOS 26.11 ships:
1. Change `nixos-26.05` to `nixos-26.11` and `release-26.05` to `release-26.11` in `flake.nix` (and in the templates if you want).
2. Run `nix flake update` and `nh os switch`.
3. Do not change `stateVersion`.
