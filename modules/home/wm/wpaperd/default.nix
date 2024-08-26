{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.wpaperd;
  pkg = pkgs.wpaperd;
in {
  options.my.home.wm.apps.wpaperd = with lib; {
    image = lib.mkOption {
      type = with types; submodule {
        options = {
          path = lib.mkOption {
            type = with types; nullOr (path);
            default = null;
            description = "image file to use as lockscreen background";
          };
          url = lib.mkOption {
            type = with types; nullOr (str);
            default = null;
            description = "url to fetch image from, to be used as lockscreen background";
          };
          sha256 = lib.mkOption {
            type = with types; nullOr (str);
            default = null;
            description = "url image hash";
          };
        };
      };
    };
    systemdTarget = mkOption {
      type = with types; str;
      default = "graphical-session.target";
      description = "The systemd target that will automatically start the wpaperd service.";
    };
  };
  config = lib.mkIf cfg.enable { # seb: NOTE https://github.com/anufrievroman/waypaper would also be nice.
    assertions = [
      {
        assertion = config.my.home.gm.wayland.enable;
        message = "wpaperd module requires wayland graphics manager (set my.home.gm.wayland.enable = true)";
      }
    ];
    
    programs.wpaperd = { # seb: TODO https://stackoverflow.com/questions/21830670
      enable = true;
      package = pkg;
      settings.default = {
        path = if cfg.image.path != null then cfg.image.path else (builtins.fetchurl { inherit (cfg.image) url sha256; });
          # duration = "30m";
          apply-shadow = true;
          sorting = "random";
      };
    };

    systemd.user.services.wpaperd = {
      Unit = {
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkg}/bin/wpaperd";
        Restart = "on-failure";
      };
      Install.WantedBy = [ cfg.systemdTarget ];
    };
  };
}
