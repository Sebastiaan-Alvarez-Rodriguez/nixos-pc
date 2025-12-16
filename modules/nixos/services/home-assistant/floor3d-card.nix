# declarative HA module for floor3d-card, a custom renderer of 3d maps for buildings.
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.home-assistant.custom_components.floor3d-card;
  cfg_visonic = config.my.services.home-assistant.custom_components.visonic;
  configpath = "/var/lib/hass";
  ccpath = "${configpath}/custom_components"; #custom-components-path

  floor3d = pkgs.hass.custom-lovelace.floor3d;
in {
  options.my.services.home-assistant.custom_components.floor3d-card = with lib; {
    enable = mkEnableOption "Floor3d custom integration for home-assistant";
    model = mkOption {
      type = types.path;
      description = "Model of house to render, of type 'glb'. Note that model instance ids match with my.services.home-asstiant.visonic.sensor names (if used) to correlate these devices";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.ui.enable && lib.hasSuffix "glb" cfg.ui.model; message = "Model does not end with 'glb': ${cfg.ui.model}"; }
    ];
    services.home-assistant = {
      customLovelaceModules = [ floor3d ];
      lovelaceConfig = {
        # Dashboards can be created using the edit UI, or using Lovelace. Using one disables the other way.
        # This option defines the config for lovelace.
        views = [
          {
            type = "panel";
            title = "floor3d";
            path = "floor3d";
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
                    object_id = "${zone}_box_1"; # front-facing plane of box in model. Check house-model package to learn how to set/get the IDs.
                    entity = "binary_sensor.visonic_${zone}"; # object entity id to relate to this object id (even when uncommenting all 'light' suboptions below)
                    # seb TODO: find out why below error occurs when linking  entities correctly, and why only with librewolf/firefox likes:
                    # THREE.WebGLProgram: shader error:  1282 35715 false gl.getProgramInfoLog Statically used varyings do not fit within packing limits. (see GLSL ES Specification 1.0.17, p111) <empty string> <empty string>
                    type3d = "light";
                    # action = "more-info"; # seb TODO: or use "overlay"
                    light = {
                      lumens = 1500;
                      color = "red";
                      distance = 1000; # cm distance radius
                      shadow = true; # consider walls etc to block light
                      decay = 1.5;
                      vertical_alignment = "middle"; # options: "top/middle/bottom"
                    };
                  };
                in (builtins.map mkEntity (builtins.attrNames cfg_visonic.ui.sensors.magnet)) ++ (builtins.map mkEntity (builtins.attrNames cfg_visonic.ui.sensors.motion));
              }
            ];
          }
        ];
      };
    };
  };
}
