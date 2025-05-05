# Torrent and usenet meta-indexer
{ config, lib, ... }: let
  cfg = config.my.services.jackett;
in {
  options.my.services.jackett = with lib; {
    enable = mkEnableOption "Jackett torrent meta-indexer";
    port = mkOption {
      type = types.port;
      default = 9117;
      description = "Internal port for webui";
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
    };
    backup-path = mkOption {
      type = with types; nullOr path;
      default = "/var/lib/private/prowlarr/Backups";
    };
  };

  config = lib.mkIf cfg.enable {
    services.jackett.enable = true;

    # Jackett wants to eat *all* RAM if left to its own devices
    systemd.services.jackett = {
      serviceConfig = {
        MemoryHigh = "15%";
        MemoryMax = "25%";
      };
    };

    my.services.nginx.virtualHosts.jackett = {
      inherit (cfg) port;
    };
    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.backup-path ]; };
  };
}
