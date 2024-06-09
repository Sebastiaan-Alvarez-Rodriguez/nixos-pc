{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.wpaperd;
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.manager == "wayland";
        message = "wpaperd module requires wayland graphics manager (set my.home.gm.manager = \"wayland\")";
      }
    ];
    programs.wpaperd = {
      enable = true;
      settings = {
        default = {
          path = "../../res/background"; # seb: NOTE was absolute path: "${config.home.homeDirectory}/Pictures/Wallpapers"
          duration = "30m";
          apply-shadow = true;
          sorting = "random";
        };
      };
    };
  };
}
