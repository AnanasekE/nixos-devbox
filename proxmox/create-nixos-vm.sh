#!/usr/bin/env bash
# Create a NixOS VM on a Proxmox VE host.
# Run as root on the PVE node. All settings can be overridden via env vars:
#   VMID=120 NAME=nixos MEMORY=8192 ./create-nixos-vm.sh
set -euo pipefail

# ---- Settings ---------------------------------------------------------------
NIXOS_CHANNEL="${NIXOS_CHANNEL:-nixos-26.05}"        # stable channel
ISO_FLAVOR="${ISO_FLAVOR:-minimal}"                  # minimal | graphical
VMID="${VMID:-$(pvesh get /cluster/nextid)}"
NAME="${NAME:-devbox}"
CORES="${CORES:-4}"
MEMORY="${MEMORY:-8192}"                             # MiB
DISK_SIZE="${DISK_SIZE:-80}"                         # GiB
DISK_STORAGE="${DISK_STORAGE:-local-lvm}"            # storage for VM disks
ISO_STORAGE="${ISO_STORAGE:-local}"                  # storage with 'iso' content
BRIDGE="${BRIDGE:-vmbr0}"
VLAN="${VLAN:-}"                                     # optional VLAN tag
START="${START:-1}"                                  # 1 = start VM after creation

# ---- Checks -----------------------------------------------------------------
[[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 1; }
command -v qm >/dev/null || { echo "qm not found. Run on a Proxmox VE node." >&2; exit 1; }
if qm status "$VMID" &>/dev/null; then
  echo "VMID $VMID already exists." >&2; exit 1
fi
pvesm status -storage "$DISK_STORAGE" &>/dev/null || { echo "Storage $DISK_STORAGE not found." >&2; exit 1; }
pvesm status -storage "$ISO_STORAGE"  &>/dev/null || { echo "Storage $ISO_STORAGE not found." >&2; exit 1; }

# ---- ISO --------------------------------------------------------------------
ISO_NAME="${NIXOS_CHANNEL}-${ISO_FLAVOR}-x86_64-linux.iso"
ISO_URL="https://channels.nixos.org/${NIXOS_CHANNEL}/latest-nixos-${ISO_FLAVOR}-x86_64-linux.iso"
ISO_VOLID="${ISO_STORAGE}:iso/${ISO_NAME}"
ISO_PATH="$(pvesm path "$ISO_VOLID")"

if [[ ! -f "$ISO_PATH" ]]; then
  echo "Downloading $ISO_URL"
  tmp="${ISO_PATH}.part"
  curl -fL --retry 3 -o "$tmp" "$ISO_URL"
  echo "Verifying checksum"
  expected="$(curl -fsSL "${ISO_URL}.sha256" | awk '{print $1}')"
  actual="$(sha256sum "$tmp" | awk '{print $1}')"
  if [[ "$expected" != "$actual" ]]; then
    rm -f "$tmp"; echo "Checksum mismatch." >&2; exit 1
  fi
  mv "$tmp" "$ISO_PATH"
else
  echo "ISO present: $ISO_PATH"
fi

# ---- VM ---------------------------------------------------------------------
NET="virtio,bridge=${BRIDGE}"
[[ -n "$VLAN" ]] && NET+=",tag=${VLAN}"

echo "Creating VM $VMID ($NAME)"
qm create "$VMID" \
  --name "$NAME" \
  --ostype l26 \
  --machine q35 \
  --bios ovmf \
  --efidisk0 "${DISK_STORAGE}:1,efitype=4m,pre-enrolled-keys=0" \
  --cpu host \
  --cores "$CORES" \
  --memory "$MEMORY" \
  --balloon 0 \
  --onboot 1 \
  --scsihw virtio-scsi-single \
  --scsi0 "${DISK_STORAGE}:${DISK_SIZE},iothread=1,discard=on,ssd=1" \
  --ide2 "${ISO_VOLID},media=cdrom" \
  --boot "order=scsi0;ide2" \
  --net0 "$NET" \
  --agent enabled=1,fstrim_cloned_disks=1 \
  --serial0 socket \
  --vga std \
  --rng0 source=/dev/urandom \
  --tags "nixos;dev"

if [[ "$START" == "1" ]]; then
  qm start "$VMID"
  echo "VM $VMID started. Open the console in the PVE web UI to install."
else
  echo "VM $VMID created. Start with: qm start $VMID"
fi

cat <<EOF

Next, in the VM console (Proxmox > VM $VMID > Console):
  curl -fsSL https://raw.githubusercontent.com/AnanasekE/nixos-devbox/main/install.sh | sudo bash

After install, detach the ISO and reboot:
  qm set $VMID --ide2 none,media=cdrom
EOF
