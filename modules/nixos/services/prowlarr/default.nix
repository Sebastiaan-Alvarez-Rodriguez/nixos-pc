# Torrent and usenet meta-indexer
{ config, lib, ... }: let
  cfg = config.my.services.prowlarr;
in {
  options.my.services.prowlarr = with lib; {
    enable = mkEnableOption "Prowlarr torrent & usenet meta-indexer";

    port = mkOption {
      type = types.port;
      default = 9696;
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
    services.prowlarr.enable = true;

    my.services.nginx.virtualHosts.prowlarr = {
      inherit (cfg) port;
    };

    services.fail2ban.jails = {
      prowlarr = ''
        enabled = true
        filter = prowlarr
        action = iptables-allports
      '';
    };

    environment.etc = {
      "fail2ban/filter.d/prowlarr.conf".text = ''
        [Definition]
        failregex = ^.*\|Warn\|Auth\|Auth-Failure ip <HOST> username .*$
        journalmatch = _SYSTEMD_UNIT=prowlarr.service
      '';
    };

    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.backup-path ]; };
  };
}
