{ config, pkgs, ... }: {
  imports = [
    ./hardware.nix
    # ./secrets # seb todo
  ];

  my.system.boot = {
    enable = true;
    tmp.clean = true;
    kind = "systemd";
    extraConfig = {
      initrd.secrets = { "/crypto_keyfile.bin" = null; }; # Setup keyfile
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
    nix.enable = true;
    packages.enable = true;
    packages.allowUnfree = true;
  };

  my.home = { # seb: TODO remove all unneeded packages from /modules/home. Especially watch out for pkgs guarded by mkDisableOption's, since they are by default enabled
    bat.enable = true; # like cat, but with syntax highlighting & more
    # bitwarden = {
    #   enable = true;
    #   pinentry = pkgs.pinentry-gtk2; # Use graphical pinentry  
    #   mail = //... wait what? Should this not be different per-user?
    # };
    
    firefox.enable = true;
    firefox.tridactyl.enable = true; # seb: An arcane way to use firefox
    gm.manager = "wayland";
    gpg.enable = true;
    # gpg.pinentry = pkgs.pinentry-gtk2; # Use a small popup to enter passwords

    # packages.additionalPackages = with pkgs; [
    #   jellyfin-media-player # Wraps the webui and mpv together
    # ];
    # mpv.enable = true; # Minimal video player
    spotify.enable = true;
    wm.manager = "river";
    wm.mako.enable = true;
    wm.rofi.enable = true;
    wm.waybar.enable = true;
  };

  my.programs = {
    # Steam configuration
    steam.enable = true;
  };
  programs = {
    adb.enable = true; # To use, users must be added to the "adbusers" group
    dconf.enable = true;
  };

  # my.services = { # seb: TODO uncomment after handling wireguard config.
  #   wireguard.enable = true;
  # };

  my.profiles = {
    # Bluetooth configuration and GUI
    # bluetooth.enable = true; # seb: TODO for laptop hosts, enable
    gtk.enable = true;
    # Laptop specific configuration
    # laptop.enable = true; # seb: TODO checkout what this is for laptop hosts
    # i3 configuration
  # seb: TODO continue from here to bottom
    # wm.windowManager = "river"; # i3 is for X.
    # X configuration
    x.enable = true;
  };

  services = {
    dbus.enable = true;
    greetd = { # seb TODO: should not have this config here, especially running stuff as a hardcoded user.
      enable = true;
      restart = false;
      settings = rec {
        initial_session = let
          run = pkgs.writeShellScript "start-river" ''
            # Seems to be needed to get river to properly start
            sleep 1
            # Set the proper XDG desktop so that xdg-desktop-portal works
            # This needs to be done before river is started
            export XDG_CURRENT_DESKTOP=river
            ${pkgs.river}/bin/river
          '';
        in {
          command = "${run}";
          user = "rdn";
        };
        default_session = initial_session;
      };
    };
    logind = {
      #lidSwitch = "ignore";
      #lidSwitchDocked = "ignore";
    };
    teamviewer.enable = true;
  };

  environment.systemPackages = [
    pkgs.home-manager
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rdn = {
    isNormalUser = true;
    description = "rdn";
    extraGroups = [ "networkmanager" "wheel" "adbusers"]; # "docker" if we use docker
    shell = pkgs.fish;
    password = "changeme";
  };

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.utf8";

  system.stateVersion = "23.11"; # Do not change
}
