{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm;
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
    ./wlogout
    ./wpaperd
  ];

  options.my.home.wm = with lib; {
    river.enable = mkEnableOption "Set river as window manager.";
    i3.enable = mkEnableOption "Set i3 as window manager.";

    apps = mkOption { # applications to enhance window managers
      type = with types; submodule { options = {
        dunst = {
          enable = mkEnableOption "notifications - xserver wayland - dunst";
        };
        flameshot = {
          enable = mkEnableOption "screenshot-tool - wayland - flameshot";
        };
        grim = {
          enable = mkEnableOption "screenshot-tool - wayland - grim";
        };
        i3bar = { # seb TODO: checkout package & config
          enable = mkEnableOption "status-bar - xserver - i3bar";
          vpn = {
            enable = my.mkDisableOption "VPN configuration";
            blockConfigs = mkOption {
              type = with types; listOf (attrsOf str);
              default = [
                { active_format = " VPN "; service = "wg-quick-wg"; }
                { active_format = " VPN (LAN) "; service = "wg-quick-lan"; }
              ];
              example = [ { active_format = " WORK "; service = "some-service-name"; } ];
              description = "list of block configurations, merged with the defauls";
            };
          };
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
        screen-lock = {
          enable = mkEnableOption "automatic screen locker - xserver - screen-locker";
        };
        waybar = {
          enable = mkEnableOption "status-bar - wayland - waybar";
        };
        wpaperd = {
          enable = mkEnableOption "background-display - wayland - wpaperd";
        };
      };};
    };
  };

  config = {
    assertions = [ { assertion = !(cfg.i3.enable && cfg.river.enable); message = "Enable exactly one of `my.home.wm.i3.enable` and my.home.wm.river.enable`"; } ];
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
