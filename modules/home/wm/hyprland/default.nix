{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.wm.hyprland;
in {
  imports = [ ./wayle.nix ];

  options.my.home.wm.hyprland = with lib; {
    enable = mkEnableOption "Set hyprland as window manager.";

    package = mkOption {
      type = types.package;
      default = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      description = "package to use";
    };

    portal-package = mkOption {
      type = types.package;
      default = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      description = "xdg portal package addon to use";
    };

    font-packages = mkOption {
      type = with types; listOf package;
      default = [ pkgs.nerd-fonts.symbols-only ];
      description = "font packages to use";
    };

    binds = {
      modkey = mkOption {
        type = types.str;
        default = "SUPER"; # This is the 'windows' key on most keyboards.
        description = "Modkey to use for issuing commands to hyprland";
      };

      lock = mkOption {
        type = types.str;
        default = "loginctl lock-session"; # loginctl is standard. Sends lock command over D-Bus. Advice: use hypr-idle to listen on D-Bus.
        description = "lock command";
      };

      repeat-rate = mkOption {
        type = types.int;
        default = 50;
        description = "Amount of keypresses per second when a key is in repeat-mode (i.e. button is held down)";
      };
      repeat-delay = mkOption {
        type = types.int;
        default = 300;
        description = "Amount of milliseconds a button must be held down for repeat-mode to activate";
      };

      browser.normal = mkOption {
        type = types.str;
        default = config.my.home.browser.program;
        description = "Default browser (regular window)";
      };
      browser.private = mkOption {
        type = types.str;
        default = "${config.my.home.browser.program} --private-window";
        description = "Default browser (private window)";
      };

      editor = mkOption {
        type = types.str;
        default = getExe (pkgs.${config.my.home.editor.program});
        description = "Default text editor";
      };

      terminal = mkOption {
        type = types.str;
        default = config.my.home.terminal.program;
        description = "Default terminal";
      };

      launcher = {
        application = mkOption {
          type = types.str;
          default = "";
          description = "Launcher application search command (i.e. for .desktop-like executables)";
        };
        executable = mkOption {
          type = types.str;
          default = "";
          description = "Launcher executable search command (i.e. for executables on $PATH)";
        };
        window = mkOption {
          type = types.str;
          default = "";
          description = "Launcher window list command";
        };
        emoji = mkOption {
          type = types.str;
          default = "";
          description = "Launcher emoji picker list command";
        };
        calc = mkOption {
          type = types.str;
          default = "";
          description = "Launcher calc picker list command";
        };
      };

      brightness = {
        kbd = {
          up = mkOption {
            type = types.str;
            default = ''${pkgs.brightnessctl} -d "*keyboard*" set 5%+'';
            description = "Keyboard brightness up command";
          };
          down = mkOption {
            type = types.str;
            default = ''${pkgs.brightnessctl} -d "*keyboard*" set 5%-'';
            description = "Keyboard brightness down command";
          };
        };
        mon = {
          up = mkOption {
            type = types.str;
            default = ''${pkgs.brightnessctl} set 5%+'';
            description = "Monitor brightness up command";
          };
          down = mkOption {
            type = types.str;
            default = ''${pkgs.brightnessctl} set 5%-'';
            description = "Monitor brightness down command";
          };
        };
      };

      media = {
        play = mkOption {
          type = types.str; # default assumes playerctl is used
          default = "playerctl play-pause";
          description = "Play media command";
        };
        pause = mkOption {
          type = types.str;
          default = "playerctl play-pause";
          description = "Pause media command";
        };
        next = mkOption {
          type = types.str;
          default = "playerctl next";
          description = "Next media command";
        };
        prev = mkOption {
          type = types.str;
          default = "playerctl previous";
          description = "Prev media command";
        };
      };

      audio = {
        raise = mkOption {
          type = types.str; # default assumes wireplumber
          default = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          description = "Raise volume audio command";
        };
        lower = mkOption {
          type = types.str;
          default = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          description = "Lower volume audio command";
        };
        togglemute = mkOption {
          type = types.str;
          default = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          description = "Mute audio command";
        };
        togglemicmute = mkOption {
          type = types.str;
          default = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          description = "Mute mic audio command";
        };
      };
      extra-binds = mkOption {
        type = types.attrs;
        default = {};
        example = litteralExample ''
          { "any section"."subsection".bindd = [ "$mainMod, G, $d this is an explanation, exec, my-command-here param1 param2" ]; }
        '';
        description = "Extra bindings to append to config of hyprland. Use \$d to automatically insert your commands in the section you defined";
      };
    };
    extra-config = mkOption {
      type = types.lines;
      default = "";
      description = "Extra lines to append to config of hyprland";
    };
  };

  config = lib.mkIf config.my.home.wm.hyprland.enable {
    assertions = [ { assertion = config.my.home.gm.wayland.enable; message = "hyprland module requires wayland graphics manager (set my.home.gm.wayland.enable = true)"; } ];

    wayland.windowManager.hyprland = {
      enable = true;
      package = cfg.package;
      portalPackage = cfg.portal-package;

      configType = lib.mkForce "lua";
      # settings = let
      #     mk-section-name = section-names: "[${builtins.concatStringsSep "|" section-names}]";
      #     mk-leaf-list = name: lst: builtins.map (s: lib.replaceString "$d" name s) lst; # in a list-leaf, replaces all "$d" with the full section name
      #     mk-leaf = path: lst: { "${lib.last path}" = mk-leaf-list (mk-section-name (lib.init path)) lst; }; # returns a dict like { bindd = <list-leaf> };
      #     mk-section-list = d: lib.mapAttrsToListRecursive (path: value: mk-leaf path value) d; # makes a list like [ { bindd = <list-leaf>; } { bindd = <other-leaf>; }]
      #     mk-keybinds = ds: lib.zipAttrsWith (name: values: lib.flatten values) (builtins.concatMap mk-section-list ds); # takes a list of keybind settings, translates to one long list of dicts and merges everything to one dict.
      #     # see https://wiki.hypr.land/Configuring/Binds
      # in {};
      settings = {};
      extraConfig = ''
        hl.config({
          autogenerated = false
        })
        local MAINMOD = "${cfg.binds.modkey}";
        local LOCKCMD = "${cfg.binds.lock}";
        local TERMINAL = "${cfg.binds.terminal}";
        local EXPLORER = "";
        local EDITOR = "${cfg.binds.editor}";
        local BROWSER = "${cfg.binds.browser.normal}";
        local BROWSERPRIVATE = "${cfg.binds.browser.private}";

        local function bind_base(mods, key, cat, sub, desc, obj, flags)
          local full = string.format("[%s|%s] %s", cat, sub, desc)

          -- flags.description = full
          local options = {}
          if flags then
            for k, v in pairs(flags) do options[k] = v end
          end
          options.description = full

          hl.bind(mods, key, obj, options)
        end
        local function bind(mods, key, cat, sub, desc, obj)
          bind_base(mods, key, cat, sub, desc, obj, {})
        end
        local function binde(mods, key, cat, sub, desc, obj)
          bind_base(mods, key, cat, sub, desc, obj, { locked = true })
        end
        local function bindm(mods, key, cat, sub, desc, obj)
          bind_base(mods, key, cat, sub, desc, obj, { mouse = true })
        end

        hl.input = {
          repeat_rate = ${builtins.toString cfg.binds.repeat-rate},
          repeat_delay = ${builtins.toString cfg.binds.repeat-delay}
        }

        -- required for togglesplit
        hl.dwindle = {
          preserve_split = true
        }

        --------------------------------------------------------------------------------
        -- Windows Management
        --------------------------------------------------------------------------------
        -- main

        bind(MAINMOD, "F", "Windows Management", "Main", "toggle fullscreen", hl.dsp.window.fullscreen({mode="fullscreen", action="toggle"}))
        bind(MAINMOD .. "+SHIFT", "F", "Windows Management", "Main", "toggle fullscreen (keeping gaps)", hl.dsp.window.fullscreen({mode="maximized", action="toggle"}))
        bind(MAINMOD, "Q", "Windows Management", "Main", "close window", hl.dsp.window.close())
        bind(MAINMOD .. "+SHIFT", "Q", "Windows Management", "Main", "force (kill) window", hl.dsp.window.kill())
        bind(MAINMOD, "X", "Windows Management", "Main", "lock screen", hl.dsp.exec_cmd(LOCKCMD))
        bind(MAINMOD, "W", "Windows Management", "Main", "Toggle floating", hl.dsp.window.float({action="toggle"}))
        bind(MAINMOD, "G", "Windows Management", "Main", "toggle group", hl.dsp.group.toggle())
        bind(MAINMOD .. "+SHIFT", "F", "Windows Management", "Main", "toggle pin on focused window", hl.dsp.window.pin({action="toggle"}))

        -- Group Navigation
        bind(MAINMOD .. "+SHIFT", "H", "Windows Management", "Group Navigation", "change active group backwards", hl.dsp.group.prev({}))
        bind(MAINMOD .. "+SHIFT", "L", "Windows Management", "Group Navigation", "change active group forwards", hl.dsp.group.next({}))

        -- Change focus
        bind(MAINMOD, "J", "Windows Management", "Change focus", "cycle to next window", hl.dsp.window.cycle_next({ next = true }))
        bind(MAINMOD, "K", "Windows Management", "Change focus", "cycle to previous window", hl.dsp.window.cycle_next({ next = false }))

        -- Move window across workspace
        bind(MAINMOD .. "+SHIFT", "J", "Windows Management", "Move window across workspace", "swap active window with next window", hl.dsp.window.swap({ next = true }))
        bind(MAINMOD .. "+SHIFT", "K", "Windows Management", "Move window across workspace", "swap active window with previous window", hl.dsp.window.swap({ prev = true }))

        -- mouse actions
        bindm(MAINMOD, "mouse:272", "Windows Management", "Move window across workspace", "hold to move window", hl.dsp.window.drag())
        bindm(MAINMOD, "mouse:273", "Windows Management", "Move window across workspace", "hold to resize window", hl.dsp.window.resize())

        -- Splits
        bind(MAINMOD, "H", "Windows Management", "Splits", "splitratio decrease", hl.dsp.layout("splitratio -0.05"))
        bind(MAINMOD, "L", "Windows Management", "Splits", "splitratio increase", hl.dsp.layout("splitratio 0.05"))
        bind(MAINMOD, "S", "Windows Management", "Splits", "toggle split horizontal/vertical", hl.dsp.layout("togglesplit"))

        --------------------------------------------------------------------------------
        -- Launcher
        --------------------------------------------------------------------------------
        -- Apps
        bind(MAINMOD, "Return", "Launcher", "Apps", "terminal emulator", hl.dsp.exec_cmd(TERMINAL))
        bind(MAINMOD, "C", "Launcher", "Apps", "text editor", hl.dsp.exec_cmd(EDITOR))
        bind(MAINMOD, "B", "Launcher", "Apps", "web browser", hl.dsp.exec_cmd(BROWSER))
        bind(MAINMOD .. "+SHIFT", "B", "Launcher", "Apps", "private web browser", hl.dsp.exec_cmd(BROWSERPRIVATE))

        -- Launcher menus
        bind(MAINMOD, "D", "Launcher", "Launcher menus", "application finder", hl.dsp.exec_cmd("${cfg.binds.launcher.application}"))
        bind(MAINMOD, "C", "Launcher", "Launcher menus", "calculator", hl.dsp.exec_cmd("${cfg.binds.launcher.calc}"))
        bind(MAINMOD, "E", "Launcher", "Launcher menus", "file finder", hl.dsp.exec_cmd("${cfg.binds.launcher.executable}"))
        bind(MAINMOD, "TAB", "Launcher", "Launcher menus", "window (focus) switcher", hl.dsp.exec_cmd("${cfg.binds.launcher.window}"))
        bind(MAINMOD, "slash", "Launcher", "Launcher menus", "keybindings hint menu", hl.dsp.exec_cmd("pkill -x rofi || hyde-shell keybinds_hint c"))
        bind(MAINMOD, "semicolon", "Launcher", "Launcher menus", "emoji picker menu", hl.dsp.exec_cmd("${cfg.binds.launcher.emoji}"))
        bind(MAINMOD .. "+SHIFT", "semicolon", "Launcher", "Launcher menus", "glyph picker", hl.dsp.exec_cmd("pkill -x rofi || hyde-shell glyph-picker"))
        bind(MAINMOD, "V", "Launcher", "Launcher menus", "clipboard", hl.dsp.exec_cmd("pkill -x rofi || hyde-shell cliphist -c"))
        bind(MAINMOD .. "+SHIFT", "V", "Launcher", "Launcher menus", "clipboard manager", hl.dsp.exec_cmd("pkill -x rofi || hyde-shell cliphist"))
        bind(MAINMOD .. "+SHIFT", "A", "Launcher", "Launcher menus", "select rofi launcher shape", hl.dsp.exec_cmd("pkill -x rofi || hyde-shell rofiselect"))

        --------------------------------------------------------------------------------
        -- Workspaces
        --------------------------------------------------------------------------------
        -- Navigation
        for i = 1, 9 do
            bind(MAINMOD, tostring(i), "Workspaces", "Navigation", "navigate to workspace " .. i, hl.dsp.focus({ workspace = i }))
        end
        bind(MAINMOD, "mouse_down", "Workspaces", "Navigation", "scroll to next workspace", hl.dsp.focus({ workspace = "e+1" }))
        bind(MAINMOD, "mouse_up", "Workspaces", "Navigation", "scroll to previous workspace", hl.dsp.focus({ workspace = "e-1" }))

        -- Move window to workspace
        for i = 1, 9 do
            bind(MAINMOD .. "+SHIFT", tostring(i), "Workspaces", "Move window to workspace", "move to workspace " .. i, hl.dsp.window.move({ workspace = i, follow = false }))
        end
        bind(MAINMOD .. "+CONTROL+SHIFT", "J", "Workspaces", "Move window to workspace", "move window to next relative workspace", hl.dsp.window.swap({ next = true }))
        bind(MAINMOD .. "+CONTROL+SHIFT", "K", "Workspaces", "Move window to workspace", "Move window to previous relative workspace", hl.dsp.window.swap({ prev = true }))

        -- Scratchpad
        bind(MAINMOD, "0", "Workspaces", "Scratchpad", "toggle scratchpad", hl.dsp.workspace.toggle_special("special"))
        bind(MAINMOD .. "+SHIFT", "0", "Workspaces", "Scratchpad", "move to scratchpad", hl.dsp.window.move({ workspace = "special:special", follow = false }))

        --------------------------------------------------------------------------------
        -- Hardware Controls
        --------------------------------------------------------------------------------
        -- Audio
        binde("", "XF86AudioRaiseVolume", "Hardware Controls", "Audio", "increase volume", hl.dsp.exec_cmd([[${cfg.binds.audio.raise}]]))
        binde("", "XF86AudioLowerVolume", "Hardware Controls", "Audio", "decrease volume", hl.dsp.exec_cmd([[${cfg.binds.audio.lower}]]))
        binde("", "XF86AudioMute", "Hardware Controls", "Audio", "toggle mute", hl.dsp.exec_cmd([[${cfg.binds.audio.togglemute}]]))
        binde("", "XF86AudioMicMute", "Hardware Controls", "Audio", "toggle mic mute", hl.dsp.exec_cmd([[${cfg.binds.audio.togglemicmute}]]))

        -- Media
        binde("", "XF86AudioPlay", "Hardware Controls", "Media", "play media", hl.dsp.exec_cmd([[${cfg.binds.media.play}]]))
        binde("", "XF86AudioPause", "Hardware Controls", "Media", "pause media", hl.dsp.exec_cmd([[${cfg.binds.media.pause}]]))
        binde("", "XF86AudioNext", "Hardware Controls", "Media", "next media", hl.dsp.exec_cmd([[${cfg.binds.media.next}]]))
        binde("", "XF86AudioPrev", "Hardware Controls", "Media", "previous media", hl.dsp.exec_cmd([[${cfg.binds.media.prev}]]))

        -- Brightness
        binde("", "XF86MonBrightnessUp", "Hardware Controls", "Brightness", "monitor brightness up", hl.dsp.exec_cmd([[${cfg.binds.brightness.mon.up}]]))
        binde("", "XF86MonBrightnessDown", "Hardware Controls", "Brightness", "monitor brightness down", hl.dsp.exec_cmd([[${cfg.binds.brightness.mon.down}]]))
        binde("", "XF86KbdBrightnessUp", "Hardware Controls", "Brightness", "keyboard brightness up", hl.dsp.exec_cmd([[${cfg.binds.brightness.kbd.up}]]))
        binde("", "XF86KbdBrightnessDown", "Hardware Controls", "Brightness", "keyboard brightness down", hl.dsp.exec_cmd([[${cfg.binds.brightness.kbd.down}]]))

        --------------------------------------------------------------------------------
        -- Utilities
        --------------------------------------------------------------------------------
        -- Screen Capture
        bind(MAINMOD, "P", "Utilities", "Screen Capture", "screenshot select", hl.dsp.exec_cmd([[hyde-shell screenshot s]]))
        bind(MAINMOD .. "+SHIFT", "P", "Utilities", "Screen Capture", "screenshot monitor", hl.dsp.exec_cmd([[hyde-shell screenshot m]]))
        bind(MAINMOD .. "+ALT", "P", "Utilities", "Screen Capture", "print all monitors", hl.dsp.exec_cmd([[hyde-shell screenshot p]]))
        bind(MAINMOD .. "+SHIFT", "period", "Utilities", "Screen Capture", "color picker", hl.dsp.exec_cmd([[hyprpicker -an]]))

        -- Login control
        bind(MAINMOD, "X", "Utilities", "Login control", "lock session", hl.dsp.exec_cmd([[${cfg.binds.lock}]]))
        
      '' + cfg.extra-config;
      # "Theming and Wallpaper" = {
      #   "Main".bindd = [
      # "$mainMod Control, A, $d select global wallpaper , exec, hyde-shell wallpaper -SG"
      # "$mainMod Control, S, $d next global wallpaper , exec, hyde-shell wallpaper -Gn"
      # "$mainMod Control SHIFT, S, $d previous global wallpaper , exec, hyde-shell wallpaper -Gp"
      # "$mainMod Control, S, $d next waybar layout, exec, hyde-shell wbarconfgen n"
      # "$mainMod Control SHIFT, S, $d previous waybar layout, exec, hyde-shell wbarconfgen p"
      # "$mainMod Control, D, $d wallbash mode selector , exec, pkill -x rofi || hyde-shell wallbashtoggle -m"
      # "$mainMod Control, F, $d select a theme, exec, pkill -x rofi || hyde-shell themeselect"
      # "$mainMod Control, G, $d select animations, exec, pkill -x rofi || hyde-shell animations --select"
    };

    fonts.fontconfig.enable = true; # to load fonts
    home.packages = cfg.font-packages;
  };
}
