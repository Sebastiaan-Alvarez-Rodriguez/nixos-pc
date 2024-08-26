# graphical managers, i.e. wayland, xserver
{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.gm;
in {
  options.my.home.gm = with lib; {
    x.enable = mkEnableOption "Use x as graphics manager";
    wayland.enable = mkEnableOption "Use wayland as graphics manager";
  };

  config = (lib.mkMerge [
    { assertions = [ { assertion = !(cfg.x.enable && cfg.wayland.enable); message = "Enable exactly one of `my.home.gm.x.enable` and my.home.gm.wayland.enable`"; } ]; }
    (lib.mkIf cfg.x.enable {
      xsession.enable = true;
      home.packages = with pkgs; [ xsel ];
    })
    (lib.mkIf cfg.wayland.enable {
      # programs.xwayland.enable = true; 
      home.packages = [ pkgs.wl-clipboard pkgs.wl-clip-persist ];
      # seb: NOTE we don't enable wayland here. The wayland window managers, i.e. wm.river, already activate wayland.
      home.sessionVariables = {
        MOZ_ENABLE_WAYLAND = 1;
        QT_QPA_PLATFORMTHEME = "qt5ct";
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
        SDL_VIDEODRIVER = "wayland";
        _JAVA_AWT_WM_NONREPARENTING = 1;
        GDK_BACKEND = "wayland";
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
      };
    })
  ]);
}
