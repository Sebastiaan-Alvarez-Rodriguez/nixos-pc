{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm;
in {
  imports = [ ./i3 ./hyprland ./river ./apps ];

  config = lib.mkIf (cfg.i3.enable || cfg.hyprland.enable || cfg.river.enable) {
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [
      # # all fonts
      # dejavu_fonts
      # font-awesome_5
      # montserrat
      # noto-fonts
      # # noto-fonts-cjk
      # # noto-fonts-emoji
      # roboto

      # # portal for xdg-compatible applications
      # xdg-desktop-portal-gtk
    ];

    # xdg.portal = {
    #   enable = true;
    #   extraPortals = [pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk];
    #   config.common.default = "*";
    # };
  };
}
