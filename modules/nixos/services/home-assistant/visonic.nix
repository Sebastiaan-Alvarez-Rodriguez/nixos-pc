# declarative HA module for visonic, a custom integration: https://github.com/davesmeghead/visonic
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.home-assistant.custom_components.visonic;
  configpath = "/var/lib/hass";
  ccpath = "${configpath}/custom_components"; #custom-components-path

  hass-visonic = pkgs.hass.custom-component.visonic;
in {
  options.my.services.home-assistant.custom_components.visonic  = with lib; {
    enable = mkEnableOption "Visonic custom integration for home-assistant";
    ui = {
      enable = mkEnableOption "Generate lovelace UI";
      sensors = {
        motion = mkOption {
          type = with types; attrsOf str;
          default = {};
          example = {"z1" = "entryhall"; };
          description = "mapping of motion sensor zone numbers to names";
        };
        magnet = mkOption {
          type = with types; attrsOf str;
          default = {};
          example = {"z4" = "door to yard"; };
          description = "mapping of magnet zone numbers to names";
        };
        other = mkOption {
          type = with types; attrsOf str;
          default = {};
          example = {"z4" = "door to yard"; };
          description = "Other badges to show here, not necessarily from visonic. Map from device name to a 'human friendly name' to get extra device-badges shown.";
        };
      };
    };
    port = mkOption {
      type = types.port;
      default = 10000;
      description = "Internal port for home-assistant http server";
    };
  };

  config = lib.mkIf cfg.enable {
    services.home-assistant = lib.mkIf cfg.ui.enable {
      lovelaceConfig = {
        # Dashboards can be created using the edit UI, or using Lovelace. Using one disables the other way.
        # This option defines the config for lovelace.
        views = [
          {
            type = "sections";
            max_columns = 4;
            path = "visonic";
            title = "visonic";
            icon = "mdi:shield-home";
            sections = [
              {
                type = "grid";
                cards = [
                  { type = "alarm-panel"; states = [ "arm_home" "arm_away" ]; entity = "alarm_control_panel.visonic_alarm"; grid_options = { columns = "full"; }; }
                ];
                column_span = 4;
              }
            ];
            badges = let
              generateBadge = sensor: name: { type = "entity"; show_name = true; show_state = true; show_icon = true; entity = "binary_sensor.${sensor}"; inherit name; };
              prepend_visonic = name: value: lib.nameValuePair "visonic_${name}" value;
            in (lib.mapAttrsToList generateBadge (lib.mapAttrs' prepend_visonic cfg.ui.sensors.magnet)) ++ (lib.mapAttrsToList generateBadge cfg.ui.sensors.other);
          }
        ];
      };
    };
  
    systemd.services.home-assistant.preStart = ''
      cp -r ${hass-visonic}/custom_components/visonic ${ccpath}/visonic
      chmod -R u+rwX,go+rX ${ccpath}/visonic
    ''; # NOTE: must use chmod, since 'cp' also copies over the read-only file permissions from the store.
  };
}
