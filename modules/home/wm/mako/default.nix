{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.mako;
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.manager == "wayland";
        message = "Mako module requires wayland graphics manager (set my.home.gm.manager = \"wayland\")";
      }
    ];
    services.mako = { # wayland notifications
      enable = true;
      defaultTimeout = 3000;
    };
  };
}
