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
        };
      };
    };
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
