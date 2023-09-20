{ inputs, lib, config, pkgs, ... }: {
  # A common headless (non-graphical) user installation. User specializations must set:
  # home.username, home.homeDirectory, programs.git.userName, programs.git.userMail

  imports = [
    ../modules/home-manager/ssh-agent.nix
  ];

  home.stateVersion = "23.05";

  home.sessionVariables = {
    EDITOR = "${pkgs.helix}/bin/hx";
  };

  # TODO: Trim these packages so that we dont get the X libraries for random bullshit
  home.packages = with pkgs; [
    acpi
    amber # cmd search/replace
    (aspellWithDicts (dicts: [dicts.en dicts.en-computers dicts.en-science]))
    bintools-unwrapped
    btop
    editorconfig-core-c
    fd
    fzf
    gnupg
    htop
    helix
    killall
    libqalculate
    libtree
    lm_sensors
    meld
    moreutils
    mutagen
    nix-output-monitor
    nmap
    parted
    patchelf
    python3
    p7zip
    tmux
    unzip
    usbutils
    visidata # commandline tabular data explorer
    wget
    xclip # required by helix for copy/pasting (use `primary-clipboard-yank`)
    zip
  ];

  xdg.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      tabs -4
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      fish_vi_key_bindings
    '';
    shellAbbrs = {
      gs = "git status";
      gl = "git log --oneline --graph";
      ga = "git add";
      gd = "git diff";
      gdc = "git diff --cached";
      gf = "git fetch";
      gfa = "git fetch --all";
      gp = "git push";
      gpf = "git push --force-with-lease";
      gc = "git commit";
      gcm = "git commit -m";
      gca = "git commit --amend --no-edit";
      gco = "git checkout";
      grc = "git rebase --continue";
    };
    plugins = [
      {
        name = "z";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "z";
          rev = "85f863f20f24faf675827fb00f3a4e15c7838d76";
          sha256 = "+FUBM7CodtZrYKqU542fQD+ZDGrd2438trKM0tIESs0=";
        };
      }
      {
        name = "fzf.fish";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "1a0bf6c66ce37bfb0b4b0d96d14e958445c21448";
          sha256 = "sha256-1Rx17Y/NgPQR4ibMnsZ/1UCnNbkx6vZz43IKfESxcCA=";
        };
      }
    ];
  };
  programs.home-manager.enable = true;

  programs.git = { # set userName and userEmail in specializations
    enable = true;
    package = pkgs.gitFull;
    ignores = [ ".private" ".cache" "build" ".direnv" ".envrc" ];
    extraConfig = {
      core.autocrlf = false;
      pull.rebase = true;
      color.ui = true;
      diff.tool = "meld";
    };
  };

  programs.nix-index.enable = true;

  programs.ssh = {
    enable = true;
    forwardAgent = true;

    controlMaster = "auto";
    controlPersist = "10m";
  };
  services.ssh-agent.enable = true; # uncomment when using 23.11 --> then it will be merged: https://github.com/nix-community/home-manager/blob/408ba13188ff9ce309fa2bdd2f81287d79773b00/modules/services/ssh-agent.nix#L12
}