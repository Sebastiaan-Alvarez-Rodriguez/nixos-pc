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
  };

  config = lib.mkIf cfg.enable {
   virtualisation.oci-containers.containers.joplin = {
      image = cfg.package;
      autoStart = true;
      # user = "joplin:joplin";
      # user = "64380:64381";
      ports = [
        "127.0.0.1:${builtins.toString cfg.port}:22300" # only locally expose joplin
      ];
      volumes = [
        "/run/postgresql:/run/postgresql"
        # "/etc/passwd:/etc/passwd:ro" # seb NOTE: this breaks the container... but without it, it won't access the postgres
        # "/etc/group:/etc/group:ro" # seb NOTE: probably because inside the container, it uses its own uid/gid mapping. I need joplin to have the same uid/gid as on the host.
        # seb NOTE: and I cannot mount /etc/passwd and /etc/group, because it overrides the container's passwd and group... Somehow this leads to the container erroring out with some file permission error for some /opt/whatever file.
        # seb NOTE: and I cannot set the container-internal proces to use the same uid/gid as the host, because it breaks stuff inside the container.
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

    # users.users.joplin = {
    #   description = "joplin service";
    #   group = "joplin";
    #   isSystemUser = true;
    #   uid = 64380;
    # };
    # users.groups.joplin = { gid = 64381; };

    my.services.postgresql = {
      enable = true;

      # local peer map auth type: allows a certain user access to the database, without a password.
      # authentication = "local joplin joplin peer map=joplin_map";
      # identMap = "joplin_map joplin joplin";
      authentication = "local joplin joplin trust"; # seb NOTE: this is insecure by default. Use e2ee to not have plain notes in this db.

      ensureDatabases = [ "joplin" ];
      ensureUsers = [ { name = "joplin"; ensureDBOwnership = true; } ];
    };

    my.services.nginx.virtualHosts = {
      notes = {
        inherit (cfg) port;
      };
    };
  };
}
