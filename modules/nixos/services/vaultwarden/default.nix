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
        signupsAllowed = true;
        databaseUrl = "postgresql:///${config.users.users.vaultwarden.name}";
      };
    };
    my.services.nginx.virtualHosts = {
      vwd = {
        inherit (cfg) port;
      };
    };
    my.services.postgresql = {
      enable = true;
      # settings.port = 5432;

      # Only allow unix socket authentication for vaultwarden database
      authentication = "local ${config.users.users.vaultwarden.name} all peer map=superuser_map"; # seb: NOTE if I ever get a conflict for this attribute, change to list option type and merge in custom service.

      identMap = ''
        superuser_map root     postgres
        superuser_map postgres postgres
        superuser_map  /^(.*)$ \1
      ''; # seb: NOTE if I ever get a conflict for this attribute, change to list option type and merge in custom service.

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
