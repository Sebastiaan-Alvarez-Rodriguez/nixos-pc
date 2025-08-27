# declarative HA module for visonic, a custom integration: https://github.com/davesmeghead/visonic
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.home-assistant.custom_components.visonic;
  configpath = "/var/lib/hass";
  ccpath = "${configpath}/custom_components"; #custom-components-path

  hass-visonic = pkgs.hass.custom-component.visonic;
  floor3d = pkgs.hass.custom-lovelace.floor3d;
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
          description = "mapping of motion sensor zone numbers to names, e.g";
        };
        magnet = mkOption {
          type = with types; attrsOf str;
          default = {};
          example = {"z4" = "door to yard"; };
          description = "mapping of magnet zone numbers to names, e.g";
        };
      };
      model = mkOption {
        type = types.path;
        description = "Model of house to render, of type 'glb'. Note that model instance ids match with sensor names to get them correlated";
      };
    };
    port = mkOption {
      type = types.port;
      default = 10000;
      description = "Internal port for home-assistant http server";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.ui.enable && lib.hasSuffix "glb" cfg.ui.model; message = "Model does not end with 'glb': ${cfg.ui.model}"; }
    ];
    services.home-assistant = lib.mkIf cfg.ui.enable {
      customLovelaceModules = [ floor3d ];
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
              generateBadge = sensor: name: { type = "entity"; show_name = true; show_state = true; show_icon = true; entity = "binary_sensor.visonic_${sensor}"; inherit name; };
            in lib.mapAttrsToList generateBadge cfg.ui.sensors.magnet;
          }
          {
            type = "panel";
            title = "testing";
            path = "testing";
            icon = "mdi:shield-home-outline";
            cards = [
              {
                # NOTE: Configuration options here: https://github.com/adizanni/floor3d-card
                # NOTE: Learn more here: https://github.com/adizanni/floor3d-card/wiki
                type = "custom:floor3d-card";
                name = "testing";
                path = "/local";
                objfile = builtins.baseNameOf cfg.ui.model;

                backgroundColor = "white";
                globalLightPower = "0.5";
                sky = "yes";
                shadow = "yes";
                north = { x = -1; z = 0; };
                entities = let
                  mkEntity = zone: {
                    # NOTE: users cannot change the object IDs from the UI. They have to zip open the sh3d file and edit the IDs found in 'Home.xml'
                    # Also note: users report that the id's of objects may randomly change between saves, so must check model object ids after each save.
                    object_id = "${zone}_box_1"; # front-facing plane of box in model.
                    # entity = "binary_sensor.visonic_${zone}"; # object entity id to relate to this object id (even when uncommenting all 'light' suboptions below)
                    # seb TODO: find out why below error occurs when linking  entities correctly:
                    # THREE.WebGLProgram: shader error:  1282 35715 false gl.getProgramInfoLog Statically used varyings do not fit within packing limits. (see GLSL ES Specification 1.0.17, p111) <empty string> <empty string>
                    type3d = "light";
                    action = "more-info"; # seb TODO: or use "overlay"
                    light = {
                      # lumens = 2000;
                      # color = "red";
                      # distance = 1500; # cm distance radius
                      # shadow = true; # consider walls etc to block light
                      # decay = 1;
                      # vertical_alignment = "middle"; # options: "top/middle/bottom"
                    };
                  };
                in (builtins.map mkEntity (builtins.attrNames cfg.ui.sensors.motion)) ++ (builtins.map mkEntity (builtins.attrNames cfg.ui.sensors.magnet));
              }
            ];
          }
        ];
      };
    };
  
    systemd.services.home-assistant.preStart = ''
      cp ${cfg.ui.model} ${configpath}/www/
      cp -r ${hass-visonic}/custom_components/visonic ${ccpath}/visonic
      chmod -R u+rwX,go+rX ${ccpath}/visonic
    ''; # NOTE: must use chmod, since 'cp' also copies over the read-only file permissions from the store.
  };
}
