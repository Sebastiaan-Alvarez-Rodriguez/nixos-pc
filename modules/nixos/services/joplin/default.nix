{ config, lib, pkgs, ... }: let
  cfg = config.my.services.joplin;
in {
  options.my.services.joplin = with lib; {
    enable = mkEnableOption "Joplin Server";

    package = mkOption {
      type = types.str;
      default = "docker.io/joplin/server:3.5.2";
      description = "OCI image for Joplin Server. Please do not use 'latest'.";
    };

    port = mkOption {
      type = types.port;
      default = 22300;
      description = "External port for Joplin Server.";
    };

    # data-dir = mkOption {
    #   type = types.path;
    #   default = "/var/lib/joplin";
    #   description = "Persistent data directory mounted into the container.";
    # };
  };

  config = lib.mkIf cfg.enable {
   virtualisation.oci-containers.containers.joplin = {
      image = cfg.package;
      autoStart = true;
      user = "joplin:joplin";
      ports = [
        "127.0.0.1:${builtins.toString cfg.port}:22300" # only locally expose joplin
      ];
      volumes = [
        "/run/postgresql:/run/postgresql"
        "/etc/passwd:/etc/passwd:ro" # seb NOTE: this breaks the container... but without it, it won't access the postgres
        "/etc/group:/etc/group:ro" # seb NOTE:
      ];
      environment = {
        APP_PORT = "22300";
        APP_BASE_URL = "https://notes.${config.networking.domain}";

        DB_CLIENT = "pg";
        POSTGRES_HOST = "/run/postgresql";
        POSTGRES_DATABASE = "joplin";
        POSTGRES_USER = "joplin";
      };
    };

    # systemd.tmpfiles.rules = [
    #   "d ${cfg.data-dir} 0750 root root -"
    # ];

    users.users.joplin = {
      description = "joplin service";
      group = "joplin";
      isSystemUser = true;

    };
    users.groups.joplin = { };

    # seb TODO: connection to local postgres if possible
    my.services.postgresql = {
      enable = true;
      ensureDatabases = [ "joplin" ];
      ensureUsers = [ { name = "joplin"; ensureDBOwnership = true; } ];
    };

    my.services.nginx.virtualHosts = {
      notes = {
        inherit (cfg) port;
      };
    };
    # What is this anyway?
    # systemd.services."docker-joplin" = {
    #   after = optional cfg.database.enableLocalPostgres "postgresql.service";
    #   wants = optional cfg.database.enableLocalPostgres "postgresql.service";
    # };
  };
}
