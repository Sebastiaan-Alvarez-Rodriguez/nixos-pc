# Backups using restic. NOTE: use 'backup-server' service to setup a repository.
{ config, pkgs, lib, utils, ... }: let
  cfg = config.my.services.backup;
  excludeArg = with builtins; with pkgs; "--exclude-file=" + (writeText "excludes.txt" (concatStringsSep "\n" cfg.exclude));

  inherit (utils.systemdUtils.unitOptions) unitOption;
in {
  options.my.services.backup = with lib; {
    enable = mkEnableOption "Enable backups for this host";

    repository = mkOption {
      type = types.str;
      example = [ "/mnt/backup-hdd" "rest:http://USER:PASSWORD@IP:PORT"];
      description = ''Backup location as provided by restic. See: https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html'';
    };

    environment-file = mkOption {
      type = types.str;
      example = "/var/lib/restic/env.txt";
      description = ''
        Provide:
         1. "RESTIC_REST_USERNAME" --> server access user.
         2. "RESTIC_REST_PASSWORD" --> server access password.
        NOTE: With 1+2, an attacker may access the remote server and create new repositories.
              They cannot access existing repositories, because those also have a password.
        NOTE: To ensure attackers with 1+2 cannot create new repositories, use `private-repo` server setting.
      '';
    };

    exclude = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "/var/lib/very-large-path" "**/target-temporary builddir *.objectfile" ];
      description = "Paths to exclude from backup";
    };

    password-file = mkOption {
      type = types.str;
      example = "/path/to/plaintext-pass.txt";
      description = ''
        Plaintext password for the repository.
        NOTE: With this, an attacker may access the repository (but only if they also have 1+2 from `environment-file` setting).
              Depending on repository settings, attacker may update/delete backed up repositories.
              This is mitigated by using append-only repositories, allowing attackers only to create new snapshots in the repo.
              Their malicious work can be undone by picking a snapshot prior to the attack.
      '';
    };

    paths = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "/var/lib" "/home" ];
      description = "Paths to backup";
    };

    prune-opts = mkOption {
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

    timer-config = mkOption {
      type = with types; nullOr (attrsOf unitOption);
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
      environmentFile = cfg.environment-file; # pass credentials
      passwordFile = cfg.password-file;
      pruneOpts = cfg.prune-opts;
      timerConfig = cfg.timer-config;

      inherit (cfg) paths repository;
    };
  };
}
