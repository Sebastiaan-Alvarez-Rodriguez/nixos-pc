{ lib, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/61f45f4e-6610-4dd9-a7e4-ea798bfd3c79";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-2bdc20d3-ed28-4113-bd0d-7c9797d90657".device = "/dev/disk/by-uuid/2bdc20d3-ed28-4113-bd0d-7c9797d90657";

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/D06C-F506";
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
