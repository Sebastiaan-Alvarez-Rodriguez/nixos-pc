{ pkgs, lib, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/minimal.nix")
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  boot.initrd.availableKernelModules = lib.mkOverride 0 [ ];
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi3;
  # boot.kernelParams = [ "usbcore.autosuspend=-1" ]; # do not suspend USBs.
  boot.supportedFilesystems = lib.mkOverride 0 [ ];

  sdImage.compressImage = false;

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/feb8e53b-b7f3-40dc-b2c2-f947226bb278";
    fsType = "ext4";
  };

  my.hardware.networking = {
    enable = true;
    hostname = "blackberry";
    domain = "blackberry.mijn.place";
    block-trackers = true;
  };
}
