{ inputs, config, lib, pkgs, system, ...}: let
  username = "rdn";
in {
  imports = [ ../rdn/rdn-headless.nix ../rdn/default.nix ];

  home.packages = with pkgs; [ qmk vial ];
}
