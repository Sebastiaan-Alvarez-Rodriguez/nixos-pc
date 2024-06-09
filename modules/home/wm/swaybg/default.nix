{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.swaybg;
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.manager == "wayland";
        message = "Swaybg module requires wayland graphics manager (set my.home.gm.manager = \"wayland\")";
      }
    ];
    programs.swaybg-dynamic = { # backgrounds
    # seb TODO: Need to import swaybg-dynamic from the original config if I want a changing background.
      enable = true;
      mode = "fill";
      systemdTarget = if config.my.home.wm.manager == "river" then "river-session.target" else null;
    };
  };
}
