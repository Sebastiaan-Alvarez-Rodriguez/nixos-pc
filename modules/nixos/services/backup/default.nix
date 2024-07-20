# Backups using restic. NOTE: use 'backup-server' service to setup a repository.
{ config, pkgs, lib, ... }: let
  cfg = config.my.services.backup;
  excludeArg = with builtins; with pkgs; "--exclude-file=" + (writeText "excludes.txt" (concatStringsSep "\n" cfg.exclude));
in {
  options.my.services.backup = with lib; {
    enable = mkEnableOption "Enable backups for this host";

    repository = mkOption {
      type = types.str;
      example = [ "/mnt/backup-hdd" "rest:http://USER:PASSWORD@IP:PORT"];
      description = ''Backup location as provided by restic. See: https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html'';
    };

    passwordFile = mkOption {
      type = types.str;
      example = "/var/lib/restic/password.txt";
      description = ''
        Read the plaintext repository's password from this path.
        NOTE: Ensure to chown & chmod this file to make it hard to read as an attacker.
        NOTE: Ensure to push to append-only repos: If an attacker gets this password, they only can append to the backup repo.
      '';
    };

    paths = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "/var/lib" "/home" ];
      description = "Paths to backup";
    };

    exclude = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "/var/lib/very-large-path" "**/target-temporary build artefact" ];
      description = "Paths to exclude from backup";
    };

    pruneOpts = mkOption {
      type = with types; listOf str;
      default = [
        "--keep-last 10"
        "--keep-hourly 24"
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
        "--keep-yearly 100"
      ];
      example = [ "--keep-last 5" "--keep-weekly 2" ];
      description = "List of options to give to the `forget` subcommand after a backup.";
    };

    timerConfig = mkOption {
      type = types.nullOr (types.attrsOf unitOption);
      default = {
        OnCalendar = "daily";
        Persistent = true;
      };
      description = ''Config setting backup frequency.'';
    };
  };

  config = lib.mkIf cfg.enable {
    my.services.backup.paths = lib.flatten [ # Essential files which should always be backed up
      "/etc/machine-id" # Should be unique to a given host, used by some software (e.g: ZFS)
      "/var/lib/nixos" # Contains the UID/GID map, and other useful state
      (builtins.map (key: [ key.path "${key.path}.pub" ]) config.services.openssh.hostKeys) # SSH host keys (and public keys for convenience)
    ];

    services.restic.backups."basic" = {
      extraBackupArgs = [ "--verbose=2" ] ++ lib.optional (builtins.length cfg.exclude != 0) excludeArg; # Take care of included and excluded files
      initialize = true; # initializes the repo as well
      # environmentFile = cfg.credentialsFile; # give B2 API key securely

      inherit (cfg) paths passwordFile pruneOpts timerConfig repository;
    };
  };
}
