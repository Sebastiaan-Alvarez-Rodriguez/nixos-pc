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
      river = {
        enable = true;
        extra-config = ''
          riverctl input pointer-1267-12440-ELAN1201:00_04F3:3098_Touchpad tap enabled
        '';
      };
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
          image.path = "/etc/wallpaper.jpg";
          accent-color = "rgb (139, 0, 0)";
        };
        wpaperd = {
          enable = true;
          image.path = "/etc/wallpaper.jpg";
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

  my.services = { # seb: TODO uncomment after handling wireguard config.
  #   wireguard.enable = true;
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
  };

  my.profiles = {
    # bluetooth.enable = true; # seb: TODO for laptop hosts, enable
    gtk.enable = true;
    laptop = {
      enable = true;
      extra-silent = true;
    };
  };

  services = {
    dbus.enable = true;
    # logind = {
    #   lidSwitch = "ignore";
    #   lidSwitchDocked = "ignore";
    # };
  };

  environment.etc."greetd/environments".text = ''
    river
  ''; # allows users logging in to pick their window manager.
  environment.etc."wallpaper.jpg".source = builtins.fetchurl {
    url = "https://api-rog.asus.com/recent-data/api/v3/Wallpaper/Download/1482";
    sha256 = "sha256:1504gzj7g9mkv0pkab1i34cmkli7fzrj0vg8ga80kzqvi1xs323x";
  };

  environment.systemPackages = [ pkgs.home-manager ];
  # Extra configuration for console.
  services.xserver.xkb.options = "caps:hyper,compose:rctrl";
  console.useXkbConfig = true;


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
  age.identityPaths = [ "/home/rdn/.ssh/agenix" ]; # list of paths to recipient keys to try to use to decrypt the secrets

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.utf8";

  system.stateVersion = "24.05"; # Do not change
}
