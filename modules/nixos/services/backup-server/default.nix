# Backup server using restic's rest server. NOTE: Backup data from clients using 'backup' service.
{ config, pkgs, lib, ... }: let
  cfg = config.my.services.backup-server;
  excludeArg = with builtins; with pkgs; "--exclude-file=" + (writeText "excludes.txt" (concatStringsSep "\n" cfg.exclude));
in {
  options.my.services.backup-server = with lib; {
    enable = mkEnableOption "Enable backups for this host";

    append-only = mkEnableOption {
      description = "Enable append only mode. This mode allows creation of new backups but prevents deletion and modification of existing backups.";
      default = true;
    };

    credentials-file = mkOption {
      type = types.path;
      description = ''
        Path to allowed user credentials to access the server.
        Each line looks like `<user>:<hash>`.
        Lines can be generated using `htpasswd -nB <user>`.
      '';
    };

    data-dir = mkOption {
      type = types.str;
      description = "data storage location (NOTE: data is encrypted at client-side, no chance to read it here)";
    };

    port = mkOption {
      type = types:port;
      default = 1001;
      description = "Internal port for backup server";
    };

    private-repos = mkEnableOption {
      description = "Enable private repos. Grants access only to a repo (i.e. a subdirectory) with the same name as the specified username.";
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [
      {
        warning = !cfg.append-only;
        message = "Append-only server should be enabled to prevent attackers with server + repo credentials to delete / change backup snapshots prior to attack!";
      }
      {
        warning = !cfg.private-repos;
        message = "Private repos should be enabled to prevent attackers with server credentials to create backup snapshots!";
      }
    ];

    services.restic.server = {
      enable = true;
      listenAddress = "127.0.0.1:${cfg.port}";
      dataDir = cfg.data-dir;
      appendOnly = cfg.append-only;
      extraFlags = [ "--htpasswd-file" builtins.toString cfg.credentials-file ];
    };

    my.services.nginx.virtualHosts = {
      restic = {
        inherit (cfg) port;

        extraConfig = {
          # Allow bulk upload of backup data
          locations."/".extraConfig = ''
            client_max_body_size 0;
          '';
        };
      };
    };
  };
}
