# Torrent and usenet meta-indexer
{ config, lib, ... }: let
  cfg = config.my.services.nzbhydra;
in {
  options.my.services.nzbhydra = with lib; {
    enable = mkEnableOption "NZBhydra torrent & usenet meta-indexer";

    port = mkOption {
      type = types.port;
      default = 5076;
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
    services.nzbhydra2.enable = true;

    my.services.nginx.virtualHosts.nzbhydra = {
      inherit (cfg) port;
    };

    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.backup-path ]; };
  };
}


