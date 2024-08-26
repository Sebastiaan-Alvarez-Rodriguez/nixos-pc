{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.rofi;
  picked_pkg = if config.my.home.gm.wayland.enable then pkgs.rofi-wayland else pkgs.rofi;
in {
  config = lib.mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      terminal = config.my.home.terminal.program; # null by default
      # Used to be
      # terminal = "${pkgs.foot}/bin/foot";

      # use regular 'rofi' package for xserver gm?
      package = picked_pkg.override {
        plugins = with pkgs; [ rofi-emoji ];
      };
      extraConfig = {
        modi = "drun,ssh,combi";
        separator-style = "dash";
        color-enabled = true;
      };
      # seb: TODO does this config do anything nice?
      theme = "gruvbox-dark-hard";
    };
  };
}
