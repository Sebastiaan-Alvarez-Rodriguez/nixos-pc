{ inputs, config, lib, pkgs, ...}: let
  username = "mrs";
in {
  imports = [ ../headless.nix ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  programs.git.userName = "MariskaIJpelaar";
  programs.git.userEmail = "m.m.j.ijpelaar@gmail.com";
}