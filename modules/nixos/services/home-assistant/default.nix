# declarative HA
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.home-assistant;
  configpath = "/var/lib/hass";
  ccpath = "${configpath}/custom_components"; #custom-components-path

  hass-visonic = inputs.self.packages.${system}.home-assistant-visonic;
in {
  options.my.services.home-assistant = with lib; {
    enable = mkEnableOption "home-assistant service";
    port = mkOption {
      type = types.port;
      default = 9999;
      description = "Internal port for home-assistant http server";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.users.users ? hass;
        message = "'hass' user not found.";
      }
    ];

    services.home-assistant = {
      enable = true;

      package = (pkgs.home-assistant.override {
        extraPackages = py: with py; [
          psycopg2 # support for postgresql
          zlib-ng  # next-gen zlib support
        ];
      }).overrideAttrs (oldAttrs: {
        doInstallCheck = false;
      });
      config.recorder.db_url = "postgresql:///${config.users.users.hass.name}";

      extraComponents = [
        # All packaged components are here: https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
        
        # Components required to complete the onboarding
        "esphome"
        "met"
        "radio_browser"

        # my own added components
        "plugwise"
        "solaredge"
      ];
      config = { # Found in /var/lib/hass
        default_config = {}; # https://www.home-assistant.io/integrations/default_config/
        http = {
          server_port = cfg.port;
          server_host = "127.0.0.1";
          trusted_proxies = [ "127.0.0.1" ];
          use_x_forwarded_for = true;
        };
      };

      lovelaceConfig = {
        # Dashboards can be created using the edit UI, or using Lovelace. Using one disables the other way.
        # This option defines the config for lovelace.
        views = [
          {
            type = "panel";
            title = "alarm-mono";
            path = "alarm-mono";
            icon = "mdi:shield-home-outline";
            cards = [
              { type = "alarm-panel"; states = [ "arm_home" "arm_away" ]; entity = "alarm_control_panel.visonic_alarm_167313"; }
            ];
          }
          {
            type = "panel";
            path = "anna";
            title = "anna";
            icon = "mdi:thermostat";
            cards = [
              { type = "thermostat"; entity = "climate.anna"; show_current_as_primary = true; }
            ];
          }
          {
            type = "sidebar";
            path = "sun";
            title = "sun";
            icon = "mdi:sun-clock";
            cards = [
              { type = "gauge"; entity = "sensor.solaredge_energy_today"; min = 0; max = 50000; }
              { type = "gauge"; entity = "sensor.solaredge_current_power"; min = 0; max = 10000; needle = false; }
              { type = "entity"; entity = "sensor.solaredge_lifetime_energy"; }
            ];
          }
        ];
      };
    };
  
    users.groups.hass = { }; # Set-up homeassistant group

    systemd.tmpfiles.rules = [
      # custom components
      # NOTE: always restart home-assistant service after adding a component
      "C ${ccpath}/visonic - - - - ${hass-visonic}/custom_components/visonic"

      # fix directory permissions
      "Z ${ccpath} 770 hass hass - -"
    ];

    my.services.postgresql = {
      enable = true;
      # Only allow unix socket authentication for hass database
      authentication = "local ${config.users.users.hass.name} ${config.users.users.hass.name} peer map=homeassistant_map";

      identMap = ''
        homeassistant_map ${config.users.users.hass.name} ${config.users.users.hass.name}
      '';

      ensureDatabases = [ config.users.users.hass.name ];

      ensureUsers = [
        {
          inherit (config.users.users.hass) name;
          ensureDBOwnership = true;
        }
      ];
    };

    my.services.nginx.virtualHosts.ha = {
      inherit (cfg) port;
      useACMEHost = config.networking.domain;

      extraConfig = {
        # extraConfig = ''
        #   proxy_buffering off;
        # '';
        locations."/" = {
          proxyWebsockets = true;
        };
      };
    };
  };
}
