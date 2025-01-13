# Backups using restic. NOTE: use 'backup-server' service to setup a repository.
{ config, pkgs, lib, utils, ... }: let
  cfg = config.my.services.backup;
  inherit (utils.systemdUtils.unitOptions) unitOption;

  routeOption = with lib; types.submodule({ name, ...}: {
    options = {
      repository = mkOption {
        type = types.str;
        example = [ "/mnt/backup-hdd" "rest:http://USER:PASSWORD@IP:PORT"];
        description = "Backup location as provided by restic. See: https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html";
      };

      environment-file = mkOption {
        type = types.str;
        example = "/var/lib/restic/env.txt";
        description = ''
          Provide:
           1. "RESTIC_REST_USERNAME" --> server access user.
           2. "RESTIC_REST_PASSWORD" --> server access password (plaintext).
          NOTE: This environment file is passed to systemd and thus uses systemd security to not leak the variables.
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
        default = [];
        example = [
          "--keep-last 10"
          "--keep-hourly 24"
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
          "--keep-yearly 100"
        ];
        description = ''
          List of options to give to the `forget` subcommand after a backup.
          NOTE: If you make the backup server `append-only`, you cannot delete data, including with this option!
          Trying to do so results in an error after making the backup (i.e. the backup still runs).
        '';
      };

      timer-config = mkOption {
        type = with types; nullOr (attrsOf unitOption);
        default = {
          OnCalendar = "daily";
          Persistent = true;
        };
        description = "Config setting backup frequency.";
      };
    };
  });
in {
  options.my.services.backup = with lib; {
    enable = mkEnableOption "Enable backups for this host";
    global-paths = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "/var/lib" "/home" ];
      description = "Paths to backup in each route. WARNING: This backups data to each route, be careful!";
    };
    global-excludes = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "/var/lib/very-large-path" "**/target-temporary builddir *.objectfile" ];
      description = "Paths to exclude from backup. WARNING: This prevents data in each route, be careful!";
    };
    routes = mkOption {
      type = types.attrsOf routeOption;
      default = {};
      example = {
        "route1" = {
          paths = [ "/my/path/1" ];
          repository = "some-repo";
        };
        "route2" = {
          paths = [ "/my/path/1" ];
          repository = "other-repo";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    my.services.backup.global-excludes = let
      normalUsers = builtins.attrNames (lib.filterAttrs (n: v: v.isNormalUser) config.users.users); # NOTE: all normal i.e. user-defined users.
    in lib.flatten [
      (builtins.map (user: "/home/${user}/.ssh/") normalUsers) # Do not store private keys on other hosts.
      config.age.identityPaths # agenix secrets
      (builtins.map (key: [ key.path "${key.path}.pub" ]) config.services.openssh.hostKeys) # for keys in other directories
    ];
    services.restic.backups = let
      global-excludes-file = pkgs.writeText "global_excludes.txt" (builtins.concatStringsSep "\n" cfg.global-excludes );

      mkRoute = name: { ... } @ args: {
        initialize = true; # initializes the repo as well
        environmentFile = args.environment-file; # pass credentials
        passwordFile = args.password-file;
        pruneOpts = args.prune-opts;
        timerConfig = args.timer-config;
        paths = cfg.global-paths ++ args.paths;
        extraBackupArgs = let
          excludes-file = pkgs.writeText "excludes_${name}.txt" (builtins.concatStringsSep "\n" args.exclude);
        in [ "--verbose=2" ] ++ [''--exclude-file=${global-excludes-file} --exclude-file=${excludes-file}''];
        inherit (args) repository;
      };
      mkRoutes = attrs: lib.mapAttrs mkRoute attrs;
    in
      mkRoutes cfg.routes;
  };
}
