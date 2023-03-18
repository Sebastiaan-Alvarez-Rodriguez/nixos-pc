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
    chromium
    drawio
    droidcam
    galculator
    gparted
    htop
    jetbrains.idea-community
    meld
    micro
    nheko
    nmap
    patchelf
    python3
    p7zip
    qbittorrent
    sublime4
    tdesktop
    teams
    teamspeak_client
    tor-browser-bundle-bin
    unzip
    vlc
    wget
    zip
  ];

  home.file = { 
    # sets background picture for xserver-provided desktop environments.
    ".background-image".source =  ../res/background/neon_rain_3840x2160.jpg;
    # sets KDE plasma to use the background picture.
    ".config/plasmarc".text = ''
      [Theme]
      name=breeze-dark

      [Wallpapers]
      usersWallpapers=${pkgs.breeze-qt5}/share/wallpapers/Next/,${config.home.homeDirectory}/.background-image
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };    

  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      extraPolicies = {
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DisableFirefoxAccounts = true;
        FirefoxHome = {
          Pocket = false;
          Snippets = false;
        };
        UserMessaging = {
          ExtensionRecommendation = false;
          SkipOnboarding = false;
        };
      };
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      direnv hook fish | source
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


  programs.ssh = {
    enable = true;
    forwardAgent = true;

    controlMaster = "auto";
    controlPersist = "10m";

    matchBlocks = import shared/ssh/config.nix {
      inherit githubUsername;
    };

    extraConfig = ''
      SetEnv TERM=xterm-256color
    '';
  };
}
