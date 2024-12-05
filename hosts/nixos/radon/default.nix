{ inputs, config, pkgs, system, ... }: let
    capella = inputs.self.packages.${system}.capella;
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
    spotify.enable = true;
    ssh = {
      enable = true;
      mosh.enable = true;
    };
    terminal.program = "foot";
    wm = {
      river.enable = true;
      apps = {
        dunst.enable = false; # seb: TODO explore dunst (needs to disable mako)
        grim.enable = true;
        kanshi = {
          enable = true;
          systemdTarget = "river-session.target";
        };
        mako.enable = true;
        rofi.enable = true;
        swaylock = {
          enable = true;
          image = {
            url = "https://w.wallhaven.cc/full/zy/wallhaven-zy3l5o.jpg";
            sha256 = "d71fce2282c21b44c26aa9a89e64d00fb89db1298d42c0e8fb8a241ce7228371";
            pixelate = 3;
          };
        };
        wlogout = {
          enable = true;
          image = {
            url = "https://w.wallhaven.cc/full/p9/wallhaven-p9586j.png";
            sha256 = "07181c8d3e3a33b09acfb65adeb1d30b8efbf15a3c0300954893263708d0c855";
          };
          accent-color = "rgb (139, 0, 0)";
        };
        wpaperd = {
          enable = true;
          image = {
            url = "https://w.wallhaven.cc/full/p9/wallhaven-p9586j.png";
            sha256 = "07181c8d3e3a33b09acfb65adeb1d30b8efbf15a3c0300954893263708d0c855";
          };
          systemdTarget = "river-session.target";
        };
        waybar = {
          enable = true;
          systemdTarget = "river-session.target";
        };
      };
    };
  };

  my.programs = {
    steam.enable = true;
  };
  programs = {
    adb.enable = true; # To use, users must be added to the "adbusers" group
  };

  my.services = { 
    fail2ban.enable = true;
    greetd = {
      enable = true;
      greeting = "<=================>";
      wait-for-graphical = true;
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
    ssh-server.enable = true;
  };

  my.profiles = {
    gtk.enable = true;
  };

  services = {
    dbus.enable = true;
    teamviewer.enable = true; # seb: NOTE remove if it does not work.
  };

  environment.etc."greetd/environments".text = ''
    river
  ''; # allows users logging in to pick their window manager.

  environment.systemPackages = [ pkgs.home-manager capella ];

  users = let # seb: TODO make this more simple, move to nixos/home module for generation?
    groupExists = grp: builtins.hasAttr grp config.users.groups;
    groupsIfExist = builtins.filter groupExists;
  in {
    # mutableUsers = false;
    users.rdn = {
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
