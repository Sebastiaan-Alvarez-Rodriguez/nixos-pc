# declarative HA
{ config, lib, pkgs, ... }: let
  cfg = config.my.services.home-assistant;
in {
  options.my.services.home-assistant = with lib; {
    enable = mkEnableOption "home-assistant service";
    port = mkOption {
      type = types.port;
      default = 9999;
      description = "Port for home-assistant http server";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.users.users ? hass;
        message = "'hass' user not found.";
      }
    ];

    # networking.firewall.allowedTCPPorts = [ cfg.port ]; # seb: TODO remove me after test

    services.home-assistant = {
      enable = true;

      package = (pkgs.home-assistant.override { # support for postgresql
        extraPackages = py: with py; [ psycopg2 ]; # seb: NOTE: was psycopg2 originally
      }).overrideAttrs (oldAttrs: {
        doInstallCheck = false;
      });
      config.recorder.db_url = "postgresql:///${config.users.users.hass.name}";

      extraComponents = [
        # All packaged components are here: https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
        # The quoted names are the ones available.
        
        # Components required to complete the onboarding
        "esphome"
        "met"
        "radio_browser"

        "solaredge"
      ];
      # unknowns: 
      config = { # Includes dependencies for a basic setup
        default_config = {}; # https://www.home-assistant.io/integrations/default_config/
        http.server_port = cfg.port;
      };
    };
  
    users.groups.hass = { }; # Set-up homeassistant group

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
  };
}
