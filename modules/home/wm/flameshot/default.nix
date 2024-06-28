{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.flameshot;
in {
  # NOTE: flameshot does not work well with river right now - https://github.com/flameshot-org/flameshot/blob/master/docs/Sway%20and%20wlroots%20support.md#river-wlroots-support
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.manager == "wayland";
        message = "Flameshot module requires wayland graphics manager (set my.home.gm.manager = \"wayland\")";
      }
    ];
    home.packages = [ pkgs.flameshot ];

  };
}
