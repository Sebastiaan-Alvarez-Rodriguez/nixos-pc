# Todo and kanban app
{ config, lib, ... }: let
  cfg = config.my.services.vikunja;
  subdomain = "todo";
  vikunjaDomain = "${subdomain}.${config.networking.domain}";
  socketPath = "/run/vikunja/vikunja.socket";
in {
  options.my.services.vikunja = with lib; {
    enable = mkEnableOption "Vikunja todo app";

    mail = {
      enable = mkEnableOption {
        description = "mailer configuration";
      };

      configFile = mkOption {
        type = types.str;
        example = "/run/secrets/vikunja-mail-config.env";
        description = "Configuration for the mailer connection, using environment variables.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.vikunja = {
      enable = true;

      frontendScheme = "https";
      frontendHostname = vikunjaDomain;

      database = {
        type = "postgres";
        user = "vikunja";
        database = "vikunja";
        host = "/run/postgresql";
      };

      settings = {
        service = {
          # Only allow registration of users through the CLI
          enableregistration = false;
          # Ues the host's timezone
          timezone = config.time.timeZone;
          # Use UNIX socket for serving the API
          unixsocket = socketPath;
          unixsocketmode = "0o660";
        };

        mailer = {
          enabled = cfg.mail.enable;
        };
      };

      environmentFiles = lib.optional cfg.mail.enable cfg.mail.configFile;
    };

    # This is a weird setup
    my.services.nginx.virtualHosts = {
      ${subdomain} = {
        socket = socketPath;
      };
    };

    systemd.services.vikunja = {
      serviceConfig = {
        DynamicUser = lib.mkForce false; # Use a system user to simplify using the CLI
        User = "vikunja"; # Set the user for postgres authentication
        RuntimeDirectory = "vikunja"; # Create /run/vikunja/ to serve the UNIX socket
      };
    };

    users.users.vikunja = {
      description = "Vikunja Service";
      group = "vikunja";
      isSystemUser = true;
    };
    users.groups.vikunja = { };

    users.users.nginx.extraGroups = [ "vikunja" ]; # Allow nginx to access the UNIX socket

    my.services.postgresql = {
      ensureDatabases = [ "vikunja" ];
      ensureUsers = [
        {
          name = "vikunja";
          ensureDBOwnership = true;
        }
      ];
    };

    my.services.backup = {
      paths = [
        config.services.vikunja.settings.files.basepath
      ];
    };
  };
}
