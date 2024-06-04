{ lib, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1e2dfeee-90da-4417-9f97-34bd12e61b0a";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-df517c4c-6d0d-484f-bab0-b7d1d186558c".device = "/dev/disk/by-uuid/df517c4c-6d0d-484f-bab0-b7d1d186558c";

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/8343-29CC";
    fsType = "vfat";
  };

  swapDevices = [ ];

  # powerManagement.cpuFreqGovernor = lib.mkDefault "powersave"; # seb: use for laptop?

  my.hardware.firmware.cpu-flavor = "amd";
  my.hardware.graphics.amd = {
    enable = true;
    amdvlk = false;
  };
  my.hardware.networking = {
    enable = true;
    hostname = "radon";
    block-trackers = true;
  };
  my.hardware.sound.pipewire.enable = true;
}
