{ config, lib, pkgs, ... }: with lib; let
  cfg = config.my.services.sqlite-backup;

  createBackupService = item: let
    compressSuffixes = {
      "none" = "";
      "gzip" = ".gz";
      "zstd" = ".zstd";
    };
    compressSuffix = getAttr item.compression compressSuffixes;

    mkSqlPath = prefix: suffix: "${item.dst}/${item.name}${prefix}.sqlite${suffix}";
    curFile = mkSqlPath "" compressSuffix;
    prevFile = mkSqlPath ".prev" compressSuffix;
    prevFiles = map (mkSqlPath ".prev") (attrValues compressSuffixes);
    inProgressDumpFile = mkSqlPath ".in-progress" "";
    inProgressCompressFile = mkSqlPath ".in-progress" compressSuffix;

    dumpCmd = ''sqlite3 ${item.src} ".backup '${inProgressDumpFile}'"'';
    compressCmd = getAttr item.compression {
      "none" = "cat ${inProgressDumpFile}";
      "gzip" = "${pkgs.gzip}/bin/gzip -c -${toString item.compressionLevel} --rsyncable ${inProgressDumpFile}";
      "zstd" = "${pkgs.zstd}/bin/zstd -c -${toString item.compressionLevel} --rsyncable ${inProgressDumpFile}";
    };

  in {
    enable = true;
    description = "Backup of ${item.name} database";
    path = [ pkgs.coreutils pkgs.sqlite ];

    script = ''
      set -e -o pipefail

      umask 0077 # ensure backup is only readable by root user

      if [ -e ${curFile} ]; then
        rm -f ${toString prevFiles}
        mv ${curFile} ${prevFile}
      fi

      ${dumpCmd} # dumps file
      ${compressCmd} > ${inProgressCompressFile} # creates compressed file

      rm ${inProgressDumpFile}
      mv ${inProgressCompressFile} ${curFile}
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };

    startAt = cfg.startAt;
  };
in {
  options.my.services.sqlite-backup = {
    enable = mkEnableOption "sqlite dumps";

    startAt = mkOption {
      default = "*-*-* 01:15:00";
      type = with types; either (listOf str) str;
      description = ''
        This option defines (see `systemd.time` for format) when the
        databases should be dumped.
        The default is to update at 01:15 (at night) every day.
      '';
    };

    items = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name for backup service (created as `sqlite-backup-<name>`)";
          };

          src = mkOption {
            type = types.str;
            description = "Source path file";
          };

          dst = mkOption {
            type = types.str;
            description = "Destination path (directory). The backup file will be inserted as <name>.sqlite[.compressionextension]";
          };

          compression = mkOption {
            type = types.enum ["none" "gzip" "zstd"];
            default = "gzip";
            description = "The type of compression to use on the generated database dump.";
          };

          compressionLevel = mkOption {
            type = types.ints.between 1 19;
            default = 6;
            description = "The compression level used when compression is enabled. gzip accepts levels 1 to 9. zstd accepts levels 1 to 19.";
          };

          mkdirIfNeeded = mkOption {
            type = types.bool;
            default = false;
            description = "Make directory path if it does not exist yet. Already existing destinations keep their user/group. Created directories will be root-owned.";
          };
        };
      });
    };
  };

  config = mkMerge [
    {
      assertions = [] ++ lib.map (item: {
        assertion = lib.all item.compression == "none" ||
          (item.compression == "gzip" && item.compressionLevel >= 1 && item.compressionLevel <= 9) ||
          (item.compression == "zstd" && item.compressionLevel >= 1 && item.compressionLevel <= 19);
        message = "config.services.sqlite-backup.compressionLevel must be set between 1 and 9 for gzip and 1 and 19 for zstd";
      }) cfg.items;
    }

    (mkIf cfg.enable {
      systemd.tmpfiles.rules = let
        filterfunc = item: item.mkdirIfNeeded;
        dstfunc = item: "d '${item.dst}' 0700 :root - - -";
      in
        lib.map dstfunc (builtins.filter filterfunc cfg.items);
    })

    {
      systemd.services = listToAttrs (map (item: {
        name = "sqlite-backup-${item.name}";
        value = createBackupService item;
      }) cfg.items);
    }
  ];
}
