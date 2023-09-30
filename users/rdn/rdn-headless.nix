{ inputs, config, lib, pkgs, ...}: let
  username = "rdn";
in {
  imports = [ ../headless.nix ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  programs.fish.interactiveShellInit = ''
      tabs -4
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      eval (ssh-agent -c) > /dev/null
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

  # LSPs for helix
  home.packages = with pkgs; [
    pkgs.python3Packages.python-lsp-server
  ];

  programs.git.userName = "Sebastiaan-Alvarez-Rodriguez";
  programs.git.userEmail = "sebastiaanalva@gmail.com";

  programs.ssh.matchBlocks = let 
    trustedHosts = {
      "github.com" = {
        user = "Sebastiaan-Alvarez-Rodriguez";
        identityFile = "/home/${username}/.ssh/github.rsa";
      };
      "cobra" = {
        user = "sebastiaan";
        hostname = "pythons.space";
        identityFile = "/home/${username}/.ssh/cobra_sebastiaan.rsa";
      };
      "dsn" = {
        user = "xose";
        port = 9100;
        hostname = "192.168.178.214";
        identityFile = "/home/${username}/.ssh/dsn.rsa";
      };
      "orca" = {
        user = "rdn";
        hostname = "ingrid.hypnotherapie-de-aandacht.nl";
        identityFile = "/home/${username}/.ssh/orca.rsa";
      };
      "blackberry-local" = {
        hostname = "192.168.178.213";
        user = "rdn";
        port = 18357;
        identityFile = "/home/${username}/.ssh/blackberry.rsa";
      };
      "blackberry" = {
        hostname = "home.alvarez-rodriguez.nl";
        user = "rdn";
        port = 18357;
        identityFile = "/home/${username}/.ssh/blackberry.rsa";
      };
    };
    setDefaults = defaults: hosts: builtins.mapAttrs (name: value: value // defaults) hosts;
  in (setDefaults {
    identitiesOnly = true;
    forwardAgent = true;
    # addKeysToAgent = true;
    # useKeychain = true;
  } trustedHosts);
    # // (setDefaults { user = "git"; } gitHosts);
}