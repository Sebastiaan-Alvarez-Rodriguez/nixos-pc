{ config, lib, ... }: let
  cfg = config.my.profiles.laptop;
in {
  options.my.profiles.laptop = with lib; {
    enable = mkEnableOption "laptop profile";
    extra-silent = mkEnableOption "extra silenced laptop profile";
  };

  config = lib.mkIf cfg.enable {
    services.libinput.enable = true; # Enable touchpad support
    my.services.tlp = {
      enable = true;
      scaling-ac = if cfg.extra-silent then "powersave" else "performance";
    };
    my.hardware.fancontrol.enable = cfg.extra-silent;
    my.hardware.upower.enable = true; # Enable upower power management
    my.home.power-alert.enable = true; # Enable battery notifications
  };
}
