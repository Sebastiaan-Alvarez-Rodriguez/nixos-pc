{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.waybar;
in {
  options.my.home.wm.apps.waybar = with lib; {
    systemdTarget = mkOption {
      type = with types; str;
      default = "graphical-session.target";
      description = "The systemd target that will automatically start the swaybg service.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.wayland.enable;
        message = "Waybar module requires wayland graphics manager (set my.home.gm.wayland.enable = true)";
      }
    ];
    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        target = cfg.systemdTarget;
      };
      settings = {
        main = {
          layer = "bottom";
          position = "top";
          height = 25;
 
          modules-left = [] ++ lib.optionals config.my.home.wm.river.enable [ "river/tags" ];
          modules-center = [ "clock" ];
          modules-right = [ "backlight/slider" "tray" "network" "battery" "cpu" "memory" "pulseaudio" "custom/exit" ];

          network = {
            format-wifi = "{essid} ({signalStrength}%) ";
            format-ethernet = "{ifname}: {ipaddr}/{cidr} ";
            format-linked = "{ifname} (No IP) ";
            format-disconnected = "Disconnected ⚠";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
          };
          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% ";
            format-plugged = "{capacity}% ";
            format-alt = "{time} {icon}";
            format-icons = ["" "" "" "" ""];
          };
          cpu = {
            format = "{}% ";
          };
          memory = {
            format = "{}% ";
          };
          tray = {
            spacing = 10;
          };
          clock = {
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            format-alt = "{:%Y-%m-%d}";
          };
          pulseaudio = {
            format = "{volume}% {icon} {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = "{volume}% ";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = ["" "" ""];
            };
            on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
          };
          "custom/exit" = lib.mkIf config.my.home.wm.apps.wlogout.enable {
            "format" = "";
            "on-click" = "${config.my.home.wm.apps.wlogout.package}/bin/wlogout";
            "tooltip-format" = "Power Menu";
          };
        };
      };
      style = ./waybar-style.css;
    };
  };
}
