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

        "plugwise"
        "solaredge"
      ];
      # unknowns: 
      config = { # Found in /var/lib/hass
        default_config = {}; # https://www.home-assistant.io/integrations/default_config/
        http = {
          server_port = cfg.port;
          server_host = "127.0.0.1";
          trusted_proxies = [ "127.0.0.1" ];
          use_x_forwarded_for = true;
        };
      };

      # lovelaceConfig = { # the dashboards are created with lovelace. With this option set, we cannot edit the dashboard using the UI when this option is set.
      #   views = [
      #     {
      #       title = "Home";
      #       icon = "mdi:view-dashboard-outline";
      #       cards = [
      #         { type = "alarm-panel"; states = [ "arm_home" "arm_away" ]; entity = "alarm_control_panel.visonic_alarm_167313"; }
      #         { type = "thermostat"; entity = "climate.anna"; }

      #         { type = "entity"; entity = "sensor.smile_anna_outdoor_temperature" }
      #         { type = "entity"; entity = "sensor.solaredge_current_power" }
      #         { type = "entity"; entity = "sensor.solaredge_energy_today" }
      #       ];
      #     }
      #   ];
      # };
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
