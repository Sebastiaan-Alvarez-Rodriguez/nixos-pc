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

    # No ssh config here (is forwarded by forwardAgent)
    # matchBlocks = import shared/ssh/config.nix {
    #   inherit githubUsername;
    # };

    extraConfig = ''
      SetEnv TERM=xterm-256color
    '';
  };
}
