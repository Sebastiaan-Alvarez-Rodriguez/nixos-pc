# Groceries and household management
# argumentation mealy vs grocy vs tandoor: https://www.reddit.com/r/selfhosted/comments/o1hc34/recipe_managementmeal_plannng_comments_on_mealie/
{ config, lib, ... }: let
  cfg = config.my.services.grocy;
  grocyPrefix = "grocy";
in {
  options.my.services.grocy = with lib; {
    enable = mkEnableOption "Grocy household ERP";

    runtime-path = mkOption {
      type = types.path;
      default = "/data/grocy/running";
    };

    backup-path = mkOption {
      type = types.path;
      default = "/data/grocy/backup";
    };
  };

  config = lib.mkIf cfg.enable {
    # systemd.tmpfiles.rules = [ # ensure directories exists
    #   "d ${cfg.runtime-path} 0700 grocy nginx -"
    # ]; # seb TODO: remove if indeed not needed (grocy seems to handle it)

    services.grocy = {
      enable = true;
      hostName = "${grocyPrefix}.${config.networking.domain}"; # The service sets up the reverse proxy automatically
      nginx.enableSSL = false; # Configure SSL by hand

      dataDir = cfg.runtime-path;
      settings = {
        currency = "EUR";
        culture = "en";
        calendar = {
          firstDayOfWeek = 1; # Start on Monday
          showWeekNumber = true;
        };
      };
    };

    my.services.backup.exclude = [ cfg.runtime-path ]; # contains a running sqlite3 database, should be backed up only after halting all potential writes (https://www.sqlite.org/howtocorrupt.html)
    my.services.backup.paths = [ cfg.backup-path ];

    my.services.sqlite-backup.items = [{
      name = "grocy";
      src = "${cfg.runtime-path}/grocy.db";
      dst = "${cfg.backup-path}";
      compression = "zstd";
      compressionLevel = 19;
      mkdirIfNeeded = true;
    }];

    # seb TODO: backup db using command like: sqlite3 grocy.db ".backup 'grocy.db_backup.sq3'"
    my.services.nginx.virtualHosts.${grocyPrefix} = {
      useACMEHost = config.networking.domain;
      root = "${config.services.grocy.package}/public";
    };
  };
}
