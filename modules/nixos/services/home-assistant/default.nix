# declarative HA
# Browse integrations: https://www.home-assistant.io/integrations/
# example yaml configuration layout:
# example blueprints:
#
# intel
# All forms of configuration accept jinja: https://jinja.palletsprojects.com/en/stable/templates/
#   this includes functions
# Foreach design: https://community.home-assistant.io/t/using-the-new-for-each/419829
#   contains a simpler example second, using 'expand' (is not jinja)
 
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
      default = 10000;
      description = "Internal port for home-assistant http server";
    };

    blueprints = {
      script = mkOption {
        type = with types; listOf (path);
        default = [];
        description = literalExpression "List of script blueprints to install into ${config.services.home-assistant.configDir}/blueprints/script";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [ { assertion = config.users.users ? hass; message = "'hass' user not found."; } ];

    services.home-assistant = {
      enable = true;

      package = (pkgs.home-assistant.override {
        extraPackages = py: with py; [
          getmac # because it just keeps on complaining otherwise
          ical # so adding todo-lists does not crash

          psycopg2 # support for postgresql
          pychromecast # because it just keeps on complaining otherwise
          zlib-ng  # next-gen zlib support
        ];
      }).overrideAttrs (oldAttrs: {
        doInstallCheck = false;
      });

      extraComponents = [
        # All packaged components are here: https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
        
        # Components required to complete the onboarding
        "esphome"
        "met"
        "radio_browser"

        # my own added components
        "plugwise"
        "roborock"
        "solaredge"
      ];
      config = { # Found in /var/lib/hass
        # for configuration.yaml and other config tips, see [here](https://github.com/frenck/home-assistant-config)
        default_config = {}; # https://www.home-assistant.io/integrations/default_config/
        homeassistant.time_zone = "Europe/Amsterdam";
        http = {
          server_port = cfg.port;
          server_host = "127.0.0.1";
          trusted_proxies = [ "127.0.0.1" ];
          use_x_forwarded_for = true;
        };
        recorder.db_url = "postgresql:///${config.users.users.hass.name}";

        "automation" = "!include ${configpath}/automations.yaml";
        "automation split" = "!include_dir_list ${configpath}/automations";
        "scene" = "!include ${configpath}/scenes.yaml";
        "scene split" = "!include_dir_list ${configpath}/scenes";
        "script" = "!include ${configpath}/scripts.yaml";
        "script split" = "!include_dir_named ${configpath}/scripts";
        # "template" = "!include_dir_list ./template";
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

      blueprints.script = let
        # script blueprint, syntax inspired from: [here](https://github.com/SirGoodenough/HA_Blueprints/blob/master/Scripts/play_media_file_script.yaml) (minus the on-the-fly variable switching)
        emergency-notify = pkgs.writeText "emergency-notify.yaml" ''
          blueprint:
            name: Emergency Mobile Alert
            description: Sends a critical emergency alert to a selected phone, temporarily setting ringer mode to 'normal'
            domain: script
            input:
              phone_target:
                name: Mobile App Notify Target
                description: E.g., notify.mobile_app_<PHONE-NAME-HERE>
                selector:
                  target:
                    entity:
                      domain: notify
              title:
                name: Alert Title
                default: "🚨 Emergency!"
                selector:
                  text:
              _message:
                name: Alert Message
                default: "Something bad happened"
                selector:
                  text:

          sequence:
            - service: "{{ phone_target.entity_id }}"
              data:
                message: command_ringer_mode
                data:
                  command: normal

            - delay:
              hours: 0
              minutes: 0
              seconds: 3
              milliseconds: 0

            - service: "{{ phone_target.entity_id }}"
              data:
                message: "{{ message }}"
                title: "{{ title }}"
                data:
                  importance: high
                  ttl: 0
                  priority: high
                  channel: "alarm_stream"
                  vibrationPattern: [0, 500, 1000, 500, 1000, 500]
                  persistent: true
                  sticky: true

            - delay:
              hours: 0
              minutes: 1
              seconds: 0
              milliseconds: 0

            - service: "{{ phone_target.entity_id }}"
              data:
                message: command_ringer_mode
                data:
                  command: silent
        '';
      in [ emergency-notify ] ++ cfg.blueprints.script;
    };
  
    users.groups.hass = { }; # Set-up homeassistant group

    systemd.tmpfiles.rules = [
      # create basic referenced files if they do not exist
      "f ${configpath}/automations.yaml 0770 hass hass - []"
      "f ${configpath}/scenes.yaml 0770 hass hass - []"
      "f ${configpath}/scripts.yaml 0770 hass hass - {}"
      
      # prepare custom component installation
      "R ${ccpath} - - - - -" # remove custom components dir recursively
      "D ${ccpath} 0770 hass hass - -" # create custom components dir again (now empty)

      # add custom components
      # NOTE: always restart home-assistant service after adding a component
      "C ${ccpath}/visonic - - - - ${hass-visonic}/custom_components/visonic"

      # "L+ ${ccpath}/visonic - - - - ${hass-visonic}/custom_components/visonic" # NOTE: symlinks are removed by HA for some reason. Does not work.
    ];

    my.services.postgresql = {
      enable = true;
      # Only allow unix socket authentication for hass database
      authentication = "local ${config.users.users.hass.name} ${config.users.users.hass.name} peer map=homeassistant_map";

      identMap = ''
        homeassistant_map ${config.users.users.hass.name} ${config.users.users.hass.name}
      '';

      ensureDatabases = [ config.users.users.hass.name ];

      ensureUsers = [ { inherit (config.users.users.hass) name; ensureDBOwnership = true; } ];
    };

    my.services.nginx.virtualHosts.ha = {
      inherit (cfg) port;
      useACMEHost = config.networking.domain;

      extraConfig.locations."/" = {
        proxyWebsockets = true;
      };
    };
  };
}
