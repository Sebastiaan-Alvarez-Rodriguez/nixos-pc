{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.kanshi;
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.manager == "wayland";
        message = "Kanshi module requires wayland graphics manager (set my.home.gm.manager = \"wayland\")";
      }
    ];

    services.kanshi = { # display config tool
      enable = true;
      systemdTarget = if config.my.home.wm.manager == "river" then "river-session.target" else null;
    };
  };
}
