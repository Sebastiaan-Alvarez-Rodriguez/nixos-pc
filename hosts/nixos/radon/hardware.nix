{ lib, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/febab299-adca-4f01-96e6-6623add5f4bb";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-f2d9c3a6-b926-46bd-bf78-a6322ae78eb2".device = "/dev/disk/by-uuid/f2d9c3a6-b926-46bd-bf78-a6322ae78eb2";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C6BC-B33C";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];
  # powerManagement.cpuFreqGovernor = lib.mkDefault "powersave"; # seb: use for laptop?

  my.hardware.firmware = {
    enable = true;
    cpu-flavor = "amd";
  };
  my.hardware.graphics.amd = {
    enable = true;
    enableKernelModule = true;
    amdvlk = false;
  };
  my.hardware.networking = {
    enable = true;
    hostname = "radon";
    block-trackers = true;
  };
  my.hardware.sound.pipewire.enable = true;
}
