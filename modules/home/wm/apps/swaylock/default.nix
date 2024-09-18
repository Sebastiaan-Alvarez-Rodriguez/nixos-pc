{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.swaylock;
in {
  options.my.home.wm.apps.swaylock = with lib; {
    enable = lib.mkEnableOption "Enable lockscreen";

    color = mkOption {
      type = with types; nullOr (str);
      default = null;
      description = "color to use as lockscreen background";
    };

    image = mkOption {
      type = with types; submodule {
        options = {
          path = mkOption {
            type = nullOr (path);
            default = null;
            description = "image file to use as lockscreen background";
          };
          url = mkOption {
            type = nullOr (str);
            default = null;
            description = "url to fetch image from, to be used as lockscreen background";
          };
          sha256 = mkOption {
            type = nullOr (str);
            default = null;
            description = "url image hash";
          };
          fade-in = mkOption {
            type = nullOr (int);
            default = null;
            description = "Fades-in lockscreen after given amount of seconds.";
          };
          pixelate = mkOption {
            type = nullOr (int);
            default = null;
            description = "Pixelates picture using pixel groups of this size.";
          };
        };
      };
    };

    package = mkOption {
      type = types.package;
      default = pkgs.swaylock-effects;
      description = "Package to use for swaylock.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.wayland.enable;
        message = "swaylock module requires wayland graphics manager (set my.home.gm.wayland.enable = true)";
      }
    ];

    programs.swaylock = {
      enable = true;
      package = cfg.package;
      settings = (lib.mkMerge [
        { 
          ignore-empty-password = true;
          show-failed-attempts = true;

          # indicator-caps-lock = true;
          # indicator-idle-visible = true;
          # indicator-radius = 200;
          # indicator-thickness = 20;
          # inside-color = 00000000; # was 0
          # key-hl-color = 00000066;
          # separator-color=00000000;

          font="Fira Sans Semibold";

          clock = true;
          timestr = "%R";
          datestr = "%a, %e of %B";

          # indicator style
          indicator = true; # show indicator?
          indicator-radius=200;
          indicator-thickness=20;
          indicator-caps-lock = true;

          # Define all colors

          key-hl-color = "00000066";
          separator-color = "00000000";

          inside-color= "00000033";
          inside-clear-color = "ffffff00";
          inside-caps-lock-color = "ffffff00";
          inside-ver-color = "ffffff00";
          inside-wrong-color = "ffffff00";

          ring-color = "ffffff";
          ring-clear-color = "ffffff";
          ring-caps-lock-color = "ffffff";
          ring-ver-color = "ffffff";
          ring-wrong-color = "ffffff";

          line-color="00000000";
          line-clear-color = "ffffffFF";
          line-caps-lock-color = "ffffffFF";
          line-ver-color = "ffffffFF";
          line-wrong-color = "ffffffFF";

          text-color = "ffffff";
          text-clear-color = "ffffff";
          text-ver-color = "ffffff";
          text-wrong-color = "ffffff";

          bs-hl-color = "ffffff";
          caps-lock-key-hl-color = "ffffffFF";
          caps-lock-bs-hl-color = "ffffffFF";
          disable-caps-lock-text = true;
          text-caps-lock-color = "ffffff";

        }
        (lib.mkIf (cfg.color != null) { color = cfg.color; })
        (lib.mkIf (cfg.image.path != null) { image = cfg.image.path; })
        (lib.mkIf (cfg.image.url != null) { image = (builtins.fetchurl { inherit (cfg.image) url sha256; }); })
        (lib.mkIf (cfg.image.fade-in != null) { fade-in = cfg.image.fade-in; })
        (lib.mkIf (cfg.image.pixelate != null) { effect-pixelate = cfg.image.pixelate; })
      ]);
    };
  };
}
