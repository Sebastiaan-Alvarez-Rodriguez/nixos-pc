{ config, lib, ... }: let
  cfg = config.my.services.postgresql-backup;
in {
  # NOTE: to restore a backup, use `pg_restore`. See e.g. https://stackoverflow.com/a/18546265
  options.my.services.postgresql-backup = with lib; {
    enable = mkEnableOption "Backup SQL databases";
    backupAll = mkEnableOption "postgres backupAll option";
    compression = mkOption {
      type = with types; enum ["none" "gzip" "zstd"];
      default = "zstd";
      description = "Compression to use for backups";
    };
    compressionLevel = mkOption {
      type = types.int;
      default = 6;
      description = "If compression is given, sets the compression level for the algorithm (gzip between 1-6, zstd between 1-19).";
    };
    location = mkOption {
      type = types.str;
      description = "Path to store backup to. This value is automatically added to the backup service. Directory is automatically created with postgres-only rwx access.";
    };
    startAt = mkOption {
      type = types.str;
      default = "*-*-* 01:15:00"; # every day at 01:15
      description = "When to run the backup service, as a cronstring";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresqlBackup = {
      enable = true;
      inherit (cfg) backupAll compression compressionLevel location startAt;
    };

    my.services.backup = {
      paths = [ config.services.postgresqlBackup.location ];
      # No need to store previous backups thanks to `restic`
      exclude = [ (config.services.postgresqlBackup.location + "/*.prev.sql.gz") ];
    };
  };
}
