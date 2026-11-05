# Matches the VM made by create-nixos-vm.sh (OVMF/UEFI, VirtIO SCSI)
# and the disk layout from README.md (labels "boot" and "nixos").
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [
    "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "virtio_blk" "sd_mod" "sr_mod"
  ];
  boot.kernelParams = [ "console=tty0" "console=ttyS0,115200" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  zramSwap.enable = true;
  services.fstrim.enable = true;
  networking.useDHCP = lib.mkDefault true;
}
