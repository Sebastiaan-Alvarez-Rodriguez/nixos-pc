{ config, pkgs, ... }: 
let
  username = "rdn";
  githubUsername = "Sebastiaan-Alvarez-Rodriguez";
  githubEmail = "sebastiaanalva@gmail.com";
in {
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "22.05";

 
  home.packages = with pkgs; [
    binutils
    parted
    htop
    meld
    micro
    nmap
    patchelf
    python3
    p7zip
    tmux
    unzip
    wget
    zip
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };    

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      tabs -4
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      set fish_greeting
    '';
  };

  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    userName = githubUsername;
    userEmail = githubEmail;


    signing = {
      key = null;
      signByDefault = false;
    };

    ignores = [ ".private" ".cache" ];

    extraConfig = {
      pull.rebase = true;
      color.ui = true;
      diff.tool = "meld";
    };
  };
  programs.home-manager.enable = true;
}
