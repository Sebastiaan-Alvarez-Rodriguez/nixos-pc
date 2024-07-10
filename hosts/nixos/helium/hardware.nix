{ lib, modulesPath, ... }: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/sda"; # seb: TODO remove grub statement here. use 'my.system.boot' in accompany-'default.nix'
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "ohci_pci" "ehci_pci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/67740218-f938-438f-93bf-f124de80afac";
    fsType = "ext4";
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  my.hardware.networking = {
    enable = true;
    hostname = "helium";
    domain = "h.mijn.place";
    block-trackers = true;
  };
}
