{ config, lib, pkgs, ... }: let
  cfg = config.my.services.syncthing;
  base-name = "🐍";
  base-path = "${cfg.data-dir}/${base-name}";
  strong-name = "strong-backup";
  strong-path = "${cfg.data-dir}/${strong-name}";
in {
  options.my.services.syncthing = with lib; {
    sync-dir = mkOption {
      type = with types; str;
      default = "/var/lib/syncthing/data";
      description = "Storage location for synchronised directories";
    };

    cfg-dir = mkOption {
      type = with types; str;
      default = "/var/lib/syncthing/config";
      description = "Config storage location";
    };

    data-dir = mkOption {
      type = with types; str;
      description = "Storage location for our shared folders";
    };

    port = mkOption {
      type = with types; port;
      default = 9534;
      description = "syncthing web-gui port";
    };

    client = {
      enable = mkEnableOption "syncthing configuration";
      server-name = mkOption {
        type = with types; str;
        description = "Name of central server";
      };
      server-id = mkOption {
        type = with types; str;
        description = "syncthing id for the central server";
      };
    };
    server = {
      enable = mkEnableOption "syncthing server (i.e. folder creator)";
      private-keyfile = mkOption {
        type = with types; str;
        description = "Path to file containing secret-key.";
      };
      certfile = mkOption {
        type = with types; str;
        description = "path to file containing cert identifying this node.";
      };
      backup-routes = mkOption {
        type = with types; (listOf str);
        description = "Restic backup routes to use for this data (only backups strong-backup). Only need to do this for 1 server.";
      };
    };
  };

  config = lib.mkIf (cfg.client.enable || cfg.server.enable) (lib.mkMerge [
    {
      services.syncthing = {
        enable = true;

        relay.enable = false;

        dataDir = cfg.sync-dir;
        configDir = cfg.cfg-dir;

        guiAddress = "127.0.0.1:${toString cfg.port}";

        settings = {
          urAccepted = -1; # do not send usage data
          overrideFolders = false; # just keep it lax a bit
          overrideDevices = false; # just keep it lax a bit

          folders = { # when 2 nodes have the same folder name, they just merge.
            "${base-name}" = { # basic files to be shared between the server and clients
              path = base-path;
              devices = builtins.attrNames config.services.syncthing.settings.devices; # i.e. all configured devices above.
            };
            "${strong-name}" = { # files to be shared between servers, clients, and to be backed up using the backup system as well.
              path = strong-path;
              devices = builtins.attrNames config.services.syncthing.settings.devices; # i.e. all configured devices above.
            };
          };
        };
      };
      systemd.tmpfiles.rules = [ "d ${cfg.data-dir} 0770 ${config.users.users.syncthing.name} ${config.users.users.syncthing.group} -" ];
      # just add users to the 'syncthing' group to allow them to read/write without su rights.
      systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true"; # Don't create default ~/Sync folder

      networking.firewall.allowedTCPPorts = [ 22000 ]; # not configurable :(
      networking.firewall.allowedUDPPorts = [ 21027 22000 ]; # not configurable :(
    }
    (lib.mkIf cfg.server.enable {
      services.syncthing = {
        key = cfg.server.private-keyfile;
        cert = cfg.server.certfile;

        settings = {
          devices = {}; # devices will announce themselves to the server
          # overrideFolders = true; # the server decides which folders should exist.
          # overrideDevices = false; # clients sign in on the server.
          gui.insecureSkipHostcheck = true; # we are behind a reverse proxy, so stop checking whether connections come from "127.0.0.1" in the application.
        };
      };

      my.services.nginx.virtualHosts.sync = {
        inherit (cfg) port;
      };

      my.services.backup.routes = (lib.my.toAttrsUniform cfg.server.backup-routes { paths = [ cfg.cfg-dir strong-path ]; });
      my.services.backup.global-excludes = [ cfg.data-dir cfg.sync-dir ];
    })
    (lib.mkIf cfg.client.enable {
      services.syncthing.settings = {
        devices = {
          "${cfg.client.server-name}" = { id = cfg.client.server-id; };
        };
      };
    })
  ]);
}
