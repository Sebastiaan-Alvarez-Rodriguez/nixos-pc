{ config, lib, pkgs, ... }: let
  cfg = config.my.services.syncthing;
  base-name = "🐍";
  base-path = "${cfg.data-dir}/${base-name}";
  strong-name = "strong-backup";
  strong-path = "${cfg.data-dir}/${strong-name}";
in {
  options.my.services.syncthing = with lib; {
    enable = mkEnableOption "syncthing configuration";

    sync-dir = mkOption {
      type = with types; str;
      default = "/data/syncthing/data";
      description = "Storage location for synchronised directories";
    };

    cfg-dir = mkOption {
      type = with types; str;
      default = "/data/syncthing/config";
      description = "Config storage location";
    };

    data-dir = mkOption {
      type = with types; str;
      default = "/data/storage/syncthing";
      description = "Storage location for our shared folders";
    };

    private-keyfile = mkOption {
      type = types.str;
      description = "path to file containing secret-key.";
    };
    certfile = mkOption {
      type = types.str;
      description = "path to file containing cert identifying this node.";
    };

    port = mkOption {
      type = with types; port;
      default = 9534;
      description = "syncthing web-gui port";
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data (only backups strong-backup).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;

      relay.enable = false;
      dataDir = cfg.sync-dir;
      configDir = cfg.cfg-dir;
      guiAddress = "127.0.0.1:${toString cfg.port}";

      key = cfg.private-keyfile;
      cert = cfg.certfile;

      settings = {
        gui.insecureSkipHostcheck = true;
        devices = { # the IDs are not secret at all, src: https://forum.syncthing.net/t/should-i-keep-my-node-ids-as-secret-as-possible/230
          "rdn-phone" = { id = "NABS66G-LYDPC6H-QWVOGEX-YGMA7NS-HTDHYNH-RYKPW67-7QVK4XY-RAP7MQM"; };
        };
        folders = {
          "${base-name}" = { # basic files to be shared between the server and clients
            path = base-path;
            devices = builtins.attrNames config.services.syncthing.settings.devices; # i.e. all configured devices above.
          };
          "${strong-name}" = { # files to be shared between servers, clients, and to be backed up using the backup system as well.
            path = strong-path;
            devices = builtins.attrNames config.services.syncthing.settings.devices; # i.e. all configured devices above.
          };
        };
        urAccepted = -1; # do not send usage data
      };
    };
    systemd.tmpfiles.rules = [ "d ${cfg.data-dir} 0700 ${config.users.users.syncthing.name} ${config.users.users.syncthing.group} -" ];
    systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true"; # Don't create default ~/Sync folder

    networking.firewall.allowedTCPPorts = [ 22000 ]; # not configurable :(
    networking.firewall.allowedUDPPorts = [ 21027 22000 ]; # not configurable :(

    my.services.nginx.virtualHosts.sync = {
      inherit (cfg) port;
    };

    my.services.backup.routes = (lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.cfg-dir strong-path ]; });
    my.services.backup.global-excludes = [ cfg.data-dir cfg.sync-dir strong-path ];

    # services.fail2ban.jails."syncthing" = {
    #   enabled = true;
    #   settings = {
    #     filter = "syncthing";
    #     action = "iptables-allports";
    #   };
    # };

    # environment.etc."fail2ban/filter.d/syncthing.conf".text = ''
    #   [Definition]
    #   failregex = ^.+\[syncthing::api::identity\]\[ERROR\] Username or password is incorrect. Try again. IP: (<HOST>).+$
    #   journalmatch = _SYSTEMD_UNIT=syncthing.service
    # '';
    # TODO: Syncthing detection
  };
}
