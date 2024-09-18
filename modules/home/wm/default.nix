{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm;
in {
  imports = [ ./apps ];

  options.my.home.wm = with lib; {
    river.enable = mkEnableOption "Set river as window manager.";
    i3.enable = mkEnableOption "Set i3 as window manager.";
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
