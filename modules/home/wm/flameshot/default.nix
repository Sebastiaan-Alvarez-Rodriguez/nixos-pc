{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.flameshot;
in {
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
