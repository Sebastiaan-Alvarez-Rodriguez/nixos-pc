{ config, lib, pkgs, ... }: let
  mkRelatedOption = description: relatedWMs: let
    isActivatedWm = wm: config.my.home.wm.windowManager == wm;
  in
    (lib.mkEnableOption description) // {
      default = builtins.any isActivatedWm relatedWMs;
    };
in {
  imports = [
    ./dunst
    ./flameshot
    ./grim
    ./i3
    ./i3bar
    ./kanshi
    ./mako
    ./river
    ./rofi
    ./screen-lock
    ./swaylock
    ./waybar
    ./wpaperd
  ];

  options.my.home.wm = with lib; {
    manager = mkOption {
      type = with types; nullOr (enum [ "i3" "river" ]);
      # seb: For sway, https://nixos.wiki/wiki/Sway (use homemanager)
      # seb: For river, https://home-manager-options.extranix.com/?query=river&release=master
      default = null;
      description = "Which window manager to use for home session";
    };

    # applications to enhance window managers
    grim = {
      enable = mkEnableOption "screenshot-tool - wayland - grim";
    };
    flameshot = {
      enable = mkEnableOption "screenshot-tool - wayland - flameshot";
    };
    kanshi = {
      enable = mkEnableOption "display-configuration - kanshi";
    };
    mako = {
      enable = mkEnableOption "notifications - wayland - mako";
    };
    rofi = {
      enable = mkEnableOption "desktop-menu - xserver wayland - rofi";
    };
    waybar = {
      enable = mkEnableOption "status-bar - wayland - waybar";
    };
    wpaperd = {
      enable = mkEnableOption "background-display - wayland - wpaperd";
    };

    dunst = {
      enable = mkEnableOption "notifications - xserver wayland - dunst";
    };


    i3bar = { # seb TODO: checkout package & config
      enable = mkEnableOption "status-bar - xserver - i3bar";

      vpn = {
        enable = my.mkDisableOption "VPN configuration";

        blockConfigs = mkOption {
          type = with types; listOf (attrsOf str);
          default = [
            {
              active_format = " VPN ";
              service = "wg-quick-wg";
            }
            {
              active_format = " VPN (LAN) ";
              service = "wg-quick-lan";
            }
          ];
          example = [
            {
              active_format = " WORK ";
              service = "some-service-name";
            }
          ];
          description = "list of block configurations, merged with the defauls";
        };
      };
    };

    screen-lock = {
      enable = mkEnableOption "automatic screen locker - xserver - screen-locker";

      command = mkOption {
        type = types.str;
        default = "${lib.getExe pkgs.i3lock} -n -c 000000";
        example = "\${lib.getExe pkgs.i3lock} -n -i lock.png";
        description = "Locker command to run";
      };

      cornerLock = {
        enable = my.mkDisableOption ''
          Move mouse to upper-left corner to lock instantly, lower-right corner to disable auto-lock.
        '';

        delay = mkOption {
          type = types.int;
          default = 5;
          example = 15;
          description = "How many seconds before locking this way";
        };
      };

      notify = {
        enable = my.mkDisableOption "Notify when about to lock the screen";

        delay = mkOption {
          type = types.int;
          default = 5;
          example = 15;
          description = ''
            How many seconds in advance should there be a notification.
            This value must be lesser than or equal to `cornerLock.delay` when both options are enabled.
          '';
        };
      };

      timeout = mkOption {
        type = types.ints.between 1 60;
        default = 15;
        example = 1;
        description = "Inactive time interval to lock the screen automatically";
      };
    };
  };

  config = {
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [
      # all fonts
      dejavu_fonts
      font-awesome_5
      montserrat
      noto-fonts
      # noto-fonts-cjk
      # noto-fonts-emoji
      roboto

      # portal for xdg-compatible applications
      xdg-desktop-portal-gtk
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk];
      config.common.default = "*";
    };
  };
}
