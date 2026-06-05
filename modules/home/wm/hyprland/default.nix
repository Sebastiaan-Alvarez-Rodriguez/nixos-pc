{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.wm.hyprland;
in {
  imports = [ ./hydenix.nix ./end4.nix ./wayle.nix ];

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

    binds = {
      modkey = mkOption {
        type = types.str;
        default = "SUPER"; # This is the 'windows' key on most keyboards.
        description = "Modkey to use for issuing commands to hyprland.hydenix";
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

      browser.normal = lib.mkOption {
        type = lib.types.str;
        default = config.my.home.browser.program;
        description = "Default browser (regular window)";
      };
      browser.private = lib.mkOption {
        type = lib.types.str;
        default = "${config.my.home.browser.program} --private-window";
        description = "Default browser (private window)";
      };

      editor = lib.mkOption {
        type = lib.types.str;
        default = lib.getExe (pkgs.${config.my.home.editor.program});
        description = "Default text editor";
      };

      terminal = lib.mkOption {
        type = lib.types.str;
        default = config.my.home.terminal.program;
        description = "Default terminal";
      };

      brightness = {
        kbd = {
          up = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Keyboard brightness up command";
          };
          down = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Keyboard brightness down command";
          };
        };
        mon = {
          up = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Monitor brightness up command";
          };
          down = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Monitor brightness down command";
          };
        };
      };

      media = {
        play = lib.mkOption {
          type = lib.types.str;
          default = "playerctl play-pause"; # assumes pkgs.playerctl is used
          description = "Play media command";
        };
        pause = lib.mkOption {
          type = lib.types.str;
          default = "playerctl play-pause";
          description = "Pause media command";
        };
        next = lib.mkOption {
          type = lib.types.str;
          default = "playerctl next";
          description = "Next media command";
        };
        prev = lib.mkOption {
          type = lib.types.str;
          default = "playerctl previous";
          description = "Prev media command";
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
      type = types.attrs;
      default = {};
      description = "Extra lines to append to config of hyprland";
    };
  };

  config = lib.mkIf config.my.home.wm.hyprland.enable {
    assertions = [ { assertion = config.my.home.gm.wayland.enable; message = "hyprland module requires wayland graphics manager (set my.home.gm.wayland.enable = true)"; } ];

    wayland.windowManager.hyprland = lib.mkIf (!cfg.hydenix.enable) {
      enable = true;
      package = cfg.package;
      portalPackage = cfg.portal-package;
      settings = let
          mk-section-name = section-names: "[${builtins.concatStringsSep "|" section-names}]";
          mk-leaf-list = name: lst: builtins.map (s: lib.replaceString "$d" name s) lst; # in a list-leaf, replaces all "$d" with the full section name
          mk-leaf = path: lst: { "${lib.last path}" = mk-leaf-list (mk-section-name (lib.init path)) lst; }; # returns a dict like { bindd = <list-leaf> };
          mk-section-list = d: lib.mapAttrsToListRecursive (path: value: mk-leaf path value) d; # makes a list like [ { bindd = <list-leaf>; } { bindd = <other-leaf>; }]
          mk-keybinds = ds: lib.zipAttrsWith (name: values: lib.flatten values) (builtins.concatMap mk-section-list ds); # takes a list of keybind settings, translates to one long list of dicts and merges everything to one dict.
          # see https://wiki.hypr.land/Configuring/Binds
      in {
        input = {
          repeat_rate = "${builtins.toString cfg.binds.repeat-rate}";
          repeat_delay = "${builtins.toString cfg.binds.repeat-delay}";
        };

        dwindle = {
          preserve_split = true;
        }; # required for `togglesplit`

        "$mainMod" = cfg.binds.modkey;
        "$lockcmd" = "hyde-shell lock-session";
        "$TERMINAL" = cfg.binds.terminal;
        "$EXPLORER" = "";
        "$EDITOR" = cfg.binds.editor;
        "$BROWSER" = cfg.binds.browser.normal;
        "$BROWSERPRIVATE" = cfg.binds.browser.private;
        "$TIWIKIWI" = "kiwijo";
      } // mk-keybinds [ { 
        "Window Management" = {
          "Main".bindd = [ # toggle between fullscreen or not
            "$mainMod, F, $d toggle fullscreen, fullscreen, 0 toggle" # this one makes completely full screen
            "$mainMod SHIFT, F, $d toggle fullscreen (keeping gaps), fullscreen, 1 toggle" # this keeps gaps and bars
          ] ++ [ # close windows
            "$mainMod, Q, $d close window, closewindow, activewindow"
            "$mainMod SHIFT, Q, $d force (kill) window, killactive, "
          ] ++ [ # lock or logout
            "$mainMod, X, $d lock screen, exec, $lockcmd"
          ] ++ [
            "$mainMod, W, $d Toggle floating, togglefloating"                  
            "$mainMod, G, $d toggle group, togglegroup"
            "$mainMod Shift, F, $d toggle pin on focused window, exec, hyde-shell windowpin"
          ];
          "Group Navigation".bindd = [
            "$mainMod SHIFT, H, $d change active group backwards   , changegroupactive, b"
            "$mainMod SHIFT, L, $d change active group forwards  , changegroupactive, f"
          ];
          "Change focus".bindd = [
            "$mainMod, J, $d cycle to next window, cyclenext, "
            "$mainMod, K, $d cycle to previous window, cyclenext, prev"
          ];
          "Move window across workspace" = {
            bindd = [
              # seb NOTE: hyde does this with more difficulty. Does it provide any gains?
              "$mainMod SHIFT, J, $d swap active window with next window, swapnext, "
              "$mainModkey SHIFT, K, $d swap active window with previous window, swapnext, prev"
            ];
            binddm = [
              "$mainMod, mouse:272, $d hold to move window, movewindow"
              "$mainMod, mouse:273, $d hold to resize window, resizewindow"
            ];
          };
          "Splits".bindd = [ # adjust split ratio
            "$mainMod, H, $d splitratio decrease, layoutmsg, splitratio -0.05"
            "$mainMod, L, $d splitratio increase, layoutmsg, splitratio 0.05"
            # "$mainMod+Shift H" = "send-layout-cmd hyprlandtile main-count +1";
            # "$mainMod+Shift L" = "send-layout-cmd hyprlandtile main-count -1";
            "$mainMod, S, $d toggle split horizontal/vertical, layoutmsg, togglesplit"
          ];
        };
        "Launcher" = {
          "Apps".bindd = [
            "$mainMod, Return, $d terminal emulator, exec, $TERMINAL"
            "$mainMod, E, $d file explorer, exec, $EXPLORER"
            "$mainMod, C, $d text editor, exec, $EDITOR"
            "$mainMod, B, $d web browser, exec, $BROWSER"
            "$mainMod SHIFT, B, $d private web browser, exec, $BROWSERPRIVATE"
            "Control SHIFT, Escape, $d system monitor, exec, hyde-shell sysmonlaunch" # note: uses "system.monitor" in upstream config
          ];
          "Launcher menus".bindd = [
            "$mainMod, A, $d application finder , exec, pkill -x rofi || hyde-shell rofilaunch d"
            "$mainMod, TAB, $d window (focus) switcher , exec, pkill -x rofi || hyde-shell rofilaunch w"
            "$mainMod SHIFT, E, $d file finder , exec, pkill -x rofi || hyde-shell rofilaunch f"
            "$mainMod, slash, $d keybindings hint menu, exec, pkill -x rofi || hyde-shell keybinds_hint c"
            "$mainMod, semicolon, $d emoji picker menu, exec, pkill -x rofi || hyde-shell emoji-picker"
            "$mainMod SHIFT, semicolon, $d glyph picker , exec, pkill -x rofi || hyde-shell glyph-picker"
            "$mainMod, V, $d clipboard, exec, pkill -x rofi || hyde-shell cliphist -c"
            "$mainMod SHIFT, V, $d clipboard manager , exec, pkill -x rofi || hyde-shell cliphist"
            "$mainMod SHIFT, A, $d select rofi launcher shape, exec, pkill -x rofi || hyde-shell rofiselect"
          ];
        };
        "Workspaces" = {
          "Navigation".bindd = let workspace-binds = builtins.concatLists (builtins.genList (i: [ "$mainMod, ${toString (i+1)}, $d navigate to workspace ${toString (i+1)}, workspace, ${toString (i + 1)}" ]) 9); in workspace-binds ++ [
            "$mainMod, mouse_down, $d scroll to next workspace, workspace, e+1"
            "$mainMod, mouse_up, $d scroll to previous workspace, workspace, e-1"
          ];
          "Move window to workspace".bindd = let workspace-move-binds = builtins.concatLists (builtins.genList (i: [ "$mainMod SHIFT, ${toString (i+1)}, $d move to workspace ${toString (i+1)}, movetoworkspacesilent, ${toString (i + 1)}" ]) 9); in workspace-move-binds ++ [
            "$mainMod Control+SHIFT, J, $d move window to next relative workspace , movetoworkspace, r+1"
            "$mainMod Control+SHIFT, K, $d move window to previous relative workspace , movetoworkspace, r-1"
          ];
          "Scratchpad".bindd = [
            "$mainMod, 0, $d toggle scratchpad, togglespecialworkspace"
            "$mainMod SHIFT, 0, $d move to scratchpad, movetoworkspacesilent, special"
          ];
        };
        "Hardware Controls" = {
          "Audio" = {
            bindde = [
              ", XF86AudioRaiseVolume, $d increase volume, exec, hyde-shell volumecontrol -o i"
              ", XF86AudioLowerVolume, $d decrease volume, exec, hyde-shell volumecontrol -o d"
            ];
            bindd = [
              ", XF86AudioMute, $d toggle mute, exec, hyde-shell volumecontrol -o m"
              ", XF86AudioMicMute, $d toggle microphone mute, exec, hyde-shell volumecontrol -i m"
            ];
          };
          "Media".bindd = [
            ", XF86AudioPlay, $d play media, exec, ${cfg.binds.media.play}"
            ", XF86AudioPause, $d pause media, exec, ${cfg.binds.media.pause}"
            ", XF86AudioNext, $d next media, exec, ${cfg.binds.media.next}"
            ", XF86AudioPrev, $d previous media, exec, ${cfg.binds.media.prev}"
          ];
          "Brightness".bindde = [
            ", XF86MonBrightnessUp, $d increase monitor brightness , exec, ${cfg.binds.brightness.mon.up}"
            ", XF86MonBrightnessDown, $d decrease monitor brightness , exec, ${cfg.binds.brightness.mon.down}"
            ", XF86KbdBrightnessUp, $d increase keyboard brightness , exec, ${cfg.binds.brightness.kbd.up}"
            ", XF86KbdBrightnessDown, $d decrease keyboard brightness , exec, ${cfg.binds.brightness.kbd.down}"
          ];
        };
        "Utilities" = {
          "Screen Capture".bindd = [
            "$mainMod, P, $d screenshot select, exec, hyde-shell screenshot s"
            "$mainMod SHIFT, P, $d screenshot monitor, exec, hyde-shell screenshot m"
            "$mainMod Alt, P, $d print all monitors, exec, hyde-shell screenshot p"
            "$mainMod SHIFT, period, $d color picker, exec, hyprpicker -an"
          ];
        };
        "Theming and Wallpaper" = {
          "Main".bindd = [
            "$mainMod Control, A, $d select global wallpaper , exec, hyde-shell wallpaper -SG"
            # "$mainMod Control, S, $d next global wallpaper , exec, hyde-shell wallpaper -Gn"
            # "$mainMod Control SHIFT, S, $d previous global wallpaper , exec, hyde-shell wallpaper -Gp"
            # "$mainMod Control, S, $d next waybar layout, exec, hyde-shell wbarconfgen n"
            # "$mainMod Control SHIFT, S, $d previous waybar layout, exec, hyde-shell wbarconfgen p"
            # "$mainMod Control, D, $d wallbash mode selector , exec, pkill -x rofi || hyde-shell wallbashtoggle -m"
            # "$mainMod Control, F, $d select a theme, exec, pkill -x rofi || hyde-shell themeselect"
            # "$mainMod Control, G, $d select animations, exec, pkill -x rofi || hyde-shell animations --select"
            # "$mainMod Control, X, $d select hyprlock layout, exec, pkill -x rofi || hyde-shell hyprlock --select"
          ];
        };
      } cfg.binds.extra-binds ];
    };
  };
}
