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

      package = (pkgs.home-assistant.override { # support for postgresql
        extraPackages = py: with py; [ psycopg2 ];
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

        "solaredge"
      ];
      # unknowns: 
      config = { # Includes dependencies for a basic setup
        default_config = {}; # https://www.home-assistant.io/integrations/default_config/
        http = {
          server_port = cfg.port;
          server_host = "127.0.0.1";
          trusted_proxies = [ "127.0.0.1" ];
          use_x_forwarded_for = true;
        };
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
      authentication = "local ${config.users.users.hass.name} all peer map=homeassistant_map";

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
