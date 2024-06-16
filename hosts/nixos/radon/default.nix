{ config, pkgs, ... }: {
  imports = [ ./hardware.nix ];

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
    # gpg.pinentry = pkgs.pinentry-gtk2; # Use a small popup to enter passwords
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
    terminal.program = "foot";
    wm.manager = "river";
    wm.dunst.enable = false; # seb: TODO explore dunst (needs to disable mako)
    wm.grim.enable = true;
    wm.flameshot.enable = false; # seb: TODO explore flameshot (needs to disable grim)
    wm.mako.enable = true;
    wm.rofi.enable = true;
    wm.wpaperd.enable = true;
    wm.waybar.enable = true;
    # xdg.enable = true;
  };

  my.programs = {
    # Steam configuration
    steam.enable = true;
  };
  programs = {
    adb.enable = true; # To use, users must be added to the "adbusers" group
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
  };

  services = {
    dbus.enable = true;
    services.greetd = {
      enable = true;
      restart = false;
      settings = rec {
        initial_session =
        let
          run = pkgs.writeShellScript "start-river" ''
            # Seems to be needed to get river to properly start
            sleep 1
            # Set the proper XDG desktop so that xdg-desktop-portal works
            # This needs to be done before river is started
            export XDG_CURRENT_DESKTOP=river
            ${pkgs.river}/bin/river
          '';
        in
        {
          command = "${run}";
          user = "robin";
        };
        default_session = initial_session;
      };
    };

    # seb: TODO nice modern greetd does not work.
    # greetd = { # seb: NOTE see https://drakerossman.com/blog/wayland-on-nixos-confusion-conquest-triumph#what-are-xorg-wayland-and-why-you-should-choose-the-latter (Adding a nice login screen)
    #   enable = true;
    #   settings = {
    #     default_session.command = let
    #       run = pkgs.writeShellScript "start-river" ''
    #         export XDG_CURRENT_DESKTOP=river
    #         ${pkgs.river}/bin/river
    #       '';
    #     in
    #       ''
    #         ${pkgs.greetd.tuigreet}/bin/tuigreet \
    #           --time \
    #           --asterisks \
    #           --user-menu \
    #           --cmd "${run}";
    #       '';
    #   };
    # };

    # logind = {
    #   lidSwitch = "ignore";
    #   lidSwitchDocked = "ignore";
    # };
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
  age.identityPaths = [ "/home/rdn/.ssh/agenix" ]; # list of paths to recipient keys to try to use to decrypt the secrets

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.utf8";

  system.stateVersion = "24.05"; # Do not change
}
