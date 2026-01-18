{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.wm.hyprland.hydenix;
in {
  imports = [ inputs.hydenix.homeModules.default ];
  options.my.home.wm.hyprland.hydenix = with lib; {
    enable = mkEnableOption "Use hydenix theme for hyprland";

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
        default = config.my.home.editor.program;
        description = "Default text editor";
      };

      terminal = lib.mkOption {
        type = lib.types.str;
        default = config.my.home.terminal.program;
        description = "Default terminal";
      };
    };

    extra-config = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra lines to append to config of hydenix";
    };
  };

  config = lib.mkIf config.my.home.wm.hyprland.hydenix.enable {
    # home-manager/local hydenix configuration
    # for more options, see https://github.com/richen604/hydenix/blob/main/template/docs/options.md
    # and here: https://github.com/richen604/hydenix/tree/main/hydenix/modules/hm
    hydenix.hm = {
      enable = true;

      # integrated program options
      comma.enable = false;
      editors = {
        enable = true;
        vscode.enable = (builtins.baseNameOf cfg.binds.editor) == "code";
        neovim = (builtins.baseNameOf cfg.binds.editor) == "nvim";
        vim = (builtins.baseNameOf cfg.binds.editor) == "vim";
        default = cfg.binds.editor;
      };
      fastfetch.enable = true;
      firefox.enable = false;
      git.enable = false;
      gtk.enable = true; # seb NOTE: I have some config in radon for this disabled... Let this do it? Or disable here, merge from profile / separate home module?
      hyde.enable = true;
      lockscreen = {
        enable = true;
        hyprlock = true; # other option: swaylock
      };
      notifications.enable = true;
      qt.enable = true; # only adds styling
      rofi.enable = true;
      screenshots.enable = true;
      shell = {
        enable = true;
        zsh.enable = false;
        starship.enable = false;
        bash.enable = false;
        fish.enable = true;
        fastfetch.enable = true;
      };
      social.enable = false;
      spotify.enable = true;
      swww.enable = true; # wallpapers
      terminals = {
        enable = true;
        kitty.enable = (cfg.binds.terminal == "kitty");
      };
      theme = { # find themes here: https://github.com/HyDE-Project/hyde-gallery
        enable = true;
        active = "Catppuccin Mocha"; # the default
        themes = [ # all available themes on this host for this user
          "Catppuccin Mocha"
          "Catppuccin Latte"
        ];
      };
      uwsm.enable = true;
      waybar.enable = true;
      wlogout.enable = true;
      xdg.enable = true;

      # hyprland configuration options
      hyprland = { # see specifically here for options: https://github.com/richen604/hydenix/blob/main/hydenix/modules/hm/hyprland/options.nix
        enable = true; # use this flake's own hyprland
        animations = {
          enable = true;
          preset = "standard"; # "fast" or "minimal-1" or "minimal-2" also sound nice
        };
        workflows = {
          enable = true;
          active = "default"; # could also be "editing", "gaming", "powersaver", or "snappy"
        };
        hypridle.enable = false; # No idle lock-out, thanks
        # extra config appended to user-prefs.conf
        extraConfig = ''
          input {
            repeat_rate = ${builtins.toString cfg.binds.repeat-rate}
            repeat_delay = ${builtins.toString cfg.binds.repeat-delay}
          }
        '';

        suppressWarnings = true; # yes I override the keybinds with my own preferences, stop warning during build.
        keybindings = {
          enable = true;
          overrideConfig = let
            bind-section-prefix = section-names: "$d=[${builtins.concatStringsSep "|" section-names}]";
            process-bind = prefix: l: builtins.map (i: prefix + " = " + i) l; # process a single bind[d/e] block of statements
            process-binds = d: builtins.concatLists (lib.attrValues (builtins.mapAttrs process-bind d)); # processes all bind[d/e] statements and converts to a list. Assumes all pairs are bind[d/e] blocks. Returns a single list.
            process-bind-section = d: section-names: (bind-section-prefix section-names) + "\n" + (lib.concatLines (process-binds d)); # processes all kv-pairs of d, and handles section tags. Returns a string.

            has-any-bind = l: builtins.any (elem: lib.hasPrefix "bind" elem) l;
            gen-keybind-config-inner = d: section-names: if (has-any-bind (builtins.attrNames d)) then
              process-bind-section d section-names
            else if builtins.length (lib.attrNames d) > 0 then
              lib.concatLines (lib.attrValues (builtins.mapAttrs (k: v: gen-keybind-config-inner v (section-names ++ [k])) d))
            else "";

            prefix = ''
              ## █▄▀ █▀▀ █▄█ █▄▄ █ █▄░█ █▀▄ █ █▄░█ █▀▀ █▀
              ## █░█ ██▄ ░█░ █▄█ █ █░▀█ █▄▀ █ █░▀█ █▄█ ▄█

              # see https://wiki.hyprland.org/configuring/keywords/ for more
              # example binds, see https://wiki.hyprland.org/configuring/binds/ for more

              #? ------- KEYBINDS_HYPRLAND_V_0_53 COMPATIBLE ----------------
              #   This Config is compatible with keybinding changes in Hyprland v0.53+
              #   To ensure your system is working we will not disable this block
              #   User template files will be provided in $XDG_DATA_HOME/hyde/templates/hypr/keybindings.conf for manual update.

              #? ------- Grouping of binds for easier management ----------------
              #  $d=[Group Name|Subgroup Name1|Subgroup Name2|...]
              # '$d' is a variable that is used to group binds together (or use another variable)
              # This is only for organization purposes and is not a defined hyprland variable
              # What we did here is to modify the Description of the binds to include the group name
              # The $d will be parsed as a separate key to be use for a GUI or something pretty
              # [Main|Subgroup1|Subgroup2|...]
              # Main - The main groupname
              # Subgroup1.. - The subgroup names can be use to avoid repeating the same description

              #? ------- Variables ----------------
            '';
            postfix = ''
              $d=#! unset the group name
            '';
            gen-variables = d: lib.concatLines (lib.attrValues (builtins.mapAttrs (k: v: "\$${k} = ${v}") (lib.filterAttrs (k: v: v != null && v != "") d)));
            gen-keybind-config = d: prefix + (gen-variables d.variables) + "\n" + (gen-keybind-config-inner d.sections []) + "\n" + postfix;
          in (gen-keybind-config { # see https://wiki.hypr.land/Configuring/Binds
            variables = {
              mainMod = cfg.binds.modkey;
              lockcmd = "hyde-shell lock-session";
              TERMINAL = cfg.binds.terminal;
              EXPLORER = "";
              EDITOR = cfg.binds.editor;
              BROWSER = cfg.binds.browser.normal;
              BROWSERPRIVATE = cfg.binds.browser.private;
            };
            sections = {
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
                  "$mainMod, H, $d splitratio decrease, splitratio, -0.05"
                  "$mainMod, L, $d splitratio increase, splitratio, +0.05"
                  # "$mainMod+Shift H" = "send-layout-cmd hyprlandtile main-count +1";
                  # "$mainMod+Shift L" = "send-layout-cmd hyprlandtile main-count -1";
                  "$mainMod, S, $d toggle split horizontal/vertical, togglesplit"
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
                "Rofi menus".bindd = [
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
                  ", XF86AudioPlay, $d play media, exec, playerctl play-pause"
                  ", XF86AudioPause, $d pause media, exec, playerctl play-pause"
                  ", XF86AudioNext, $d next media, exec, playerctl next"
                  ", XF86AudioPrev, $d previous media, exec, playerctl previous"
                ];
                "Brightness".bindde = [
                  ", XF86MonBrightnessUp, $d increase monitor brightness , exec, hyde-shell brightnesscontrol i"
                  ", XF86MonBrightnessDown, $d decrease monitor brightness , exec, hyde-shell brightnesscontrol d"
                  ", XF86KbdBrightnessUp, $d increase keyboard brightness , exec, ${pkgs.brightnessctl} -d asus::kbd_backlight s 5%+"
                  ", XF86KbdBrightnessDown, $d decrease keyboard brightness , exec, ${pkgs.brightnessctl} -d asus::kbd_backlight s 5%-"
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
                  "$mainMod Control, S, $d next waybar layout, exec, hyde-shell wbarconfgen n"
                  "$mainMod Control SHIFT, S, $d previous waybar layout, exec, hyde-shell wbarconfgen p"
                  "$mainMod Control, D, $d wallbash mode selector , exec, pkill -x rofi || hyde-shell wallbashtoggle -m"
                  "$mainMod Control, F, $d select a theme, exec, pkill -x rofi || hyde-shell themeselect"
                  "$mainMod Control, G, $d select animations, exec, pkill -x rofi || hyde-shell animations --select"
                  "$mainMod Control, X, $d select hyprlock layout, exec, pkill -x rofi || hyde-shell hyprlock --select"
                ];
              };
            };
          });
        };
        windowrules.enable = true; # applies rules to specific known programs, so they behave well
        nvidia.enable = false;
        pyprland.enable = true; # provides scratchpad
        monitors.enable = true;
      };
    } // cfg.extra-config;
  };
}
