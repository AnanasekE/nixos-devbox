#!/usr/bin/env bash
# Run inside the NixOS installer ISO (VM console) as root:
#   curl -fsSL https://raw.githubusercontent.com/AnanasekE/nixos-devbox/main/install.sh | sudo bash
# WIPES the target disk, then installs nixosConfigurations.devbox from this repo.
set -euo pipefail

REPO="${REPO:-https://github.com/AnanasekE/nixos-devbox.git}"
DISK="${DISK:-/dev/sda}"
USER_NAME="${USER_NAME:-janek}"
export NIX_CONFIG="experimental-features = nix-command flakes"

[[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 1; }
[[ -b "$DISK" ]] || { echo "Disk $DISK not found. Set DISK=/dev/..." >&2; exit 1; }

lsblk "$DISK"
read -r -p "ERASE ALL DATA on $DISK? Type 'yes': " ok </dev/tty
[[ "$ok" == "yes" ]] || { echo "Aborted."; exit 1; }

# ---- Partition: 1 GiB ESP + ext4 root -----------------------------------------
wipefs -af "$DISK"
parted -s "$DISK" -- mklabel gpt \
  mkpart ESP fat32 1MiB 1GiB set 1 esp on \
  mkpart root ext4 1GiB 100%
udevadm settle
PART1="$(lsblk -lnpo NAME "$DISK" | sed -n 2p)"
PART2="$(lsblk -lnpo NAME "$DISK" | sed -n 3p)"
mkfs.fat -F 32 -n boot "$PART1"
mkfs.ext4 -F -L nixos "$PART2"
udevadm settle

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot

# ---- Fetch config and install --------------------------------------------------
FLAKE="/mnt/home/${USER_NAME}/nixos-devbox"
mkdir -p "$(dirname "$FLAKE")"
nix shell nixpkgs#git -c git clone "$REPO" "$FLAKE"

if grep -q 'AAAAREPLACEME' "$FLAKE/hosts/devbox/configuration.nix"; then
  echo "WARNING: authorized SSH key is still the placeholder. You will not be able to SSH in." >&2
  read -r -p "Continue anyway? Type 'yes': " ok </dev/tty
  [[ "$ok" == "yes" ]] || exit 1
fi

nixos-install --flake "${FLAKE}#devbox" --no-root-passwd

# Hand the checkout to the user (uid is assigned during install).
nixos-enter --root /mnt -c "chown -R ${USER_NAME}:users /home/${USER_NAME}"

echo
echo "Install done. Next:"
echo "  1. In Proxmox: qm set <vmid> --ide2 none,media=cdrom"
echo "  2. reboot"
echo "  3. ssh ${USER_NAME}@<vm-ip>   (IP is shown in Proxmox > VM > Summary)"
