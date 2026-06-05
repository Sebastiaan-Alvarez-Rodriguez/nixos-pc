{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.rofi;
in {
  config = lib.mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      terminal = config.my.home.terminal.program; # null by default

      # use regular 'rofi' package for xserver gm?
      package = pkgs.rofi.override {
        plugins = with pkgs; [ rofi-emoji ];
      };
      extraConfig = {
        modi = "drun,run,window,emoji";
        separator-style = "dash";
        color-enabled = true;
      };
    };

    my.home.wm.hyprland.binds.launcher = let
      base = "rofi -combi-modi drun,run,window,emoji -show ";
    in {
      application = "${base} drun";
      executable = "${base} run";
      window = "${base} window";
      emoji = "${base} emoji";
    };
  };
}
