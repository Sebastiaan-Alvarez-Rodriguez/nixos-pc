{ config, lib, pkgs, ... }: let
  cfg = config.my.services.postgresql;
in {
  options.my.services.postgresql = with lib; {
    enable = mkEnableOption "postgres configuration";

    authentication = mkOption {
      type = types.lines;
      default = "";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/postgresql";
      description = "Path to data directory. Will be created if it does not exist yet.";
    };

    ensureDatabases = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "see options in https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/databases/postgresql.nix";
      example = [ "gitea" "nextcloud" ];
    };

    enableJIT = mkEnableOption "JIT support";

    ensureUsers = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "see options in https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/databases/postgresql.nix";
          };

          ensureDBOwnership = mkOption {
            type = types.bool;
            default = false;
            description = "see options in https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/databases/postgresql.nix";
          };

          ensureClauses = mkOption {
            description = "see options in https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/databases/postgresql.nix";
            example = literalExpression ''
              {
                superuser = true;
                createrole = true;
                createdb = true;
              }
            '';
            default = {};
            defaultText = lib.literalMD ''
              The default, `null`, means that the user created will have the default permissions assigned by PostgreSQL. Subsequent server starts will not set or unset the clause, so imperative changes are preserved.
            '';
            type = types.submodule {
              options = let
                defaultText = lib.literalMD ''
                  `null`: do not set. For newly created roles, use PostgreSQL's default. For existing roles, do not touch this clause.
                '';
              in {
                superuser = mkOption {
                  type = types.nullOr types.bool;
                  default = null;
                  inherit defaultText;
                };
                createrole = mkOption {
                  type = types.nullOr types.bool;
                  default = null;
                  inherit defaultText;
                };
                createdb = mkOption {
                  type = types.nullOr types.bool;
                  default = null;
                  inherit defaultText;
                };
                "inherit" = mkOption {
                  type = types.nullOr types.bool;
                  default = null;
                  inherit defaultText;
                };
                login = mkOption {
                  type = types.nullOr types.bool;
                  default = null;
                  inherit defaultText;
                };
                replication = mkOption {
                  type = types.nullOr types.bool;
                  default = null;
                  inherit defaultText;
                };
                bypassrls = mkOption {
                  type = types.nullOr types.bool;
                  default = null;
                  inherit defaultText;
                };
              };
            };
          };
        };
      });
      default = [];
      description = "see options in https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/databases/postgresql.nix";
      example = literalExpression ''
        [
          {
            name = "nextcloud";
          }
          {
            name = "superuser";
            ensureDBOwnership = true;
          }
        ]
      '';
    };

    identMap = mkOption {
      type = types.lines;
      default = "";
      example = ''
        map-name-0 system-username-0 database-username-0
        map-name-1 system-username-1 database-username-1
      '';
      description = ''
        Defines the mapping from system users to database users.

        See the [auth doc](https://postgresql.org/docs/current/auth-username-maps.html).
      '';
    };

    package = mkOption {
      type = with types; package;
      default = pkgs.postgresql_13;
      description = "Postgresql package to use";
    };

    upgradeScript = mkEnableOption "postgres upgrade script";
  };

  config = let
    finalData = if cfg.dataDir != null then "${cfg.dataDir}/${cfg.package.psqlSchema}" else null;
  in lib.mkMerge [
    (lib.mkIf cfg.enable {
      my.services.postgresql.ensureUsers = [{ # adds a root user which is superuser and may access all tables. Access this user by being root and typing `psql -U root -d <some-db>` (e.g. with `postgres` as the db).
        name = "root";
        ensureClauses = {
          superuser = true;
          createrole = true;
          createdb = true;
        };
      }];

      services.postgresql = {
        enable = true;
        inherit (cfg) package dataDir;
        inherit (cfg) authentication enableJIT ensureDatabases ensureUsers identMap;
      };
      systemd.tmpfiles.rules = [ "d ${cfg.dataDir} 0700 ${config.users.users.postgres.name} ${config.users.users.postgres.group} -" ];
    })

    (lib.mkIf config.my.services.backup.enable {
      my.services.backup.global-excludes = [ cfg.dataDir ]; # should not backup live database.
    })

    (lib.mkIf cfg.upgradeScript { # Taken from the manual
      environment.systemPackages = let
        pgCfg = config.services.postgresql;

        oldPackage = if pgCfg.enableJIT then pgCfg.package.withJIT else pgCfg.package;
        oldData = pgCfg.dataDir;
        oldBin = "${if pgCfg.extraPlugins == [] then oldPackage else oldPackage.withPackages pgCfg.extraPlugins}/bin";

        newPackage = if cfg.enableJIT then cfg.package.withJIT else cfg.package;
        newData = cfg.dataDir;
        newBin = "${if pgCfg.extraPlugins == [] then newPackage else newPackage.withPackages pgCfg.extraPlugins}/bin";
      in [
        (pkgs.writeScriptBin "upgrade-pg-cluster" ''
          #!/usr/bin/env bash

          set -eux
          export OLDDATA="${oldData}"
          export NEWDATA="${newData}"
          export OLDBIN="${oldBin}"
          export NEWBIN="${newBin}"

          if [ "$OLDDATA" -ef "$NEWDATA" ]; then
            echo "Cannot migrate to same data directory" >&2
            exit 1
          fi

          install -d -m 0700 -o postgres -g postgres "$NEWDATA"
          cd "$NEWDATA"
          sudo -u postgres "$NEWBIN/initdb" -D "$NEWDATA"

          systemctl stop postgresql    # old one

          sudo -u postgres "$NEWBIN/pg_upgrade" \
            --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
            --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
            "$@"

          cat << EOF
            Run the following commands after setting:
            services.postgresql.package = pkgs.postgresql_${lib.versions.major newPackage.version}
                sudo -u postgres vacuumdb --all --analyze-in-stages
                ${newData}/delete_old_cluster.sh
          EOF
        '')
      ];
    })
  ];
}
