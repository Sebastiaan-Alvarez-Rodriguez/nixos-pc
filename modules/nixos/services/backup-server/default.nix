# Backup server using restic's rest server. NOTE: Backup data from clients using 'backup' service.
{ config, pkgs, lib, ... }: let
  cfg = config.my.services.backup-server;
  excludeArg = with builtins; with pkgs; "--exclude-file=" + (writeText "excludes.txt" (concatStringsSep "\n" cfg.exclude));
in {
  options.my.services.backup = with lib; {
    enable = mkEnableOption "Enable backups for this host";

    data-dir = mkOption {
      type = types.str;
      description = "data storage location (NOTE: data is encrypted at client-side, no chance to read it here)";
    };

    access = mkOption {
      type = with types; attrsOf (str);
      description = ''
        access credentials to the backup service as `<username> = <plaintext-password>`.
        NOTE: the passwords can be stored plain... They don't add any real security.
      '';
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
