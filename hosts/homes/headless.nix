{ inputs, lib, config, pkgs, ... }: {
  # TODO: Trim these packages so that we dont get the X libraries for random bullshit
  home.packages = with pkgs; [
    acpi
    amber # cmd search/replace
    (aspellWithDicts (dicts: [dicts.en dicts.en-computers dicts.en-science]))
    bintools-unwrapped
    btop
    editorconfig-core-c
    fastfetch # system info display tool
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
    micro
    moreutils
    mutagen
    net-tools
    nix-output-monitor
    nmap
    parted
    patchelf
    p7zip
    unzip
    usbutils
    visidata # commandline tabular data explorer
    wget
    xclip # required by some editors for copy/pasting (use `primary-clipboard-yank`)
    zip
  ];

  xdg.enable = true;
  xdg.userDirs.setSessionVariables = false;

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

  programs.git = { # set user.name and user.email in specializations
    enable = true;
    package = pkgs.gitFull;
    ignores = [ ".private" ".cache" "build" ".direnv" ".envrc" ];
    settings = {
      core.autocrlf = false;
      pull.rebase = true;
      color.ui = true;
      diff.tool = "meld";
    };
  };

  programs.nix-index.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      controlPersist = "10m";
      forwardAgent = true;
      controlMaster = "auto";
    };
  };
}
