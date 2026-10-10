# a lightweight server webdav (file share/editing over http), caldav (calendar share/editing), and carddav (contact share).
{ config, lib, pkgs, ... }: let
  cfg = config.my.services.radicale;
  prefix = "radicale";
in {
  options.my.services.radicale = with lib; {
    enable = mkEnableOption "radicale configuration";

    package = mkOption {
      type = types.package;
      default = pkgs.radicale;
      description = "Package to use";
    };

    data-dir = mkOption {
      type = types.str;
      description = "Storage location for data";
    };

    userpassfile = mkOption {
      type = types.str;
      description = "Path to htpasswd file with users and their passwords. In the file, each line must look like 'user:pass\n'. Use `htpasswd -nB <user>` to create.";
    };

    port = mkOption {
      type = types.port;
      default = 10161;
      description = "radicale port";
    };

    backup-routes = mkOption {
      type = with types; (listOf str);
      description = "Restic backup routes to use for this data (only backups strong-backup). Only need to do this for 1 server.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.radicale = {
      enable = true;
      settings = {
        server.hosts = [ "127.0.0.1:${builtins.toString cfg.port}" ]; # only listen local, use reverse nginx proxy
        auth = {
          type = "htpasswd";
          htpasswd_filename = cfg.userpassfile;
          htpasswd_encryption = "autodetect";
        };

        # rights = { # seb TODO: rights needed for shared cal?
        #   root = {
        #     user = 
        #   }
        # }
        storage.filesystem_folder = cfg.data-dir;
      };
    };
    my.services.nginx.virtualHosts.${prefix} = {
      inherit (cfg) port;
      useACMEHost = config.networking.domain;
      extraConfig.locations."/".extraConfig = ''
        proxy_pass_header Authorization;
      '';
    };

    # create directories
    systemd.tmpfiles.rules = let
    in [ "d ${cfg.data-dir} 0700 radicale radicale -" ];

    # add to backup
    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes {
      paths = [ cfg.data-dir ];
    };


    # services.fail2ban.jails."radicale" = {
    #   enabled = true;
    #   settings = {
    #     filter = "radicale";
    #     action = "iptables-allports";
    #   };
    # };

    # environment.etc."fail2ban/filter.d/radicale.conf".text = ''
    #   [Definition]
    #   failregex = ^.+\[radicale::api::identity\]\[ERROR\] Username or password is incorrect. Try again. IP: (<HOST>).+$
    #   journalmatch = _SYSTEMD_UNIT=radicale.service
    # '';
    
  };
}
