{ inputs, config, lib, pkgs, system, ... }: let
  stremio-service = inputs.self.packages.${system}.stremio-service;
in {
  imports = [ ./hardware.nix ];

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
    home.users = [ "rdn" ]; # NOTE: Define normal users here. These users' home profiles will be populated with the settings from 'my.home' configuration below.
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

  age.rekey = {
    masterIdentities = [ "~/.ssh/deploy/radon-deploy.ed25519" ]; # must have masterIdentities set, even when no secrets are used.
    storageMode = "local";
    localStorageDir = ../../../secrets/rekey/${config.my.hardware.networking.hostname};
  };

  my.home = {
    bat.enable = true; # like cat, but with syntax highlighting & more
    editor.main = {
      package = pkgs.helix;
      path = "${pkgs.helix}/bin/hx";
    };
    librewolf.enable = true;
    gm.wayland.enable = true;
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
      enable = true;
      allowUnfree = true;
    };

    # mpv.enable = true; # Minimal video player
    # spotify.enable = true;
    ssh = {
      enable = true;
      mosh.enable = true;
    };
    terminal.program = "foot";
    wm = {
      hyprland.enable = true;
      hyprland.hydenix.enable = true;
      apps = {
        # grim.enable = true;
        # kanshi = {
        #   enable = true;
        #   systemdTarget = "river-session.target";
        # };
        # mako.enable = true;
        # rofi.enable = true; # seb NOTE: needed?
        # swaylock = {
        #   enable = true;
        #   image = {
        #     url = "https://w.wallhaven.cc/full/zy/wallhaven-zy3l5o.jpg";
        #     sha256 = "d71fce2282c21b44c26aa9a89e64d00fb89db1298d42c0e8fb8a241ce7228371";
        #     pixelate = 3;
        #   };
        # };
        # wlogout = {
        #   enable = true;
        #   image = {
        #     url = "https://w.wallhaven.cc/full/p9/wallhaven-p9586j.png";
        #     sha256 = "07181c8d3e3a33b09acfb65adeb1d30b8efbf15a3c0300954893263708d0c855";
        #   };
        #   accent-color = "rgb (139, 0, 0)";
        # };
        # wpaperd = {
        #   enable = true;
        #   image = {
        #     # url = "https://w.wallhaven.cc/full/p9/wallhaven-p9586j.png";
        #     # sha256 = "07181c8d3e3a33b09acfb65adeb1d30b8efbf15a3c0300954893263708d0c855";
        #     url = "https://www.academiacolecciones.com/pinturas/server/files/0601.jpg";
        #     sha256 = "sha256:1zs11020qjrpskg3dds8l0rcy11i73c2a1vn7831fhys7vn2d5mp";
        #   };
        #   systemdTarget = "river-session.target";
        # };
        # waybar = {
        #   enable = true;
        #   systemdTarget = "river-session.target";
        # };
      };
    };
  };
  # global hydenix configuration
  hydenix = {
    hostname = config.my.hardware.networking.hostname;
    timezone = config.time.timeZone;
    locale = config.il8n.defaultLocale;

    # stuff hydenix tries to configure despite being a hyprland preconfig-theme
    # see here: https://github.com/richen604/hydenix/tree/main/hydenix/modules/system
    audio.enable = false;
    boot.enable = false;
    gaming.enable = false;
    hardware.enable = false;
    network.enable = false;
    nix.enable = false;
    sddm.enable = false; # might be nice to actually use
    system.enable = false;
  };

  my.programs = {
    steam.enable = true;
  };
  programs = {
    adb.enable = true; # To use, users must be added to the "adbusers" group
  };

  my.services = { 
    # fail2ban.enable = true;
    greetd = {
      enable = true;
      greeting = "<=================>";
      wait-for-graphical = true;
      sessions = {
        "default_session" = pkgs.writeShellScript "start-wm" ''
          sleep 1
          ${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland}/bin/start-hyprland
        '';
      };
    };
  #   wireguard.enable = true; # seb: TODO uncomment after handling wireguard config.
    ssh-server.enable = true;
  };

  my.profiles = {
    # gtk.enable = true; seb TODO: hydenix config setup time?
  };

  services = {
    dbus.enable = true;
    udev.packages = with pkgs; [
      # https://discourse.nixos.org/t/nixos-udev-configuration/27693
      # https://discourse.nixos.org/t/via-vial-cant-find-my-keyboard/52525
      qmk
      qmk-udev-rules
      vial
    ];
  };

  # environment.etc."greetd/environments".text = '' # todo Seb hydenix config setup time?
  #   hyprland
  # ''; # allows users logging in to pick their window manager.

  environment.systemPackages = with pkgs; [ home-manager ffmpeg ];

  users = let # seb: TODO make this more simple, move to nixos/home module for generation?
    groupExists = grp: builtins.hasAttr grp config.users.groups;
    groupsIfExist = builtins.filter groupExists;
  in {
    # mutableUsers = false;
    users.rdn = {
      isNormalUser = true;
      description = "rdn";
      extraGroups = groupsIfExist [ "adbusers" "audio" "docker" "media" "networkmanager" "plugdev" "podman" "dialout" "video" "wheel" ];
      shell = pkgs.fish;
    };
  };

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = lib.mkForce "24.05"; # Do not change
}
