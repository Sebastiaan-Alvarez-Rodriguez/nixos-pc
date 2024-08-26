{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.grim;
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.wayland.enable;
        message = "Grim module requires wayland graphics manager (set my.home.gm.wayland.enable = true)";
      }
    ];
    home.packages = [ pkgs.grim ];
  };
}
