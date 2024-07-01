{ config, pkgs, ... }: {
  imports = [ ./hardware.nix ];

  services.openssh = {
    # Enable the OpenSSH daemon.
    enable = true;

    settings = {
      PasswordAuthentication = true;
    };
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

  my.home = {
    bat.enable = true; # like cat, but with syntax highlighting & more
    # bitwarden = {
    #   enable = true;
    #   pinentry = pkgs.pinentry-gtk2; # Use graphical pinentry  
    #   mail = //... wait what? Should this not be different per-user?
    # };
    editor.main = {
      package = pkgs.helix;
      path = "${pkgs.helix}/bin/hx";
    };
    firefox.enable = true;
    # firefox.tridactyl.enable = true; # seb: An arcane way to use firefox
    gm.manager = "wayland";
    gpg.enable = true;
    gpg.pinentry = pkgs.pinentry-gtk2; # Use a small popup to enter passwords
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
      # additionalPackages = with pkgs; [ jellyfin-media-player ]; # Wraps the webui and mpv together
    };

    # mpv.enable = true; # Minimal video player
    spotify.enable = true;
    ssh = {
      enable = true;
      mosh.enable = true;
    };
    terminal.program = "foot";
    wm = {
      manager = "river";
      dunst.enable = false; # seb: TODO explore dunst (needs to disable mako)
      grim.enable = true;
      kanshi = {
        enable = true;
        systemdTarget = "river-session.target";
      };
      mako.enable = true;
      rofi.enable = true;
      wpaperd = {
        enable = true;
        systemdTarget = "river-session.target";
      };
    };      
    wm.waybar = {
      enable = true;
      systemdTarget = "river-session.target";
    };
    # xdg.enable = true;
  };

  my.programs = {
    # Steam configuration
    steam.enable = true;
  };
  programs = {
    adb.enable = true; # To use, users must be added to the "adbusers" group
  };

  my.services = { 
    greetd = {
      enable = true;
      greeting = "<=================>";
      sessions = {
        "default_session" = pkgs.writeShellScript "start-river" ''
          # Seems to be needed to get river to properly start
          sleep 1
          export XDG_SESSION_TYPE=wayland
          export XDG_CURRENT_DESKTOP=river
          ${pkgs.river}/bin/river
        '';
      };
    };
  #   wireguard.enable = true; # seb: TODO uncomment after handling wireguard config.
  };

  my.profiles = {
    # bluetooth.enable = true;
    gtk.enable = true;
    # laptop.enable = true;
  };

  services = {
    dbus.enable = true;
    teamviewer.enable = true; # seb: NOTE remove if it does not work.
  };

  environment.etc."greetd/environments".text = ''
    river
  ''; # allows users logging in to pick their window manager.

  environment.systemPackages = [ pkgs.home-manager ];

  users = let # seb: TODO make this more simple, move to nixos/home module for generation?
    groupExists = grp: builtins.hasAttr grp config.users.groups;
    groupsIfExist = builtins.filter groupExists;
  in {
    # mutableUsers = false;
    users.rdn = {
      # hashedPasswordFile = config.age.secrets."users/rdn/host-password".path;
      isNormalUser = true;
      description = "rdn";
      extraGroups = groupsIfExist [ "adbusers" "audio" "docker" "media" "networkmanager" "plugdev" "podman" "video" "wheel" ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [ (builtins.readFile ../../../secrets/keys/users/rdn.rsa.pub) ];
    };
  };
  # seb: TODO can make this auto-discovery by iterating users.users and iterating their ~/.ssh directories
  # age.identityPaths = [ "/home/rdn/.ssh/agenix" ]; # list of paths to recipient keys to try to use to decrypt the secrets

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.utf8";

  system.stateVersion = "24.05"; # Do not change
}
