{ config, pkgs, ... }: {
  imports = [
    ./hardware.nix
    ./profiles.nix # seb todo
    ./programs.nix # seb todo
    ./secrets # seb todo
    ./services.nix # seb todo
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

  my.home = { # seb: TODO remove all unneeded packages from /modules/home. Especially watch out for pkgs guarded by mkDisableOption's, since they are by default enabled
    bat.enable = true; # like cat, but with syntax highlighting & more
    # bitwarden = {
    #   enable = true;
    #   pinentry = pkgs.pinentry-gtk2; # Use graphical pinentry  
    #   mail = //... wait what? Should this not be different per-user?
    # };
    
    firefox.enable = true;
    firefox.tridactyl = true; # seb: An arcane way to use firefox
    gpg.enable = true;
    # gpg.pinentry = pkgs.pinentry-gtk2; # Use a small popup to enter passwords

    # packages.additionalPackages = with pkgs; [
    #   jellyfin-media-player # Wraps the webui and mpv together
    # ];
    # mpv.enable = true; # Minimal video player
  };

  config.my.services = {
    wireguard.enable = true;
  };

  # seb: TODO continue from here to bottom

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.utf8";



  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk];
    config.common.default = "*";
  };

  # virtualisation.docker.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  programs = {
    adb.enable = true; # To use, users must be added to the "adbusers" group
    fish.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    };
    dconf.enable = true;
    nix-ld.enable = true; # for all those executables with hardcoded /lib64 dynamic linker
    xwayland.enable = true;
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

  system.stateVersion = "23.11"; # Do not change
}
