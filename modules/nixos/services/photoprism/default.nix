# A picture/video management webserver
# found using: https://www.reddit.com/r/selfhosted/comments/nrzum3/piwigo_lychee_photoprism_librephotos_your_final/
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.photoprism;
  domain-prefix = "img";
  domain = config.networking.domain;

  env = {
        PHOTOPRISM_ORIGINALS_PATH = cfg.originals-path;
        PHOTOPRISM_STORAGE_PATH = cfg.storage-path;
        PHOTOPRISM_IMPORT_PATH = cfg.import-path;
        PHOTOPRISM_BACKUP_PATH = cfg.backup-path;
        PHOTOPRISM_BACKUP_SCHEDULE = "daily";
        PHOTOPRISM_BACKUP_RETAIN = "1"; # we use restic daily, so no point in keeping multiple.
        PHOTOPRISM_BACKUP_DATABASE = "true"; # yes, backup the db.
        PHOTOPRISM_BACKUP_ALBUMS = "true"; # yes, backup the album metadata.
        PHOTOPRISM_HTTP_HOST = "localhost";
        PHOTOPRISM_HTTP_PORT = toString cfg.port;
        PHOTOPRISM_ADMIN_PASSWORD = "insecure";
        PHOTOPRISM_SITE_URL = cfg.public-address;
        PHOTOPRISM_SITE_CAPTION = "AI-powered, lightning-fast";
        PHOTOPRISM_SITE_AUTHOR = "rdn, mrs";
      };
  photoprism-manage = pkgs.writeShellScript "photoprism-manage" ''
    set -o allexport # Export the following env vars
    ${lib.toShellVars env}
    eval "$(${config.systemd.package}/bin/systemctl show -pUID,MainPID photoprism.service | ${pkgs.gnused}/bin/sed "s/UID/ServiceUID/")"
    exec ${cfg.package}/bin/photoprism "$@"
  '';
in {
  options.my.services.photoprism = with lib; {
    enable = mkEnableOption "photoprism media server";

    package = mkOption {
      type = types.package;
      default = pkgs.photoprism;
      description = "Package to use";
    };

    port = mkOption {
      type = types.port;
      default = 9056;
      description = "Internal port for webui";
    };

    public-address = mkOption {
      type = types.str;
      default = "https://${domain-prefix}.${config.networking.domain}";
      description = "Public address to be used for e.g. generating share links";
    };

    originals-path = mkOption {
      type = types.path;
      default = "/data/storage/shared/pictures";
      description = "storage PATH of your original media files (photos and videos).";
    };

    storage-path = mkOption {
      type = types.path;
      default = "/data/photoprism/storage";
      description = "Location for the database, cache-files and 'sidecar'. Must be restored entirely when switching hosts.";
    };

    import-path = mkOption {
      type = types.path;
      default = "/data/photoprism/import";
      description = "Mounts an import folder from which files can be transferred to the originals folder in a structured way that avoids duplicates. NOTE: never pick a path inside of 'originals-path' as it creates a loop.";
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
    };

    backup-path = mkOption {
      type = types.path;
      default = "/data/photoprism/backups";
      description = "Backups database and metadata.";
    };
  };

  config = lib.mkIf cfg.enable {
    # seb NOTE:
    # from the docs - Should you later want to move your instance to another host,
    # the easiest and most time-saving way is to copy the entire `storage` folder along with your `originals` and database.
    # Note that it is not needed per-se to backup the storage-folder, as long as we have:
    # - originals folder (obviously, here are the images  / videos)
    # - index database (found in `<backup-path`/sqlite`)
    # src: https://docs.photoprism.app/user-guide/backups/restore/

    # services.photoprism = {
    #   enable = true;
    #   address = "localhost";

    #   originalsPath = cfg.originals-path;
    #   storagePath = cfg.storage-path;
    #   importPath = cfg.import-path;

    #   settings = {
    #     PHOTOPRISM_ORIGINALS_PATH = cfg.originals-path;
    #     PHOTOPRISM_STORAGE_PATH = cfg.storage-path;
    #     PHOTOPRISM_IMPORT_PATH = cfg.import-path;
    #     PHOTOPRISM_BACKUP_PATH = cfg.backup-path;
    #     PHOTOPRISM_BACKUP_SCHEDULE = "daily";
    #     PHOTOPRISM_BACKUP_RETAIN = "1"; # we use restic daily, so no point in keeping multiple.
    #     PHOTOPRISM_BACKUP_DATABASE = "true"; # yes, backup the db.
    #     PHOTOPRISM_BACKUP_ALBUMS = "true"; # yes, backup the album metadata.
    #     PHOTOPRISM_ADMIN_PASSWORD = "insecure";
    #   };
    #   inherit (cfg) port;
    #   # package = inputs.nixpkgs-unstable.legacyPackages.${system}.photoprism;
    # };

    # systemd.services.photoprism.serviceConfig.DynamicUser = lib.mkForce false;


    systemd.services.photoprism = lib.mkForce {
      wantedBy = [ "multi-user.target" ];

      environment = env;
      preStart = ''
        exec ${photoprism-manage} migrations run -f
      '';
      path = with pkgs; [ sqlite ];

      unitConfig.Description = "Photoprism server";
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} start";
        DynamicUser = lib.mkForce false;
        User = "photoprism";
        Group = "photoprism";
        Restart = "on-failure";
      };
    };

    # Set-up directories
    systemd.tmpfiles.rules = [
      # originals-path should exist
      "d ${cfg.import-path} 0777 photoprism photoprism -"
      "d ${cfg.storage-path} 0700 photoprism photoprism -"
      "d ${cfg.backup-path} 0700 photoprism photoprism -"
    ];
    users.users.photoprism = {
      description = "photoprism Service";
      group = "photoprism";
      isSystemUser = true;
    };
    users.groups.photoprism = {};


    # seb TODO: it seems the index db is not generated by photoprism, so not backed up...
    # When executing: /nix/store/5yv0z6rk11crhi7pja2fwf0z9xwyvaby-photoprism-manage backup -i -f
    # output: empty .sql file, 0B, with error: ERRO[2025-06-04T00:33:39+02:00] failed to create database backup: exec: no command 
    # 
    my.services.backup.global-excludes = [ cfg.storage-path ]; # not needed.
    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.backup-path cfg.originals-path ]; };

    my.services.nginx.virtualHosts.${domain-prefix} = {
      inherit (cfg) port;
      extraConfig = {
        locations."/" = {
          extraConfig = ''
            proxy_buffering off;
          '';
          proxyPass = "http://127.0.0.1:${toString cfg.port}/";
          proxyWebsockets = true;
        };
      };
    };
  };
}
