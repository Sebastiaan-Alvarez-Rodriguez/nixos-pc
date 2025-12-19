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

  programs.git.settings.user = {
    name = "MariskaIJpelaar";
    email = "m.m.j.ijpelaar@gmail.com";
  };

  programs.ssh = {
    matchBlocks = {
      "github.com" = {
        user = config.programs.git.settings.user.name;
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
      "*" = {
        identitiesOnly = true;
        forwardAgent = true;
        addKeysToAgent = "yes";
      };
    };
  };
}
