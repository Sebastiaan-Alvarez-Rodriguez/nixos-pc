{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.wlogout;
  mkDefaultOption = with lib; name: mkOption {
    type = types.bool;
    default = true;
    description = "enable ${name} option";
  };

  fetch-icon = name: ./icons/${name}.png;

  generate-css-entry = name: ''
    #${name} {
      margin: 10px;
      border-radius: 20px;
      background-image: image(url("${(fetch-icon name)}"));
    }
  '';
  generate-css = {button-hover-color, wallpaper, font-family ? "\"Fira Sans Semibold\", FontAwesome, Roboto, sans-serif"}: ''
    /*
      Stolen from https://github.com/mylinuxforwork/dotfiles/blob/main/dotfiles/wlogout/style.css
      Original work by Stephan Raabe (2023). Modified work: Removed dependency on external files.
    */
  
    * {
      font-family: ${font-family};
      background-image: none;
      transition: 20ms;
      box-shadow: none;
    }

    window {
      background: url("${builtins.toString wallpaper}");
      background-size: cover;
    }

    button {
      color: #FFFFFF;
      font-size:20px;

      background-repeat: no-repeat;
      background-position: center;
      background-size: 25%;

      border-style: solid;
      background-color: rgba(12, 12, 12, 0.3);
      border: 3px solid #FFFFFF;

      box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
    }

    button:focus,
    button:active,
    button:hover {
      color: ${button-hover-color};
      background-color: rgba(12, 12, 12, 0.5);
      border: 3px solid ${button-hover-color};
    }

    ${lib.concatStrings (lib.map generate-css-entry ["lock" "logout" "suspend" "hibernate" "shutdown" "reboot"])}
  '';
in {
  options.my.home.wm.wlogout = with lib; {
    enable = lib.mkEnableOption "Enable wlogout for logout, shutdown, hibernate etc";

    lock = mkDefaultOption "lock";
    hibernate = mkDefaultOption "hibernate";
    logout = mkDefaultOption "logout";
    shutdown = mkDefaultOption "shutdown";
    suspend = mkDefaultOption "suspend";
    reboot = mkDefaultOption "reboot";

    image = lib.mkOption {
      type = with types; submodule {
        options = {
          path = lib.mkOption {
            type = with types; nullOr (path);
            default = null;
            description = "image file to use as wlogout background";
          };
          url = lib.mkOption {
            type = with types; nullOr (str);
            default = null;
            description = "url to fetch image from, to be used as wlogout background";
          };
          sha256 = lib.mkOption {
            type = with types; nullOr (str);
            default = null;
            description = "url image hash";
          };
        };
      };
    };
    accent-color = mkOption {
      type = types.str;
      description = "CSS-like definition of the accent color for wlogout";
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

#  environment.etc."greetd/environments".text = ''
      programs.wlogout = {
        enable = true;
        package = pkgs.wlogout;
        style = generate-css {
          button-hover-color = cfg.accent-color;
          wallpaper = if cfg.image.path != null then cfg.image.path else (builtins.fetchurl { inherit (cfg.image) url sha256; });
        };
        ## TODO: get from https://github.com/mylinuxforwork/dotfiles/blob/main/dotfiles/wlogout/style.css and fix imports;
        layout = let
          mkLabel = { name, keybind, action ? "systemctl ${name}" }: {label = name; text = name; keybind = keybind; action = action; };
        in [] 
          ++ lib.optional cfg.lock (mkLabel {name = "lock"; keybind = "x"; action =  if config.my.home.wm.swaylock.enable then "${config.my.home.wm.swaylock.package}/bin/swaylock" else ""; })
          ++ lib.optional cfg.hibernate (mkLabel { name = "hibernate"; keybind = "h"; })
          ++ lib.optional cfg.logout (mkLabel { name = "logout"; keybind = "l"; action = if (config.my.home.wm.manager == "river") then let
              script = pkgs.writeShellScript "logout" ''
                sleep 0.2;
                killall -9 river.*;
              '';
            in "${script}"
            else "";
          })
          ++ lib.optional cfg.shutdown (mkLabel { name = "shutdown"; keybind = "s"; action = "systemctl poweroff"; })
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
