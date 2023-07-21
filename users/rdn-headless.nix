{ inputs, config, lib, pkgs, ...}: let
  username = "rdn";
in {
  imports = [ ./headless.nix ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  programs.git.userName = "Sebastiaan-Alvarez-Rodriguez";
  programs.git.userEmail = "sebastiaanalva@gmail.com";

