{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.kanshi;
in {
  options.my.home.wm.apps.kanshi = with lib; {
    systemdTarget = mkOption {
      type = with types; str;
      default = "graphical-session.target";
      description = "The systemd target that will automatically start the kanshi service.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.wayland.enable;
        message = "Kanshi module requires wayland graphics manager (set my.home.gm.wayland.enable = true)";
      }
    ];

    services.kanshi = {
      enable = true;
      systemdTarget = cfg.systemdTarget;
    };
  };
}
