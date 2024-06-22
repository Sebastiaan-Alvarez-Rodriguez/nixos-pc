{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.kanshi;
in {
  options.my.home.wm.kanshi = with lib; {
    systemdTarget = mkOption {
      type = with types; str;
      default = "graphical-session.target";
      description = "The systemd target that will automatically start the kanshi service.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.manager == "wayland";
        message = "Kanshi module requires wayland graphics manager (set my.home.gm.manager = \"wayland\")";
      }
    ];

    services.kanshi = {
      enable = true;
      systemdTarget = cfg.systemdTarget;
    };
  };
}
