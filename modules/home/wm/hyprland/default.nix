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
      default = [ pkgs.nerd-fonts.symbols-only pkgs.nerd-fonts.jetbrains-mono pkgs.noto-fonts ];
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
      extras = mkOption {
        type = with types; listOf (submodule {
          options.type = mkOption {
            type = enum [ "bind" "binde" "bindm" ];
            default = "bind";
            description = "Bind type to set: normal bind, bind with keylock, or bind with mouse input";
          };
          options.key = mkOption {
            type = str;
            example = litteralExample ''${config.my.home.wm.hyprland.binds.modkey} + SHIFT + Z'';
            description = "Keybind to use";
          };
          options.cat = mkOption {
            type = str;
            description = "Category for keybind (free name)";
          };
          options.sub = mkOption {
            type = str;
            description = "Subcategory for keybind (free name)";
          };
          options.desc = mkOption {
            type = str;
            description = "Description for keybind, what does it do?";
          };
          options.action = mkOption {
            type = str;
            description = "Action to perform. For inspiration, see https://wiki.hypr.land/Configuring/Basics/Dispatchers/";
          };
        });
        default = [];
        example = litteralExample ''
          [ { key="${mod} + F" cat="Windows Management"; sub="Main"; desc="toggle fullscreen" action="hl.dsp.window.fullscreen({ mode = \"fullscreen\"})"} ]
        '';
        description = "Extra keybinds to add";
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
      settings = let
        lua = lib.generators.mkLuaInline;
        bind_base = key: cat: sub: desc: extras: action: {
          _args = [ key (lua action) ({ description = "[${cat}|${sub}] ${desc}"; } // extras) ];
        };
        bind  = key: cat: sub: desc: action: (bind_base key cat sub desc {} action);
        binde = key: cat: sub: desc: action: (bind_base key cat sub desc { locked = true; } action);
        bindm = key: cat: sub: desc: action: (bind_base key cat sub desc { mouse = true; } action);
        mod  = cfg.binds.modkey;
        exec = cmd: ''hl.dsp.exec_cmd([[${cmd}]])'';
        fcs  = ws: ''hl.dsp.focus({ workspace="${ws}"})'';
        fcsd = dr: ''hl.dsp.focus({ direction="${dr}"})'';
        lyt  = arg: ''hl.dsp.layout("${arg}")'';
        tspl = nme: ''hl.dsp.workspace.toggle_special("${nme}")'';
        wcyc = nxt: ''hl.dsp.window.cycle_next({next=${nxt}})'';
        wflt = act: ''hl.dsp.window.float({ action="${act}"})'';
        wmvw = ws: ''hl.dsp.window.move({ workspace="${ws}", follow=false})'';
        wmvd = dr: ''hl.dsp.window.move({ direction="${dr}"})'';
        wpin = act: ''hl.dsp.window.pin({action="${act}"})'';
        wswp = nxt: ''hl.dsp.window.swap({ ${nxt}=true })'';
        fs   = mode: ''hl.dsp.window.fullscreen({ mode = "${mode}"})'';

        amount-workspaces = 9;
        workspaces = (lib.map builtins.toString (lib.range 1 amount-workspaces));
      in {
        config = {
          input = {
            repeat_rate = cfg.binds.repeat-rate;
            repeat_delay = cfg.binds.repeat-delay;
          };
          dwindle = {
            preserve_split = true;
          };
        };
        bind = let
          select-fun = name: if (name == "bind") then bind else if (name == "binde") then binde else bindm;
          process-extras = i: ((select-fun i.type) i.key i.cat i.sub i.desc i.action);
        in [
          # Windows management
          # main
          (bind "${mod} + F" "Windows Management" "Main" "toggle fullscreen" (fs "fullscreen"))
          (bind "${mod} + SHIFT + F" "Windows Management" "Main" "toggle fullscreen (keep gaps)" (fs "maximized"))
          (bind "${mod} + Q" "Windows Management" "Main" "close window" "hl.dsp.window.close()")
          (bind "${mod} + SHIFT + Q" "Windows Management" "Main" "force close window" "hl.dsp.window.kill()")
          (bind "${mod} + W" "Windows Management" "Main" "toggle floating" (wflt "toggle"))
          (bind "${mod} + G" "Windows Management" "Main" "toggle group" "hl.dsp.group.toggle()")
          (bind "${mod} + P" "Windows Management" "Main" "pin focused window" (wpin "toggle"))
          # group navigation
          (bind "${mod} + SHIFT + H" "Windows Management" "Group Navigation" "change active group backwards" "hl.dsp.group.prev()")
          (bind "${mod} + SHIFT + L" "Windows Management" "Group Navigation" "change active group forwards" "hl.dsp.group.next()")
          # change focus
          (bind "${mod} + J" "Windows Management" "Change focus" "cycle to next window" (wcyc "true"))
          (bind "${mod} + K" "Windows Management" "Change focus" "cycle to previous window" (wcyc "false"))
          # Move window across workspace
          (bind "${mod} + SHIFT + J" "Windows Management" "Move window across workspace" "swap active window with next window" (wswp "next"))
          (bind "${mod} + SHIFT + K" "Windows Management" "Move window across workspace" "swap active window with previous window" (wswp "prev"))
          # mouse actions
          (bindm "${mod} + mouse:272" "Windows Management" "Move window across workspace" "hold to move window" "hl.dsp.window.drag()")
          (bindm "${mod} + mouse:273" "Windows Management" "Move window across workspace" "hold to resize window" "hl.dsp.window.resize()")
          # splits
          (bind "${mod} + H" "Windows Management" "Splits" "splitratio decrease" (lyt "splitratio -0.05"))
          (bind "${mod} + L" "Windows Management" "Splits" "splitratio increase" (lyt "splitratio 0.05"))
          (bind "${mod} + S" "Windows Management" "Splits" "toggle split horizontal/vertical" (lyt "togglesplit"))

          # Launcher
          # apps
          (bind "${mod} + Return" "Launcher" "Apps" "terminal emulator" (exec(cfg.binds.terminal)))
          (bind "${mod} + C" "Launcher" "Apps" "text editor" (exec cfg.binds.editor))
          (bind "${mod} + B" "Launcher" "Apps" "web browser" (exec cfg.binds.browser.normal))
          (bind "${mod} + SHIFT + B" "Launcher" "Apps" "private web browser" (exec cfg.binds.browser.private))

          # launcher menus
          (bind "${mod} + D" "Launcher" "Launcher menus" "application finder" (exec(cfg.binds.launcher.application)))
          (bind "${mod} + C" "Launcher" "Launcher menus" "calculator" (exec cfg.binds.launcher.calc))
          (bind "${mod} + E" "Launcher" "Launcher menus" "file finder" (exec cfg.binds.launcher.executable))
          (bind "${mod} + TAB" "Launcher" "Launcher menus" "window (focus) switcher" (exec cfg.binds.launcher.window))
          (bind "${mod} + slash" "Launcher" "Launcher menus" "keybindings hint menu" (exec "pkill -x rofi || hyde-shell keybinds_hint c"))
          (bind "${mod} + semicolon" "Launcher" "Launcher menus" "emoji picker menu" (exec cfg.binds.launcher.emoji))
          (bind "${mod} + SHIFT + semicolon" "Launcher" "Launcher menus" "glyph picker" (exec "pkill -x rofi || hyde-shell glyph-picker"))
          (bind "${mod} + V" "Launcher" "Launcher menus" "clipboard" (exec "pkill -x rofi || hyde-shell cliphist -c"))
          (bind "${mod} + SHIFT + V" "Launcher" "Launcher menus" "clipboard manager" (exec "pkill -x rofi || hyde-shell cliphist"))
          (bind "${mod} + SHIFT + A" "Launcher" "Launcher menus" "select rofi launcher shape" (exec "pkill -x rofi || hyde-shell rofiselect"))

          # Workspaces
        ] ++
          # navigation
          (map (i: (bind "${mod} + ${i}" "Workspaces" "Navigation" "navigate to workspace ${i}" (fcs i))) workspaces)
          ++
        [
          (bind "${mod} + mouse_down" "Workspaces" "Navigation" "scroll to next workspace" (fcs "e+1"))
          (bind "${mod} + mouse_up" "Workspaces" "Navigation" "scroll to previous workspace" (fcs "e-1"))
          # move window to workspace
        ] ++
          (map (i: (bind "${mod} + SHIFT + ${i}" "Workspaces" "Move window to workspace" "move to workspace ${i}" (wmvw i))) workspaces)
          ++
        [
          (bind "${mod} + CONTROL + SHIFT + J" "Workspaces" "Move window to workspace" "move window to next relative workspace" (wswp "next")) # no follow
          (bind "${mod} + CONTROL + SHIFT + K" "Workspaces" "Move window to workspace" "Move window to previous relative workspace" (wswp "prev")) # no follow
          # scratchpad
          (bind "${mod} + 0" "Workspaces" "Scratchpad" "toggle scratchpad" (tspl "special"))
          (bind "${mod} + SHIFT + 0" "Workspaces" "Scratchpad" "move to scratchpad" (wmvw "special:special")) # no follow

          # Hardware controls
          # audio
          (binde "XF86AudioRaiseVolume" "Hardware Controls" "Audio" "increase volume" (exec cfg.binds.audio.raise))
          (binde "XF86AudioLowerVolume" "Hardware Controls" "Audio" "decrease volume" (exec cfg.binds.audio.lower))
          (binde "XF86AudioMute" "Hardware Controls" "Audio" "toggle mute" (exec cfg.binds.audio.togglemute))
          (binde "XF86AudioMicMute" "Hardware Controls" "Audio" "toggle mic mute" (exec cfg.binds.audio.togglemicmute))

          # media
          (binde "XF86AudioPlay" "Hardware Controls" "Media" "play media" (exec cfg.binds.media.play))
          (binde "XF86AudioPause" "Hardware Controls" "Media" "pause media" (exec cfg.binds.media.pause))
          (binde "XF86AudioNext" "Hardware Controls" "Media" "next media" (exec cfg.binds.media.next))
          (binde "XF86AudioPrev" "Hardware Controls" "Media" "previous media" (exec cfg.binds.media.prev))

          # brightness
          (binde "XF86MonBrightnessUp" "Hardware Controls" "Brightness" "monitor brightness up" (exec cfg.binds.brightness.mon.up))
          (binde "XF86MonBrightnessDown" "Hardware Controls" "Brightness" "monitor brightness down" (exec cfg.binds.brightness.mon.down))
          (binde "XF86KbdBrightnessUp" "Hardware Controls" "Brightness" "keyboard brightness up" (exec cfg.binds.brightness.kbd.up))
          (binde "XF86KbdBrightnessDown" "Hardware Controls" "Brightness" "keyboard brightness down" (exec cfg.binds.brightness.kbd.down))

          # Utilities
          # screen capture
          (bind "${mod} + P" "Utilities" "Screen Capture" "screenshot select" (exec "hyde-shell screenshot s"))
          (bind "${mod} + SHIFT + P" "Utilities" "Screen Capture" "screenshot monitor" (exec "hyde-shell screenshot m"))
          (bind "${mod} + ALT + P" "Utilities" "Screen Capture" "print all monitors" (exec "hyde-shell screenshot p"))
          (bind "${mod} + SHIFT + period" "Utilities" "Screen Capture" "color picker" (exec "hyprpicker -an"))
          # login control
          (bind "${mod} + X" "Utilities" "Login control" "lock screen" (exec cfg.binds.lock))
        ] ++ (builtins.map process-extras cfg.binds.extras);
      };
      extraConfig = cfg.extra-config;
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
