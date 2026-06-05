# An implementation of Hyprland theme 'wayle'
#
# user configuration for wayle
# Start this environment using command: `Hyprland`
{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.wm.hyprland.wayle;
in {
  options.my.home.wm.hyprland.wayle = with lib; {
    enable = mkEnableOption "Use wayle theme for hyprland";

    extra-config = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra lines to append to config of wayle";
    };
  };

  config = lib.mkIf cfg.enable {
    services.wayle = { # provides a shell containing a bar, power menu
      enable = true;
    } // cfg.extra-config;

    my.home.wm.hyprland.binds.extra-binds = {
      "Launcher"."Wayle".bindd = [
        "$mainMod, Z, $d open wayle panel, exec, wayle panel restart"
        "$mainMod SHIFT, Z, $d open wayle settings, exec, wayle panel settings"
      ];
    };
  };
}
