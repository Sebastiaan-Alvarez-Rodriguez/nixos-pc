{ lib, modulesPath, ... }: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  # imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];

  # fileSystems."/" = { device = "/dev/sda3"; fsType = "ext4"; };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  my.hardware.networking = {
    enable = true;
    hostname = "blackberry";
    domain = "blackberry.mijn.place";
    block-trackers = true;
  };
}
