# connects zigbee antennas to mqtt brokers for messaging
{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.services.zigbee2mqtt;
  prefix = "z2m";
in {
  options.my.services.zigbee2mqtt= with lib; {
    enable = lib.mkEnableOption "zigbee2mqtt service";

    port = mkOption {
      type = types.port;
      default = 10345;
      description = "Internal port for web-ui";
    };

    data-dir = mkOption {
      type = types.path;
      description = "Path for zigbee2mqtt data";
    };

    settings = lib.mkOption {
      type = (pkgs.formats.yaml {}).type;
      default = { };
      example = {
        homeassistant.enabled = config.services.home-assistant.enable;
        permit_join = true;
        serial.port = "/dev/ttyACM1";
        mqtt.server = "mqtt://127.0.0.1:11000";
      };
      description = "Configuration yaml for zigbee2mqtt. For possible options, see: https://www.zigbee2mqtt.io/information/configuration.html";
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
    };

    tuya-zigbee = {
      # a module that installs custom firmware on devices, so that they support direct binding.
      enable = mkEnableOption "tuya-zigbee extension, more info at https://github.com/romasku/tuya-zigbee-switch/";
      z2m-url = mkOption {
        type = types.str;
        default = "https://github.com/romasku/tuya-zigbee-switch/blob/15967f3b2a90381c5f7518bea07e50e6c3f18c29/zigbee2mqtt";
        description = "url for tuya-zigbee's z2m implementation";
      };
      converter.switch_custom  = mkOption {
        type = types.str;
        default = tuya-zigbee.z2m-url + "/converters/switch_custom.js";
        description = "location of 'switch_custom.js' (use only if you want to use another version of this converter software)";
      };
      converter.tuya_with_ota = mkOption {
        type = types.str;
        default = tuya-zigbee.z2m-url + "/converters/tuya_with_ota.js";
        description = "location of 'tuya_with_ota.js' (use only if you want to use another version of this converter software)";
      };
      ota-index = mkOption {
        type = types.enum [ "end_device" "end_device-FORCE" "router" "router-FORCE" ];
        default = "router";
        description = "The ota index to use. For more information, see https://github.com/romasku/tuya-zigbee-switch/blob/main/docs/updating.md#choosing-an-index";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.zigbee2mqtt = {
      enable = true;
      dataDir = cfg.data-dir;
      settings = cfg.settings // {
        frontend = {
          enabled = true;
          port = cfg.port;
          host = "127.0.0.1";
          url = "https://${prefix}.${config.networking.domain}";
        } // lib.optionalAttrs cfg.tuya-zigbee.enable {
          ota.zigbee_ota_override_index_location = "${cfg.tuya-zigbee.z2m-url}/ota/index_${cfg.tuya-zigbee.ota-index}.json";
        };
      };
    };

    systemd.tmpfiles.rules = [ "d ${cfg.data-dir}/external_converters 0700 zigbee2mqtt zigbee2mqtt -" ] ++ lib.optionals cfg.tuya-zigbee.enable [
      "L+ ${cfg.data-dir}/external_converters/switch_custom.js - - - - ${builtins.fetchurl cfg.tuya-zigbee.converter.switch_custom}"
      "L+ ${cfg.data-dir}/external_converters/tuya_with_ota.js - - - - ${builtins.fetchurl cfg.tuya-zigbee.converter.tuya_with_ota}"
    ];
    
    # below is needed to fix zigbee2mqtt immediately starting up after network.target, and discovering that the antenna is still not reachable, and then instantly failing.
    systemd.services.zigbee2mqtt.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
    systemd.services.zigbee2mqtt.serviceConfig.RestartSec = 5;
    systemd.services.zigbee2mqtt.serviceConfig.StartLimitBurst = 5;
    systemd.services.zigbee2mqtt.serviceConfig.StartLimitIntervalSec = 35;

    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.data-dir ]; };

    my.services.nginx.virtualHosts = {
      ${prefix} = {
        inherit (cfg) port;
        local-only = true;

        extraConfig = {
          locations."/".proxyWebsockets = true;
        };
      };
    };
  };
}
