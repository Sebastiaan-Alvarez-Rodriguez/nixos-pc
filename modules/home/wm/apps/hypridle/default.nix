# tool to handle D-bus lock commands, and sleep on command.
{ config, lib, pkgs, nixosConfig ? {}, ... }: let
  cfg = config.my.home.wm.apps.hypridle;
in {
  options.my.home.wm.apps.hypridle = with lib; {
    enable = mkEnableOption "Enable hypridle";
    lock-cmd = mkOption {
      type = types.str;
      description = "Lock command";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.wm.hyprland.enable;
        message = "Must use hyprland to use hypridle";
      }
    ];

    services.hypridle = {
      enable = true;

      settings = {
        general = {
          before_sleep_cmd = cfg.lock-cmd;
          lock_cmd = cfg.lock-cmd;
        };
      };
    };
  };
}
