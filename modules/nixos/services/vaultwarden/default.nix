{ config, lib, pkgs, ... }: let
  cfg = config.my.services.vaultwarden;
in {
  options.my.services.vaultwarden = with lib; {
    enable = mkEnableOption "vaultwarden configuration";

    port = mkOption {
      type = with types; port;
      default = 4567;
      description = "Vaultwarden port";
    };
  };

  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      config = rec {
        rocketPort = cfg.port;
        domain = "http://127.0.0.1:${toString rocketPort}";
        rocketLog = "critical";
        signupsAllowed = false;
        databaseUrl = "postgresql:///${config.users.users.vaultwarden.name}";
        logLevel = "error";
        extendedLogging = true;
      };
    };
    my.services.nginx.virtualHosts = {
      vwd = {
        inherit (cfg) port;
      };
    };
    my.services.postgresql = {
      enable = true;

      # Only allow unix socket authentication for vaultwarden database
      authentication = "local ${config.users.users.vaultwarden.name} ${config.users.users.vaultwarden.name} peer map=vaultwarden_map";

      identMap = "vaultwarden_map ${config.users.users.vaultwarden.name} ${config.users.users.vaultwarden.name}";

      ensureDatabases = [ config.users.users.vaultwarden.name ];
      ensureUsers = [
        {
          inherit (config.users.users.vaultwarden) name;
          ensureDBOwnership = true;
        }
      ];
    };
  };
}
