{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.waybar;
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.manager == "wayland";
        message = "Waybar module requires wayland graphics manager (set my.home.gm.manager = \"wayland\")";
      }
    ];
    programs.waybar = {
      enable = true;
      systemd = lib.mkIf (config.my.home.wm.manager == "river") { # seb: NOTE if we do not use river... Then what?
        enable = true;
        target = "river-session.target";
      };
      settings = {
        main = {
          layer = "bottom";
          position = "top";
          height = 25;

          modules-left = [] ++ lib.optionals (config.my.home.wm.manager == "river") [ "river/tags" ];
          modules-right = [ "tray" "network" "battery" "cpu" "memory" "pulseaudio" "clock" ];

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
        };
      };
      style = ./waybar-style.css;
    };
  };
}
