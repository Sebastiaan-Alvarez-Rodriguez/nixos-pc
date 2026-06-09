{ config, lib, pkgs, nixosConfig ? {}, ... }: let
  cfg = config.my.home.wm.apps.hyprlock;
in {
  options.my.home.wm.apps.hyprlock = with lib; {
    enable = mkEnableOption "Enable hyprlock";
    image = mkOption {
      type = with types; nullOr types.path;
      default = null;
      description = ''
        Wallpaper to set.
        If 'screenshot' is passed, program will use current screen as image instead.
        If stylix is used, just leave this `null`. Stylix handles the image.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.wm.hyprland.enable;
        message = "Must use hyprland to use hyprlock";
      }

      {
        assertion = nixosConfig ? security.pam.services.hyprlock;
        message = "Must set `securty.pam.services.hyprlock = {};` to use hyprlock";
      }
    ];

    programs.hyprlock = let
      playerctl-available = builtins.elem pkgs.playercontrol config.home.packages;
    in {
      enable = true;

      settings = {
        general = { };

        animations.enabled = true;

        background = lib.mkDefault [{
          monitor = "";
          path = lib.mkIf (cfg.image != null) cfg.image;
          blur_passes = 2;
        }];

        input-field = {
            monitor = "";
            size = "200, 50";
            outline_thickness = 3;
            dots_size = 0.33; # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.15; # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true;
            dots_rounding = -1; # -1 default circle, -2 follow input-field rounding
            # outer_color = $wallbash_pry4_rgba;
            # inner_color = $wallbash_pry2_rgba;
            # font_color = $wallbash_3xa9_rgba;
            fade_on_empty = true;
            fade_timeout = 1000; # Milliseconds before fade_on_empty is triggered.
            placeholder_text = "<i>Input Password...</i>"; # Text rendered in the input box when it's empty.
            hide_input = false;
            rounding = -1; # -1 means complete rounding (circle/oval);
            # check_color = $wallbash_pry4_rgba;
            # fail_color = rgba(FF0000FF) # if authentication failed, changes outer_color and fail message color;
            fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>"; # can be set to empty
            fail_transition = 300; # transition time in ms between normal outer_color and fail_color
            capslock_color = -1;
            numlock_color = -1;
            bothlock_color = -1; # when both locks are active. -1 means don't change outer color (same for above)
            invert_numlock = false; # change color if numlock is off
            swap_font_color = true; # see below;
            position = "0, 4.5%";
            halign = "center";
            valign = "bottom";
        };
        
        label = [
          { # time
            monitor = "";
            text = "$TIME";
            # color = ""$wallbash_txt1_rgba;
            font_size = 90;
            # font_family = $fontFamily;
            position = "-30, 0";
            halign = "right";
            valign = "top";
          }

          { # date
            monitor = "";
            text = ''cmd[update:43200000] date +"%A, %d %B %Y"'';
            # color = $wallbash_txt2_rgba
            font_size = 25;
            # font_family = $fontFamily
            position = "-30, -150";
            halign = "right";
            valign = "top";
          }

          { # USER Greeting
            monitor = "";
            text = "cmd[update:60000] $fn_greet"; # user command?
            # color = "$text";
            font_size = 20;
            # font_family = "$fontFamily Bold";
            position = "0, -16%";
            halign = "center";
            valign = "center";
          }

          { # Mpris and SPLASH
            monitor = "";
            text = "cmd[update:1000] $SPLASH_CMD"; # Outputs the song title when mpris is available, otherwise, it will output the splash command.
            # color = $wallbash_txt2_rgba
            font_size = 15;
            # font_family = $fontFamily
            position = "0, 0";
            halign = "center";
            valign = "bottom";
          }

          # $(playerctl -l | tail -n1)="$(playerctl -l | tail -n1)"
          { # Next button
            monitor = "";
            text = "cmd[update:1000] { playerctl status -p $(playerctl -l | tail -n1) | grep -q \"Playing\" ;} && echo \"󰒭\"";
            onclick = "playerctl -p $(playerctl -l | tail -n1) next";
            # color = $text
            font_size = 20;
            # font_family = $fontFamily Bold
            position = "2%, -13 %";
            halign = "center";
            valign = "center";
          }
          { # Prev button
            monitor = "";
            text = "cmd[update:1000] { playerctl status -p $(playerctl -l | tail -n1) | grep -q \"Playing\" ;} && echo \"󰒮\"";
            onclick = "playerctl -p $(playerctl -l | tail -n1) previous && pkill -u $USER -SIGUSR2 hyprlock"; # seb TODO: what does this do?
            # color = $text
            font_size = 20;
            # font_family = $fontFamily Bold
            position = "-2%, -13 %";
            halign = "center";
            valign = "center";
          }
          { # Play/Pause button
            monitor = "";
            text = "cmd[update:1000] player=$(playerctl -l | tail -n1); [ -z \"$player\" ] && echo \"\" || (playerctl status -p \"$player\" 2>/dev/null | grep -q '^Playing$' && echo \"⏸\" || echo \"▶\")";
            onclick = "playerctl -p $(playerctl -l | tail -n1) play-pause";
            # color = $text;
            font_size = 20;
            # font_family = $fontFamily Bold;
            position = "0, -13 %";
            halign = "center";
            valign = "center";
          }


          { # Battery Status if present
            monitor = "";
            text = "cmd[update:5000] $BATTERY_ICON";
            # color = $wallbash_4xa9_rgba
            font_size = 20;
            # font_family = JetBrainsMono Nerd Font
            position = "-1%, 1%";
            halign = "right";
            valign = "bottom";
          }

          { # Current Keyboard Layout 
            monitor = "";
            text = "$LAYOUT";
            # color = $wallbash_4xa9_rgba
            font_size = 20;
            # font_family = $fontFamily
            position = "-2%, 1%";
            halign = "right";
            valign = "bottom";
          }


          { # Added Fingerprint Prompts
            text = "$FPRINTPROMPT";
            # color = $wallbash_txt2_rgba
            font_size = 16;
            position = "0, 2%";
            halign = "center";
            valign = "bottom";
          }
          {
            text = "$FPRINTFAIL";
            # color = rgba(FF7070FF)
            font_size = 14;
            position = "0, 5%";
            halign = "center";
            valign = "bottom";
          }
        ];
      };
    };
    my.home.wm.apps.hypridle.lock-cmd = "pidof hyprlock || hyprlock"; # just for if hypridle is used, otherwise this statement does nothing.
  };
}
