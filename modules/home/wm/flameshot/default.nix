{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.flameshot;
in {
  # NOTE: flameshot does not work well with river right now - https://github.com/flameshot-org/flameshot/blob/master/docs/Sway%20and%20wlroots%20support.md#river-wlroots-support
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.wayland.enable;
        message = "Flameshot module requires wayland graphics manager (set my.home.gm.wayland.enable = true)";
      }
    ];
    home.packages = [ pkgs.flameshot ];

  };
}
