# graphical managers, i.e. wayland, xserver
{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.gm;
in {
  options.my.home.gm = {
    manager = mkOption {
      type = with types; nullOr (enum [ "x" "wayland" ]);
      default = null;
      description = "Which graphics manager to use for home session";
    };
  };

  config = lib.mkIf (cfg.manager != null) (lib.mkMerge [
    (lib.mkIf (cfg.manager== "x") {
      xsession.enable = true;
      home.packages = with pkgs; [ xsel ];
    })
    (lib.mkIf (cfg.manager== "wayland") {
      # programs.xwayland.enable = true; 
      home.packages = [ pkgs.wl-clipboard pkgs.wl-clip-persist ];
      wayland.windowManager.sway = { # seb: TODO is this the way to get wayland? Probably not?
        enable = true;
        xwayland = true; # compatibility for xserver-only programs.
      };
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
};
