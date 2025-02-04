{ pkgs, lib, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/minimal.nix")
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi3;
  boot.initrd.availableKernelModules = lib.mkOverride 0 [ ];
  boot.supportedFilesystems = lib.mkOverride 0 [ ];

  sdImage.compressImage = false;


  my.hardware.networking = {
    enable = true;
    hostname = "blackberry";
    domain = "blackberry.mijn.place";
    block-trackers = true;
  };
}
