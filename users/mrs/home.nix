{ config, pkgs, ... }:
let
  username = "mrs";
  githubUsername = "MariskaIJpelaar";
  githubEmail = "m.m.j.ijpelaar@gmail.com";
in {
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "22.05";

  programs.home-manager.enable = true; # Let Home Manager install & manage itself.
 
  home.packages = with pkgs; [
    chromium
    drawio
    droidcam
    htop
    jetbrains.idea-community
    meld
    nheko
    nmap
    python3
    p7zip
    sublime4
    tdesktop
    teams
    teamspeak_client
    tor-browser-bundle-bin
    unzip
    zip
  ];

  home.file = { # sets background picture for xserver-provided desktop environments.
    ".background-image".source =  ../../res/background/neon_rain_3840x2160.jpg;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };    

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      direnv hook fish | source
    '';
  };

  programs.git = {
    enable = true;

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

  programs.ssh = {
    enable = true;
    forwardAgent = true;

    controlMaster = "auto";
    controlPersist = "10m";

    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = githubUsername;
        identityFile = "~/.ssh/github.rsa";
        identitiesOnly = true;
      };
    };

    # Remote servers cannot deal with TERM=foot
    extraConfig = ''
      SetEnv TERM=xterm-256color
    '';
  };
}