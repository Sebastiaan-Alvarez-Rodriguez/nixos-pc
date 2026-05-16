{ config, inputs, lib, pkgs, ... }: {
  imports = [
    inputs.hydenix.inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];
  age.rekey = {
    hostPubkey = ""; # not needed, no secrets here
    masterIdentities = [ "~/.ssh/deploy/radon-deploy.ed25519" ]; # must have masterIdentities set, even when no secrets are used.
    storageMode = "local";
    localStorageDir = ../../../secrets/rekey/${config.my.hardware.networking.hostname};
  };
  my.system.boot = {
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

  my.system = { # contains common system packages and settings shared between hosts.
    nix = {
      enable = true;
      inputs.link = true;
      inputs.addToRegistry = true;
      inputs.addToNixPath = true;
      inputs.overrideNixpkgs = true;
    };
    packages = {
        # enable = true; # seb TODO note error: - Your system configures nixpkgs with an externally created instance. `nixpkgs.config` options should be passed when creating the instance instead.
      allowUnfree = true;
      default-pkgs = with pkgs; [ curl micro vim wget ];
    };

    hyprland-hydenix.enable = true; # prepare system for hydenix upstream
  };

  my.programs.steam = {
    enable = true;
    enable-proton-ge = true;
  };
  programs = {
    adb.enable = true; # To use, users must be added to the "adbusers" group
  };

  my.services = { 
    greetd = {
      enable = true;
      greeting = "<=================>";
      default_session = {
        user = "rdn";
        command = "Hyprland";
      };
    };
    logiops = {
      enable = true;
      devices = {
        "MX Master 3S" = {
          dpi = 3000;
        };
      };
    };
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
        program = "helix";
        editor-name = "hx";
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
        enable = false; # NOTE: produces warning:
        # profile: You have set either `nixpkgs.config` or `nixpkgs.overlays` while using `home-manager.useGlobalPkgs`.
        # This will soon not be possible. Please remove all `nixpkgs` options when using `home-manager.useGlobalPkgs`.
        allowUnfree = true;
      };

      # spotify.enable = true;
      ssh.enable = true;
      terminal.program = "kitty";
      gm.wayland.enable = true; # prepare for a wayland environment
      wm.hyprland.hydenix = {
        enable = true;
        binds.browser.normal = config.my.home.browser.program;
        binds.browser.private = "${config.my.home.browser.program} --private-window";
        binds.editor = lib.getExe (pkgs.helix);
        binds.terminal = config.my.home.terminal.program;
      };
    };
  };

  users = let # seb: TODO make this more simple, move to nixos/home module for generation?
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

  programs.fish.enable = true;

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "25.05"; # Do not change
}
