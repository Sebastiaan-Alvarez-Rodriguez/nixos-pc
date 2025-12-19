{ config, lib, pkgs, ... }: let
  cfg = config.my.services.syncthing;
  base-name = "🐍";
  base-path = "${cfg.data-dir}/${base-name}";
  strong-name = "strong-backup";
  strong-path = "${cfg.data-dir}/${strong-name}";
in {
  options.my.services.syncthing = with lib; {
    sync-dir = mkOption {
      type = types.str;
      default = "/var/lib/syncthing/data";
      description = "Storage location for synchronised directories";
    };

    cfg-dir = mkOption {
      type = types.str;
      default = "/var/lib/syncthing/config";
      description = "Config storage location";
    };

    data-dir = mkOption {
      type = types.str;
      description = "Storage location for our shared folders";
    };

    port = mkOption {
      type = types.port;
      default = 10534;
      description = "syncthing web-gui port";
    };

    devices = mkOption {
      type = types.attrs;
      description = "device specifications of devices to allow on this peer.";
    };

    client = {
      enable = mkEnableOption "syncthing configuration";
      server-name = mkOption {
        type = types.str;
        description = "Name of central server";
      };
      server-id = mkOption {
        type = types.str;
        description = "syncthing id for the central server";
      };
    };
    server = {
      enable = mkEnableOption "syncthing server (i.e. folder creator)";
      private-keyfile = mkOption {
        type = types.str;
        description = "Path to file containing secret-key.";
      };
      certfile = mkOption {
        type = types.str;
        description = "path to file containing cert identifying this node.";
      };
      backup-routes = mkOption {
        type = with types; listOf str;
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
          devices = cfg.devices; # devices allowed to join the server
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

        overrideFolders = false; # do not delete folders that are not configured here in folders.
        overrideDevices = true; # delete devices that are not configured here in settings.devices
        settings = {
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
      services.syncthing = {
        overrideFolders = false; # do not delete folders that are not specified here: we may get folders from the 'server'
        overrideDevices = false; # do not delete devices that are not specified here: we may get some from the server
      };
    })
  ]);
}
