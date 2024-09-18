{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps;
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

  options.my.home.wm.apps = with lib; {
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
  };

  config = { };
}
