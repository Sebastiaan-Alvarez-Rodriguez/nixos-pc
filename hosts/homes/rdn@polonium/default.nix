{ inputs, config, lib, pkgs, system, ...}: let
  username = "rdn";
in {
  imports = [ ../rdn/rdn-headless.nix ../rdn/default.nix ];

  # seb NOTE: stremio does not work as it uses deprecated qt5 webengine software
  # home.packages = with pkgs; [ stremio ];
}
