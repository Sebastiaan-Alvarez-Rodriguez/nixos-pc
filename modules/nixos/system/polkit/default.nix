# Polkit settings
{ config, lib, ... }: let
  cfg = config.my.system.polkit;
in {
  options.my.system.polkit = with lib; {
    enable = mkEnableOption "polkit configuration";
  };

  config = lib.mkIf cfg.enable {
    security.polkit = {
      enable = true;
    };
  };
}
