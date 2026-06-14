{ config, inputs, system, lib, pkgs, ... }: {
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
        command = "start-hyprland";
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
        helix = true;
        editor-name = "hx";
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

      # mpv.enable = true; # Minimal video player
      ssh.enable = true;

      # spotify.enable = true;
      stylix = {
        enable = true;
        auto-enable = true;
        image = builtins.fetchurl {
          url = "https://w.wallhaven.cc/full/e7/wallhaven-e76pew.png";
          sha256 = "sha256:0qdmqxpjpynnqamdagxcpnagb34h5hldhw4iv9pjj4iwl3h3cqf7";
        };
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
          extra-config = {
            bar = {
              scale = 0.800000011920929;
              background-opacity = 0;
              button-variant = "basic";
              dropdown-opacity = 100;
              layout = {
                monitor = "*";
                show = true;
                left = [ "dashboard" "media" "separator" "window-title" "hyprland-workspaces" ];
                center = [ "clock" "weather" ];
                right = [ "cpu" "ram" "network" "microphone" "volume" "systray" "notifications" ];
              };
            };
            modules.clock.format = "%a %b %d %H:%M";
            modules.weather = {
              location = "'s-Hertogenbosch";
              time-format = "24h";
            };
          };
          # hydenix used to have:
          # System-wide:
          # wl-clipboard and wl-clip-persist
          # hyprland withUWSM = true; (idk)
          # hypridle (idk)
          # sddm (graphical login) (alternatives LightDM and GDM): https://github.com/richen604/hydenix/blob/main/hydenix/modules/system/sddm.nix
          #
          # home-wide:
          # hyprlock (with styles, ~/.config/hypr/hyprlock/)
          # wlogout (with styles, styles still in ~/.config/wlogout)
          # dunst (notifications)
          # rofi (application launcher, with styles in ~/.config/rofi)
          #   and themes in ~/.local/share/hyde/rofi/themes
          #   and assets in ~/.local/share/hyde/rofi/assets
          #   CHECK the docs here: https://deepwiki.com/HyDE-Project/HyDE/8.3-menu-and-picker-systems
          # swww (wallpapers)
          # uwsm module (idk)
          # waybar
          # dolphin (file manager)
        };
      };
      wm.apps.cursor = {
        enable = true;
        name = "Breeze_Obsidian";
        package = inputs.self.packages.${system}.breeze-obsidian-cursor; 
        hyprcursor = true;
      }; 
      wm.apps.hyprlock.enable = true;
      wm.apps.hypridle.enable = true;
      wm.apps.rofi.enable = true;
      wm.apps.wpaperd.enable = true;
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

  security.pam.services.hyprlock = {}; # needed so nixOS knows how to verify hyprlock login attempts

  environment.systemPackages = [ pkgs.android-tools ]; # for adb
  programs.fish.enable = true;

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = lib.mkForce "24.05"; # Do not change
}
