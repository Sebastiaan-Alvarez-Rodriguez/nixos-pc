{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.swaylock;
in {
  options.my.home.wm.swaylock = with lib; {
    enable = lib.mkEnableOption "Enable lockscreen";

    color = lib.mkOption {
      type = with types; nullOr (str);
      default = null;
      description = "color to use as lockscreen background";
    };
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
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = config.my.home.gm.manager == "wayland";
          message = "swaylock module requires wayland graphics manager (set my.home.gm.manager = \"wayland\")";
        }

      ];

      programs.swaylock = {
        enable = true;
        package = pkgs.swaylock-effects;
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
            # effects
            # fade-in = 1;
            effect-pixelate=5;

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
        ]);
      };
    }
    (lib.mkIf (config.my.home.wm.manager == "river") {
      programs.river.bindings.normal = {
        "${config.my.home.wm.river.modkey} X" = "spawn '${config.programs.swaylock.package}/bin/swaylock'";
      };
    })
  ]);
}
