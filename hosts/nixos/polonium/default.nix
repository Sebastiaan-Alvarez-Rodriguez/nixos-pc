{ config, lib, inputs, pkgs, ... }: {
  imports = [
    inputs.home-manager.nixosModules.default
    ./hardware.nix
  ];
  age.rekey = {
    hostPubkey = ""; # not needed, no secrets here
    masterIdentities = [ "~/.ssh/deploy/polonium-deploy.ed25519" ]; # must have masterIdentities set, even when no secrets are used.
    storageMode = "local";
    localStorageDir = ../../../secrets/rekey/${config.my.hardware.networking.hostname};
  };
  my.system.boot = {
    enable = true;
    tmp.clean = true;
    kind = "systemd";
    extraConfig = {
      # initrd.secrets = { "/crypto_keyfile.bin" = null; }; # Setup keyfile seb NOTE: what is that?
      kernelModules = [ "v4l2loopback" ];
      extraModulePackages = [ config.boot.kernelPackages.v4l2loopback.out ];
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
      '';
    };
  };

  my.system = { # contains common system packages and settings shared between hosts.
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
    hyprland-end4.enable = true;
  };

  my.programs = {
    steam.enable = true;
  };

  my.services = {
    asusd = {
      enable = true;
      fancurves = {
        balanced = {
          cpu = { pwm = [ 0 0 0 0 0 70 135 158 ]; temp = [ 10 20 30 40 60 78 85 98 ]; };
          gpu = { pwm = [ 0 0 0 0 0 70 135 165 ]; temp = [ 10 20 30 40 60 78 85 98 ]; };
        };
        performance = {
          cpu = { pwm = [ 0 0 0 0 50 90 140 158 ]; temp = [ 10 20 30 40 60 78 85 98 ]; };
          gpu = { pwm = [ 0 0 0 0 50 90 140 178 ]; temp = [ 10 20 30 40 60 78 85 98 ]; };
        };
        quiet = {
          cpu = { pwm = [ 0 0 0 0 0 50 120 150 ]; temp = [ 10 20 30 40 60 78 85 98 ]; };
          gpu = { pwm = [ 0 0 0 0 0 50 140 170 ]; temp = [ 10 20 30 40 60 78 85 98 ]; };
        };
        custom = {
          cpu = { pwm = [ 0 0 0 0 0 50 120 150 ]; temp = [ 10 20 30 40 60 78 85 98 ]; };
          gpu = { pwm = [ 0 0 0 0 0 50 140 170 ]; temp = [ 10 20 30 40 60 78 85 98 ]; };
        };
      };
    };
    greetd = {
      enable = true;
      greeting = "<=================>";
      default_session = {
        user = "rdn";
        command = "Hyprland";
      };
    };
  };

  my.system.home.users."rdn" = { config, ... }: {
    imports = [
      "${inputs.self}/modules/home" # generic home module so we have access to all my.home.... options.
      "${inputs.self}/hosts/homes/rdn@polonium" # specific home module of a user, e.g. hosts/homes/user@host.
    ];
    my.home = {
      bat.enable = true; # like cat, but with syntax highlighting & more
      browser.program = "librewolf";
      editor = {
        program = "helix";
        extras = [ "vim" ];
      };
      gpg = {
        enable = false; # seb: TODO figure out how to not be annoyed
        pinentry = pkgs.pinentry-gtk2; # Use a small popup to enter passwords
      };
      nix = {
        enable = true;
        inputs.link = true;
        inputs.addToRegistry = true;
        inputs.addToNixPath = true;
        inputs.overrideNixpkgs = true;
      };

      packages = {
        enable = false;
        # NOTE: produces warning:
        # profile: You have set either `nixpkgs.config` or `nixpkgs.overlays` while using `home-manager.useGlobalPkgs`.
        # This will soon not be possible. Please remove all `nixpkgs` options when using `home-manager.useGlobalPkgs`.
        allowUnfree = true;
      };

      # mpv.enable = true; # Minimal video player
      ssh.enable = true;
      # spotify.enable = true;
      terminal.program = "kitty";
      gm.wayland.enable = true; # prepare for a wayland environment
      wm.hyprland.end4-illogical = {
        enable = true;
        binds.browser.normal = config.my.home.browser.program;
        binds.browser.private = "${config.my.home.browser.program} --private-window";
        binds.terminal = config.my.home.terminal.program;
      };
    };
  };

  users = let # seb: TODO make this more simple, move to nixos/home module for generation?
    groupExists = grp: builtins.hasAttr grp config.users.groups;
    groupsIfExist = builtins.filter groupExists;
  in {
    # mutableUsers = false;
    users.rdn = {
      isNormalUser = true;
      description = "rdn";
      extraGroups = groupsIfExist [ "syncthing" "adbusers" "audio" "docker" "media" "networkmanager" "plugdev" "podman" "video" "wheel" ];
      shell = pkgs.fish;
    };
  };

  environment.systemPackages = [ pkgs.android-tools ]; # for adb
  programs.fish.enable = true;

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = lib.mkForce "24.05"; # Do not change
}
