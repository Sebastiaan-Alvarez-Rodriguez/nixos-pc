{ config, inputs, lib, pkgs, ... }: {
  imports = [
    ./hardware.nix
  ];
  age.rekey = {
    hostPubkey = ""; # not needed, no secrets here
    masterIdentities = [ "~/.ssh/deploy/radon-deploy.ed25519" ]; # must have masterIdentities set, even when no secrets are used.
    storageMode = "local";
    localStorageDir = ../../../secrets/rekey/${config.my.hardware.networking.hostname};
  };

  my.system = { # contains common system packages and settings shared between hosts.
    boot = {
      enable = true;
      tmp.clean = true;
      kind = "systemd";
      extraConfig = {
        kernelModules = [ "v4l2loopback" ];
        extraModulePackages = [ config.boot.kernelPackages.v4l2loopback.out ];
        extraModprobeConfig = ''
          options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
        '';
        supportedFilesystems = [ "ntfs" ]; # Allow NTFS reading https://nixos.wifi/wiki/NTFS
        binfmt.emulatedSystems = [ "aarch64-linux" ];
      };
    };

    nix = {
      enable = true;
      inputs.link = true;
      inputs.addToRegistry = true;
      inputs.addToNixPath = true;
      inputs.overrideNixpkgs = true;
    };
    packages = {
      enable = true;
      allowUnfree = true;
      default-pkgs = with pkgs; [ curl micro vim wget ];
    };
  };

  my.programs.steam = {
    enable = true;
    enable-proton-ge = true;
  };

  my.services = { 
    greetd = {
      enable = true;
      greeting = "<=================>";
      default_session = {
        user = "rdn";
        command = "start-hyprland";
      };
    };
    # logiops = {
    #   enable = true;
    #   devices."MX Master 3S".dpi = 3000;
    # };
  };

  my.system.home.users."rdn" = { config, ... }: {
    imports = [
      "${inputs.self}/modules/home" # generic home module so we have access to all my.home.... options.
      "${inputs.self}/hosts/homes/rdn@radon" # specific home module of a user, e.g. hosts/homes/user@host.
    ];

    my.home = {
      bat.enable = true; # like cat, but with syntax highlighting & more
      browser.program = "librewolf";
      editor = {
        helix = true;
        editor-name = "hx";
      };

      nix = {
        enable = true;
        inputs.link = true;
        inputs.addToRegistry = true;
        inputs.addToNixPath = true;
        inputs.overrideNixpkgs = true;
      };

      # spotify.enable = true;
      ssh.enable = true;
      stylix = {
        enable = true;
        auto-enable = true;
      };
      terminal.program = "kitty";
      gm.wayland.enable = true; # prepare for a wayland environment
      wm.hyprland = {
        enable = true;
        binds = {
          browser.normal = config.my.home.browser.program;
          browser.private = "${config.my.home.browser.program} --private-window";
          editor = lib.getExe (pkgs.helix);
          terminal = config.my.home.terminal.program;
        };
        wayle = {
          enable = true;
        };
      };
      wm.apps.rofi.enable = true;
    };
  };

  users = let
    groupExists = grp: builtins.hasAttr grp config.users.groups;
    groupsIfExist = builtins.filter groupExists;
  in {
    users.rdn = {
      isNormalUser = true;
      description = "rdn";
      extraGroups = groupsIfExist [ "adbusers" "audio" "docker" "media" "networkmanager" "plugdev" "podman" "dialout" "video" "wheel" ];
      shell = pkgs.fish; # Default shell (options: pkgs.bash, pkgs.zsh, pkgs.fish)
    };
  };

  environment.systemPackages = [ pkgs.android-tools ]; # for adb
  programs.fish.enable = true;
  programs.dconf.enable = true; # required by home-manager apparently

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "25.05"; # Do not change
}
