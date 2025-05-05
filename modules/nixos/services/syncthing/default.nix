{ config, lib, pkgs, ... }: let
  cfg = config.my.services.syncthing;
in {
  options.my.services.syncthing = with lib; {
    enable = mkEnableOption "syncthing configuration";

    data-dir = mkOption {
      type = with types; str;
      default = "/data/storage/syncthing";
      description = "Data storage location";
    };
    cfg-dir = mkOption {
      type = with types; str;
      default = "/data/syncthing";
      description = "Config storage location";
    };

    port = mkOption {
      type = with types; port;
      default = 9534;
      description = "syncthing web-gui port";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;

      relay.enable = false;
      urAccepted = -1; # do not send usage data
      dataDir = cfg.data-dir;
      cfgDir = cf.cfg-dir;
      guiAddress = "127.0.0.1:${cfg.port}";

      # key = 
      # cert = 

      folders = {
        base = ;
      }


      
      dbBackend = "postgresql";
      config = rec {
        rocketPort = cfg.port;
        domain = "http://127.0.0.1:${toString rocketPort}";
        rocketLog = "critical";
        signupsAllowed = false;
        databaseUrl = "postgresql:///${config.users.users.syncthing.name}";
        logLevel = "error";
        extendedLogging = true;
      };
    };
    my.services.nginx.virtualHosts.sync = {
      inherit (cfg) port;
    };
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
