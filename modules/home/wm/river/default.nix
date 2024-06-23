{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.wm.river;
  isEnabled = config.my.home.wm.manager == "river";
in {
  imports = [ ./river-session.nix ];

  # seb: TODO may need old module as in original repo,  ../modules/home-manager/river.nix
  config = lib.mkIf isEnabled {
    assertions = [
      {
        assertion = config.my.home.gm.manager == "wayland";
        message = "River module requires wayland graphics manager (set my.home.gm.manager = \"wayland\")";
      }
    ];

    programs.river = let
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
        mod = "Mod4"; # Windows key
        # TODO: Move to central lib
        pwr = base: exp: lib.foldl (x: _: x * base) 1 (lib.range 1 exp);
        allTags = (pwr 2 32) - 1;
        # TODO: Move to central lib
        concatAttrs = attrList: lib.fold (x: y: x // y) {} attrList;
        tagBinds = lib.mkMerge (map  (i: let tags = pwr 2 (i - 1); in {
          "${mod} ${toString i}" = "set-focused-tags ${toString tags}";
          "${mod}+Shift ${toString i}" = "set-view-tags ${toString tags}";
          "${mod}+Control ${toString i}" = "toggle-focused-tags ${toString tags}";
          "${mod}+Shift+Control ${toString i}" = "toggle-view-tags ${toString tags}";
        }) (lib.range 1 9));
        screenshot = pkgs.writeShellScript "screenshot" ''
          ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png
        '';
      in {
        normal = (lib.mkMerge [
          {
            "${mod} Return" = "spawn '${pkgs.foot}/bin/foot'"; # TODO: Find out why footclient prints a bunch of random stuff...
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

            "${mod} H" = "send-layout-cmd ${rivertile} 'main-ratio -0.05'";
            "${mod} L" = "send-layout-cmd ${rivertile} 'main-ratio +0.05'";

            "${mod}+Shift H" = "send-layout-cmd ${rivertile} 'main-count +1'";
            "${mod}+Shift L" = "send-layout-cmd ${rivertile} 'main-count -1'";

            "None Print" = "spawn '${screenshot}'";

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

          (lib.mkIf config.my.home.wm.rofi.enable {
            "${mod} D" = "spawn '${config.programs.rofi.package}/bin/rofi -combi-modi drun,ssh -show combi -modi combi'";
          })

          (lib.mkIf config.my.home.firefox.enable {
            "${mod} B" = "spawn '${pkgs.firefox}/bin/firefox'";
            "${mod} P" = "spawn '${pkgs.firefox}/bin/firefox --private-window'";
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
        riverctl float-filter-add app-id 'float'
        riverctl float-filter-add app-id 'popup'
      '';
    };
  };
}
