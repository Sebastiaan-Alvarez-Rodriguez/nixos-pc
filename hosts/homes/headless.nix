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
    # python3 # seb NOTE: do not combine with hydenix (since hydenix installs some other python verion I guess). Error encountered:
      # error: Cannot build '/nix/store/bifyag6y1jdm6rg08axb793iy84dc5xl-home-manager-path.drv'.
      # Reason: builder failed with exit code 25.
      # Output paths:
      #   /nix/store/kay7ckn1nrx37ayl8jjaisrs4ylv84za-home-manager-path
      # Last 5 log lines:
      # > pkgs.buildEnv error: two given paths contain a conflicting subpath:
      # >   `/nix/store/cdaifv92znxy5ai4sawricjl0p5b9sgf-python3-3.13.11/bin/pydoc' and
      # >   `/nix/store/q8w0i55y24h97cv1zf57himcg9zniyli-python3-3.13.11-env/bin/pydoc'
      # > hint: this may be caused by two different versions of the same package in buildEnv's `paths` parameter
      # > hint: `pkgs.nix-diff` can be used to compare derivations
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
