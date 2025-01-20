# fancontrol custom fancurve config
{ config, lib, ... }: let
  cfg = config.my.services.fancontrol;
in {
  options.my.services.fancontrol = with lib; {
    enable = mkEnableOption "fancontrol configuration";
    aggressiveness = mkOption {
      type = types.enum [ 1 2 3 ];
      default = 2;
      description = "Aggressiveness (higher means more aggressive)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.fancontrol = {
      enable = true;

      config = {
        # Set CPU scaling aggressively when power is not an issue
        CPU_SCALING_GOVERNOR_ON_AC = cfg.scaling-ac;
        CPU_SCALING_GOVERNOR_ON_BAT = cfg.scaling-bat;

        # Keep charge between 60% and 80% to preserve battery life
        START_CHARGE_THRESH_BAT0 = 60;
        STOP_CHARGE_THRESH_BAT0 = 80;

        # stop fancontrol from suspending usb devices
        USB_AUTOSUSPEND = 0;
      };
    };
  };
}
