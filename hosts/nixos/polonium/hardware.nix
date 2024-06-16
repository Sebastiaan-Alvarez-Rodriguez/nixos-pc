{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/83cd7c28-4f5d-4cd6-9007-f095766d2efb";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."luks-36f3a5b8-69af-431f-9899-e922766dde1e".device = "/dev/disk/by-uuid/36f3a5b8-69af-431f-9899-e922766dde1e";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/B137-7B0D";
      fsType = "vfat";
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
    wireless.enable = true;
    hostname = "polonium";
    block-trackers = true;
  };
  my.hardware.sound.pipewire.enable = true;
}
