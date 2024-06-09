{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ../modules/home-manager/river.nix
    ../modules/home-manager/swaybg-dynamic.nix
  ];

  home.packages = with pkgs; [
    gparted
  ];
}
