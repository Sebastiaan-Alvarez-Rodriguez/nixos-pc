{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.cursor;
in {
  options.my.home.wm.apps.cursor = with lib; {
    enable = mkEnableOption "Enable cursor handling";
    package = mkOption {
      type = types.package;
      description = "Package delivering cursor (under <pkg>/share/icons/<icon>)";
    };
    name = mkOption {
      type = types.str;
      description = "name of package";
    };

    gtk = mkEnableOption "Enable gtk config generation";
    x11 = mkEnableOption "Enable gtk config generation";
    hyprcursor = mkEnableOption "Enable hyprcursor config generation";
    sway = mkEnableOption "Enable sway config generation";
    dotIcons = mkEnableOption "Enable dotIcons config generation";
    
  };
  config = lib.mkIf cfg.enable { # seb: NOTE https://github.com/anufrievroman/waypaper would also be nice.
    assertions = [
      {
        assertion = config.my.home.gm.wayland.enable;
        message = "wpaperd module requires wayland graphics manager (set my.home.gm.wayland.enable = true)";
      }
    ];
    
    home.pointerCursor = {
      inherit (cfg) name package;
      gtk.enable = cfg.gtk;
      x11.enable = cfg.x11;
      hyprcursor.enable = cfg.hyprcursor;
      sway.enable = cfg.sway;
      dotIcons.enable = cfg.dotIcons;
    };
    home.sessionVariables = {
      XCURSOR_THEME = lib.mkIf (cfg.x11 || cfg.hyprcursor) cfg.name;
      # "HYPRCURSOR_SIZE,24"
      HYPRCURSOR_THEME = lib.mkIf cfg.hyprcursor cfg.name;
      # "XCURSOR_SIZE,24"
    };
  };
}
