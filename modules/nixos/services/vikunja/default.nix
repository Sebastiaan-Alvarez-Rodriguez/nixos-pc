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
      enable = mkEnableOption "mailer configuration";

      host = mkOption {
        type = types.str;
        description = "Mail hostname";
      };

      port = mkOption {
        type = types.port;
        default = 993;
        description = "port for mailserver";
      };

      authtype = mkOption {
        type = types.str;
        default = "plain";
        description = "authentication method";
      };

      username = mkOption {
        type = types.str;
        description = "mailserver user";
      };

      password-file = mkOption {
        type = types.str;
        description = "path to password-file containing mailserver password";
      };

      from-email = mkOption {
        type = types.str;
        description = "Email address given as 'from' email header when vikunja sends email";
      };

      force-ssl = mkEnableOption "Whether to force use of SSL instead of STARTLS.";
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
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
          enableregistration = false; # Only allow registration of users through the CLI
          publicurl = "https://${subdomain}.${config.networking.domain}";
          timezone = config.time.timeZone;
          # UNIX socket for serving the API
          unixsocket = socketPath;
          unixsocketmode = "0o660";
        };

        mailer = {
          enabled = cfg.mail.enable;
          password.file = cfg.mail.password-file;
          fromemail = cfg.mail.from-email;
          forcessl = cfg.mail.force-ssl;
          inherit (cfg.mail) host port authtype username;
        };
      };
    };

    # This is a weird setup
    my.services.nginx.virtualHosts.${subdomain} = {
      socket = socketPath;
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
      enable = true;

      authentication = "local vikunja vikunja peer map=vikunja_map";
      identMap = "vikunja_map vikunja vikunja";

      ensureDatabases = [ "vikunja" ];
      ensureUsers = [
        {
          name = "vikunja";
          ensureDBOwnership = true;
        }
      ];
    };

    my.services.backup.routes = (lib.my.toAttrsUniform cfg.backup-routes { paths = [ config.services.vikunja.settings.files.basepath ]; });
  };
}
