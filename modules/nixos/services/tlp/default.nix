# TLP power management
{ config, lib, ... }: let
  cfg = config.my.services.tlp;
in {
  options.my.services.tlp = with lib; {
    enable = mkEnableOption "TLP power management configuration";
    scaling-ac = mkOption {
      type = types.enum [ "performance" "powersave" ];
      default = "performance";
      description = "cpu freq when on AC";
    };
    scaling-bat = mkOption {
      type = types.enum [ "performance" "powersave" ];
      default = "powersave";
      description = "cpu freq when on battery";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tlp = {
      enable = true;

      settings = {
        # Set CPU scaling aggressively when power is not an issue
        CPU_SCALING_GOVERNOR_ON_AC = cfg.scaling-ac;
        CPU_SCALING_GOVERNOR_ON_BAT = cfg.scaling-bat;

        # Keep charge between 60% and 80% to preserve battery life
        START_CHARGE_THRESH_BAT0 = 60;
        STOP_CHARGE_THRESH_BAT0 = 80;

        # stop tlp from suspending usb devices
        USB_AUTOSUSPEND = 0;
      };
    };
  };
}
