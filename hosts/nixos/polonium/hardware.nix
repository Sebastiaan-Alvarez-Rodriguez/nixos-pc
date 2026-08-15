{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" "asus-nb-wmi" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/mapper/luks-953bb997-77ce-4b8a-8baa-b1210e478a04";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."luks-953bb997-77ce-4b8a-8baa-b1210e478a04".device = "/dev/disk/by-uuid/953bb997-77ce-4b8a-8baa-b1210e478a04";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/0541-24D0";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave"; # seb: use for laptop?

  my.hardware.firmware = {
    enable = true;
    cpu-flavor = "amd";
  };
  my.hardware.graphics.nvidia = {
    enable = true;
    powermanagement.enable = true;
    powermanagement.finegrained = true;
    prime.offload = true;
    prime.amdgpuBusId = "PCI:4:0:0";
    prime.nvidiaBusId = "PCI:1:0:0";
  };
  my.hardware.networking = {
    enable = true;
    ui.enable = true;
    hostname = "polonium";
    block-trackers = true;
  };
  my.hardware.sound.pipewire.enable = true;
}
