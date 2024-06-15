{ config, lib, ... }: let
  cfg = config.my.profiles.gtk;
in {
  options.my.profiles.gtk = with lib; {
    enable = mkEnableOption "gtk profile";
  };

  config = lib.mkIf cfg.enable {
    programs.dconf.enable = true; # Allow setting GTK configuration using home-manager
    my.home.gtk.enable = true; # GTK theme configuration
  };
}
