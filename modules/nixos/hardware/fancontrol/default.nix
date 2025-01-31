# fancontrol custom fancurve config
{ config, lib, ... }: let
  cfg = config.my.hardware.fancontrol;
in {
  options.my.hardware.fancontrol = with lib; {
    enable = mkEnableOption "fancontrol configuration";
    aggressiveness = mkOption {
      type = types.enum [ 1 2 3 ];
      default = 2;
      description = "Aggressiveness (higher means more aggressive)";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.fancontrol = {
      enable = true;

      config = ''
        
      ''; # seb TODO: get a good config here, maybe using `pwmconfig`?
    };
  };
}
