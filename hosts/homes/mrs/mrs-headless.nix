{ inputs, config, lib, pkgs, ...}: let
  username = "mrs";
in {
  imports = [ ../headless.nix ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  programs.fish.interactiveShellInit = ''
      tabs -4
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
  '';

  programs.git.userName = "MariskaIJpelaar";
  programs.git.userEmail = "m.m.j.ijpelaar@gmail.com";

  programs.ssh = {
    matchBlocks = let 
      setDefaults = defaults: hosts: builtins.mapAttrs (name: value: value // defaults) hosts;
    in (setDefaults { identitiesOnly = true; } {
      "github.com" = {
        user = config.programs.git.userName;
        identityFile = "/home/${username}/.ssh/github.rsa";
      };
      "helium" = {
        user = "mrs";
        port = 8188;
        hostname = "h.mijn.place";
        identityFile = "/home/${username}/.ssh/agenix";
      };
      "orca" = {
        user = "mrs";
        hostname = "207.180.214.239";
        identityFile = "/home/${username}/.ssh/orca.rsa";
      };
      "xenon" = {
        hostname = "164.68.108.153";
        user = "mrs";
        port = 8188;
        identityFile = "/home/${username}/.ssh/agenix";
      };
    });
    forwardAgent = true;
    addKeysToAgent = "yes";
  };
}
