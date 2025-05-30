{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.mako;
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.wayland.enable;
        message = "Mako module requires wayland graphics manager (set my.home.gm.wayland.enable = true)";
      }
    ];
    services.mako = { # wayland notifications
      enable = true;
      settings.default-timeout = 3000;
    };
  };
}
