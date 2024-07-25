{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.wlogout;
  mkDefaultOption = with lib; name: mkOption {
    type = types.bool;
    default = true;
    description = "enable ${name} option";
  };
in {
  options.my.home.wm.wlogout = with lib; {
    enable = lib.mkEnableOption "Enable wlogout for logout, shutdown, hibernate etc";

    lock = mkDefaultOption "lock";
    hibernate = mkDefaultOption "hibernate";
    logout = mkDefaultOption "logout";
    shutdown = mkDefaultOption "shutdown";
    suspend = mkDefaultOption "suspend";
    reboot = mkDefaultOption "reboot";

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
        fade-in = lib.mkOption {
          type = with types; nullOr (int);
          default = null;
          description = "Fades-in lockscreen after given amount of seconds.";
        };
        pixelate = lib.mkOption {
          type = with types; nullOr (int);
          default = null;
          description = "Pixelates picture using pixel groups of this size.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = let
        actionsEnabled = [ cfg.lock cfg.hibernate cfg.logout cfg.shutdown cfg.suspend cfg.reboot ];
        supportedLockers = [ "swaylock" ];
        enabledLockerTests = [ config.my.home.wm.swaylock.enable ];
        supportedLogouts = [ "river" ];
        enabledLogoutsTests = [ (config.my.home.wm.manager == "river") ];
      in [
        { assertion = cfg.enable -> (builtins.any (i: i) actionsEnabled); message = "No enabled actions. Enable 'lock', 'hibernate', 'logout', 'shutdown', 'suspend', and/or 'reboot'."; }
        { assertion = cfg.lock -> (builtins.any (i: i) enabledLockerTests); message = "No enabled supported locker found. Please configure to use any of the following lock tools: ${builtins.toString supportedLockers}"; }
        { assertion = cfg.logout -> (builtins.any (i: i) enabledLogoutsTests); message = "No enabled supported window managers for logging out found. Please configure to use any of the following window managers: ${builtins.toString supportedLogouts}"; }
      ];

      programs.wlogout = {
        enable = true;
        package = pkgs.wlogout;
        style = ./style.css; ## TODO: get from https://github.com/mylinuxforwork/dotfiles/blob/main/dotfiles/wlogout/style.css and fix imports;
        layout = let
          mkLabel = { name, keybind, extraConfig ? {} }: {label = name; text = name; keybind = keybind; action = "systemctl ${name}"; } // extraConfig;
        in [] 
          ++ lib.optional cfg.lock (mkLabel {name = "lock"; keybind = "x"; extraConfig = (lib.mkMerge [
            {}
            (lib.mkIf config.my.home.wm.swaylock.enable { action = "${config.my.home.wm.swaylock.package}"; })
          ]); })
          ++ lib.optional cfg.hibernate (mkLabel { name = "hibernate"; keybind = "h"; })
          ++ lib.optional cfg.logout (mkLabel { name = "logout"; keybind = "l"; extraConfig = (lib.mkMerge [
            {}
            (lib.mkIf (config.my.home.wm.manager == "river") {
              action = let
                script =  pkgs.writeShellScript "logout" ''
                  sleep 0.2;
                  killall -9 river.*;
                '';
              in "${script}";
            })
          ]); })
          ++ lib.optional cfg.shutdown (mkLabel { name = "shutdown"; keybind = "s"; extraConfig = { action = "systemctl poweroff"; }; })
          ++ lib.optional cfg.suspend (mkLabel { name = "suspend"; keybind = "u"; })
          ++ lib.optional cfg.reboot (mkLabel {name = "reboot"; keybind = "r"; });
      };
    }
    (lib.mkIf (config.my.home.wm.manager == "river") {
      programs.river.bindings.normal = {
        "${config.my.home.wm.river.modkey} C" = "spawn '${config.programs.wlogout.package}/bin/wlogout'";
      };
    })
  ]);
}
