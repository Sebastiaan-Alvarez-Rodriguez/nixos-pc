{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.wm.river;
in {
  imports = [ ./river-session.nix ];

  options.my.home.wm.river = with lib; {
    modkey = mkOption {
      type = with types; str;
      default = "Mod4"; # This is the 'windows' key on most keyboards.
      description = "Modkey to use for issuing commands to river";
    };
    extra-config = mkOption {
      type = with types; lines;
      default = "";
      description = "Extra lines to append to config of river";
    };
  };

  config = lib.mkIf config.my.home.wm.river.enable {
    assertions = [
      {
        assertion = config.my.home.gm.wayland.enable;
        message = "River module requires wayland graphics manager (set my.home.gm.wayland.enable = true)";
      }
    ];

    home.packages = with pkgs; [ river ];

    programs.river = let
      riverctl = "${pkgs.river}/bin/riverctl";
      rivertile = "${pkgs.river}/bin/rivertile";
      pamixer = "${pkgs.pamixer}/bin/pamixer";
      playerctl = "${pkgs.playerctl}/bin/playerctl";
      brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
    in {
      enable = true;
      systemdIntegration = true;

      layoutGenerator = {
        command = "${rivertile} -view-padding 2 -outer-padding 2 -main-ratio 0.5";
      };

      bindings = let
        mod = cfg.modkey;
        allTags = (lib.my.power 2 32) - 1;
        tagBinds = lib.mkMerge (map  (i: let tags = lib.my.power 2 (i - 1); in {
          "${mod} ${toString i}" = "set-focused-tags ${toString tags}";
          "${mod}+Shift ${toString i}" = "set-view-tags ${toString tags}";
          "${mod}+Control ${toString i}" = "toggle-focused-tags ${toString tags}";
          "${mod}+Shift+Control ${toString i}" = "toggle-view-tags ${toString tags}";
        }) (lib.range 1 9));
      in {
        normal = (lib.mkMerge [
          {
            # NOTE: must not use absolute '${rivertile}' here and in commands below.
            "${mod} Q" = "close";
            "${mod} J" = "focus-view next";
            "${mod} K" = "focus-view previous";
            "${mod}+Shift J" = "swap next";
            "${mod}+Shift K" = "swap previous";

            "${mod}+Shift Return" = "zoom";

            "${mod} Z" = "focus-output next";
            "${mod}+Shift Z" = "send-to-output next";

            "${mod} Space" = "toggle-float";

            "${mod} F" = "toggle-fullscreen";
            "${mod} D" = "spawn '${pkgs.rofi-wayland}/bin/rofi -combi-modi drun,ssh -show combi -modi combi'";

            "${mod} H" = "send-layout-cmd rivertile 'main-ratio -0.05'";
            "${mod} L" = "send-layout-cmd rivertile 'main-ratio +0.05'";

            "${mod}+Shift H" = "send-layout-cmd rivertile 'main-count +1'";
            "${mod}+Shift L" = "send-layout-cmd rivertile 'main-count -1'";

            "None XF86Eject" = "spawn 'eject -T'";

            "None XF86AudioRaiseVolume" = "spawn '${pamixer} -i 5'";
            "None XF86AudioLowerVolume" = "spawn '${pamixer} -d 5'";
            "None XF86AudioMute" = "spawn '${pamixer} --toggle-mute'";
            "None XF86AudioMicMute" = "spawn '${pamixer} --default-source --toggle-mute'";

            "None XF86AudioMedia" = "spawn '${playerctl} play-pause'";
            "None XF86AudioPlay" = "spawn '${playerctl} play-pause'";
            "None XF86AudioPause" = "spawn '${playerctl} play-pause'";
            "None XF86AudioPrev" = "spawn '${playerctl} previous'";
            "None XF86AudioNext" = "spawn '${playerctl} next'";

            "None XF86MonBrightnessUp" = "spawn '${brightnessctl} s 5%+'";
            "None XF86MonBrightnessDown" = "spawn '${brightnessctl} s 5%-'";
            "None XF86KbdBrightnessUp" = "spawn '${brightnessctl} -d asus::kbd_backlight s 5%+'";
            "None XF86KbdBrightnessDown" = "spawn '${brightnessctl} -d asus::kbd_backlight s 5%-'";

            "${mod} 0" = "set-focused-tags ${toString allTags}";
            "${mod}+Shift 0" = "set-view-tags ${toString allTags}";

            "${mod} F11" = "enter-mode passthrough";
          }

          tagBinds

          (lib.mkIf config.my.home.librewolf.enable {
            "${mod} B" = "spawn '${config.programs.librewolf.package}/bin/librewolf'";
            "${mod} P" = "spawn '${pkgs.programs.librewolf.package}/bin/librewolf --private-window'";
          })

          (lib.mkIf (config.my.home.terminal.program == "foot") {
            "${mod} Return" = "spawn '${pkgs.foot}/bin/foot'";
          })

          (lib.mkIf config.my.home.wm.apps.grim.enable {
            "None Print" = let
              screenshot = pkgs.writeShellScript "screenshot" ''
                ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png
              ''; # lets user take screenshot, copies result to clipboard (pastable in e.g. tdesktop)
            in
              "spawn '${screenshot}'";
          })

          (lib.mkIf config.my.home.wm.apps.rofi.enable {
            "${mod} D" = "spawn '${config.programs.rofi.package}/bin/rofi -combi-modi drun,ssh -show combi -modi combi'";
          })

          (lib.mkIf config.my.home.wm.apps.swaylock.enable {
            "${mod} X" = "spawn '${config.my.home.wm.apps.swaylock.package}/bin/swaylock'";
          })

          (lib.mkIf config.my.home.wm.apps.wlogout.enable {
            "${mod} C" = "spawn '${config.programs.wlogout.package}/bin/wlogout'";
          })
        ]);
        pointer = {
          "${mod} BTN_LEFT" = "move-view";
          "${mod} BTN_RIGHT" = "resize-view";
        };
        passthrough = {
          "${mod} F11" = "enter-mode normal";
        };
      };

      config = {
        attachMode = "bottom";
        border = {
          color = {
            focused = "0xff0908";
            unfocused = "0x484848";
          };
          width = 1;
        };
        cursor = {
          followFocus = "normal";
          hide = 5000;
        };
        repeat = {
          rate = 50;
          delay = 300;
        };
      };

      extraConfig = ''
        ${riverctl} float-filter-add app-id 'float'
        ${riverctl} float-filter-add app-id 'popup'
        ${cfg.extra-config}
      '';
    };
  };
}
