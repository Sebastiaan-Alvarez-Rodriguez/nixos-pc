# Contact Management

# link: https://www.monicahq.com/features


{ config, lib, ... }: let
  cfg = config.my.services.monica;
  subdomain = "contacts";
in {
  options.my.services.monica = with lib; {
    enable = mkEnableOption "Monica contact webapp";
    hostname = mkOption {
      type = types.str;
      default = if config.networking.domain != null then config.networking.fqdn else config.networking.hostName; # TODO: check if correct
      description = "The hostname to serve monica on.";
    };

    dataDir = mkOption {
      description = "monica data directory";
      default = "/data/monica";
      type = types.path;
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
    };

    root-url = mkOption {
      description = "Root URL";
      example = "https://example.com";
      type = types.str;
    };

    poolConfig = mkOption {
      type = with types; attrsOf (oneOf [ str int bool ]);
      default = {
        "pm" = "dynamic";
        "pm.max_children" = 16;
        "pm.start_servers" = 1;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 2;
        "pm.max_requests" = 100;
      };
      description = "Options for the monica PHP pool.";
    };

    appKeyFile = mkOption {
      description = "A file containing the Laravel APP_KEY. Can be generated with: <code>head -c 32 /dev/urandom | base64</code>";
      type = types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    services.monica = {
      inherit (cfg) enable hostname dataDir poolConfig appKeyFile;
      inherit (cfg.mail) host user passwordFile port from encryption;
      inherit (cfg.database) host port user passwordFile name;
      appURL = cfg.root-url;
     };
    # my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.dataDir ]; }; # TODO: is this the path to backup? Or also the database?
  };
}
