{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.wm.hyprland;
in {
  imports = [ ./hydenix.nix ./end4.nix ];

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

    modkey = mkOption {
      type = types.str;
      default = "SUPER"; # This is the 'windows' key on most keyboards.
      description = "Modkey to use for issuing commands to hyprland";
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
      settings = {
        "$mainMod" = cfg.modkey;
        bind = let # see https://wiki.hypr.land/Configuring/Binds
          workspace-binds = builtins.concatLists (builtins.genList (i: [ "$mainMod, code:1${toString i}, workspace, ${toString (i + 1)}" "$mainMod SHIFT, code:1${toString i}, movetoworkspacesilent, ${toString (i + 1)}" ]) 9);
        in workspace-binds
          ++ [ # window focus movement
            "$mainMod, J, cyclenext, "
            "$mainMod, K, cyclenext, prev"
            "$mainMod SHIFT, J, swapnext, "
            "$mainModkey SHIFT, K, swapnext, prev"
          ] ++ [ # adjust split ratio
            "$mainMod, H, splitratio, -0.05"
            "$mainMod, L, splitratio, +0.05"
            # "$mainMod+Shift H" = "send-layout-cmd hyprlandtile main-count +1";
            # "$mainMod+Shift L" = "send-layout-cmd hyprlandtile main-count -1";
          ] ++ [ # toggle between fullscreen or not
            "$mainMod, F, fullscreen, 0 toggle" # this one makes completely full screen
            "$mainMod SHIFT, F, fullscreen, 1 toggle" # this keeps gaps and bars
          ] ++ [ # close windows
            "$mainMod, Q, closewindow, activewindow"
            "$mainMod SHIFT, Q, killactive, "
          ]
          ++ lib.optionals (config.my.home.terminal.program == "foot") [
            "$mainMod, Return, exec, ${pkgs.foot}/bin/foot"
          ]
          ++ lib.optionals config.my.home.librewolf.enable [
            "$mainMod, B, exec, ${config.programs.librewolf.package}/bin/librewolf"
            "$mainMod, P, exec, ${config.programs.librewolf.package}/bin/librewolf --private-window"
          ]
          ++ lib.optionals config.my.home.wm.apps.swaylock.enable  [
            "$mainMod, X, exec, ${config.my.home.wm.apps.swaylock.package}/bin/swaylock"
          ];
        
          # seb TODO: maybe use?
          # ++ lib.optional config.my.home.wm.apps.grim.enable [
          #   ", Print, exec, ${pkgs.writeShellScript "screenshot" ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png}"
          # ]
          # seb TODO: maybe use? (if there is no good wofi/rofi default)
          # (lib.mkIf config.my.home.wm.apps.rofi.enable {
          #   "$mainMod D" = "spawn ${config.programs.rofi.package}/bin/rofi -combi-modi drun,ssh -show combi -modi combi";
          # })
        binde = let
          pamixer = "${pkgs.pamixer}/bin/pamixer";
          playerctl = "${pkgs.playerctl}/bin/playerctl";
          brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
        in [ # flag e: will repeat command on keybind hold
          ", XF86AudioRaiseVolume, exec, ${pamixer} -i 5"
          ", XF86AudioLowerVolume, exec, ${pamixer} -d 5"
          ", XF86AudioMute, exec, ${pamixer} --toggle-mute"
          ", XF86AudioMicMute, exec, ${pamixer} --default-source --toggle-mute"

          ", XF86AudioMedia, exec, ${playerctl} play-pause"
          ", XF86AudioPlay, exec, ${playerctl} play-pause"
          ", XF86AudioPause, exec, ${playerctl} play-pause"
          ", XF86AudioPrev, exec, ${playerctl} previous"
          ", XF86AudioNext, exec, ${playerctl} next"

          ", XF86MonBrightnessUp, exec, ${brightnessctl} s 5%+"
          ", XF86MonBrightnessDown, exec, ${brightnessctl} s 5%-"
          ", XF86KbdBrightnessUp, exec, ${brightnessctl} -d asus::kbd_backlight s 5%+"
          ", XF86KbdBrightnessDown, exec, ${brightnessctl} -d asus::kbd_backlight s 5%-"
        ];
        # seb TODO: check if below binds need to come back
        # "$mainMod Space" = "toggle-float";

        # "$mainMod D" = "spawn ${pkgs.rofi-wayland}/bin/rofi -combi-modi drun,ssh -show combi -modi combi";



        # "$mainMod 0" = "set-focused-tags ${toString allTags}";
        # "$mainMod+Shift 0" = "set-view-tags ${toString allTags}";

        repeat_rate = 50; # sets x clicks per sec when in repeat-mode (i.e. button is held down)
        repeat_delay = 300; # amount of ms before repeat-mode is active (i.e. delay when button is held down)
      } // cfg.extra-config;
    };
  };
}
