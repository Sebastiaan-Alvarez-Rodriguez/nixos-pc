{ inputs, config, lib, pkgs, ...}: let
  username = "rdn";
in {
  imports = [ ../headless.nix ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  programs.fish.interactiveShellInit = ''
      tabs -4
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      set fish_greeting '
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣶⣿⣿⣷⣶⣄⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣾⣿⣿⡿⢿⣿⣿⣿⣿⣿⣿⣿⣷⣦⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⡟⠁⣰⣿⣿⣿⡿⠿⠻⠿⣿⣿⣿⣿⣧⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⠏⠀⣴⣿⣿⣿⠉⠀⠀⠀⠀⠀⠈⢻⣿⣿⣇⠀⠀⠀
⠀⠀⠀⠀⢀⣠⣼⣿⣿⡏⠀⢠⣿⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣿⡀⠀ 
⠀⠀⠀⣰⣿⣿⣿⣿⣿⡇⠀⢸⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⡇⠀⠀
⠀⠀⢰⣿⣿⡿⣿⣿⣿⡇⠀⠘⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⢀⣸⣿⣿⣿⠁⠀⠀   - Sus Amongus
⠀⠀⣿⣿⣿⠁⣿⣿⣿⡇⠀⠀⠻⣿⣿⣿⣷⣶⣶⣶⣶⣶⣿⣿⣿⣿⠃⠀⠀⠀
⠀⢰⣿⣿⡇⠀⣿⣿⣿⠀⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀
⠀⢸⣿⣿⡇⠀⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠉⠛⠛⠛⠉⢉⣿⣿⠀⠀⠀⠀⠀⠀
⠀⢸⣿⣿⣇⠀⣿⣿⣿⠀⠀⠀⠀⠀⢀⣤⣤⣤⡀⠀⠀⢸⣿⣿⣿⣷⣦⠀⠀⠀
⠀⠀⢻⣿⣿⣶⣿⣿⣿⠀⠀⠀⠀⠀⠈⠻⣿⣿⣿⣦⡀⠀⠉⠉⠻⣿⣿⡇⠀⠀
⠀⠀⠀⠛⠿⣿⣿⣿⣿⣷⣤⡀⠀⠀⠀⠀⠈⠹⣿⣿⣇⣀⠀⣠⣾⣿⣿⡇⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣦⣤⣤⣤⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⢿⣿⣿⣿⣿⣿⣿⠿⠋⠉⠛⠋⠉⠉⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠁
      '
      fish_vi_key_bindings
  '';

  programs.git.userName = "Sebastiaan-Alvarez-Rodriguez";
  programs.git.userEmail = "sebastiaanalva@gmail.com";

  programs.ssh = {
    matchBlocks = let 
      setDefaults = defaults: hosts: builtins.mapAttrs (name: value: value // defaults) hosts;
    in (setDefaults { identitiesOnly = true; } {
      "blackberry" = {
        hostname = "blackberry.mijn.place";
        user = "rdn";
        port = 8188;
        identityFile = "/home/${username}/.ssh/blackberry.rsa";
        # addressFamily = "inet"; # force ipv4.
      };
      "dsn" = {
        user = "xose";
        port = 9100;
        hostname = "192.168.178.5";
        identityFile = "/home/${username}/.ssh/dsn.rsa";
      };
      "github.com" = {
        user = config.programs.git.userName;
        identityFile = "/home/${username}/.ssh/github.rsa";
      };
      "helium" = {
        user = "rdn";
        port = 8188;
        hostname = "h.mijn.place";
        identityFile = "/home/${username}/.ssh/agenix";
      };
      "orca" = {
        user = "rdn";
        hostname = "207.180.214.239";
        identityFile = "/home/${username}/.ssh/orca.rsa";
      };
      "xenon" = {
        hostname = "62.171.150.8";
        user = "rdn";
        port = 8188;
        identityFile = "/home/${username}/.ssh/xenon.rsa";
      };
    });
    forwardAgent = true;
    addKeysToAgent = "yes";
  };
}
