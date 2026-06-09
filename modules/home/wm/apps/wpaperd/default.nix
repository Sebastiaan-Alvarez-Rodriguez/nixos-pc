{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.wpaperd;
in {
  options.my.home.wm.apps.wpaperd = with lib; {
    image = lib.mkOption {
      type = with types; either path (listOf path);
      default = [];
      description = "image file(s) to use as lockscreen background. Can also point to a directory, in which case all files in the directory are used.";
    };

    duration = lib.mkOption {
      type = with types; nullOr str;
      default = null;
      description = "If set, amount of time to keep a background before switching to the next one (if multiple images specified)";
      example = "10m";
    };

    extra-config = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra settings to add to wpaperd settings";
    };
  };
  config = lib.mkIf cfg.enable { # seb: NOTE https://github.com/anufrievroman/waypaper would also be nice.
    assertions = [
      {
        assertion = config.my.home.gm.wayland.enable;
        message = "wpaperd module requires wayland graphics manager (set my.home.gm.wayland.enable = true)";
      }
    ];
    
    services.wpaperd = {
      enable = true;
      settings.default = let
        create_entry = item: {
          name = builtins.baseNameOf (toString item);
          path = item;
        };
        build_dir = images: pkgs.linkFarm "wallpapers" (builtins.map create_entry images);
      in {
        path = (lib.mkDefault (builtins.toString (if builtins.isList cfg.image then build_dir cfg.image else cfg.image)));
        duration = lib.mkIf (cfg.duration != null) cfg.duration;
        sorting = "random";
        mode = "center";
      } // cfg.extra-config;
    };
  };
}
