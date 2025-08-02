{ config, lib, pkgs, ... }: let
  cfg = config.my.services.webdav;
in {
  options.my.services.webdav = with lib; {
    enable = mkEnableOption "webdav configuration";

    data-dir = mkOption {
      type = with types; str;
      description = "Storage location for our shared folders";
    };

    port = mkOption {
      type = with types; port;
      default = 10159;
      description = "webdav port";
    };

    backup-routes = mkOption {
      type = with types; (listOf str);
      description = "Restic backup routes to use for this data (only backups strong-backup). Only need to do this for 1 server.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.webdav = {
      enable = true;
      settings = {
        address = "127.0.0.1";
        port = cfg.port;
        behindProxy = true;
        modify = true;
        auth = true;

        # defaults (used if users do not override these values)
        directory = "${cfg.data-dir}/default"; # default directory when user does not have its own directory set.
        permissions = "";
        users = [
          { username = "rdn"; password = "WhyNowTemp"; directory = "${cfg.data-dir}/rdn"; permissions = "CRUD"; } # seb TODO: make this secure someday.
        ];
      };
    };
    my.services.nginx.virtualHosts = {
      dav = {
        inherit (cfg) port;
      };
    };
    # create directories
    systemd.tmpfiles.rules = let
      mkrule = user: username: "d ${cfg.data-dir}/${username} 0777 webdav webdav -";
      user-rules = builtins.map (user: mkrule user.name) cfg.users;
    in [ "d ${cfg.data-dir} 0777 webdav webdav -" ] + user-rules;

    # add to backup
    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes {
      paths = [ cfg.data-dir ];
    };


    services.fail2ban.jails."webdav" = {
      enabled = true;
      settings = {
        filter = "webdav";
        action = "iptables-allports";
      };
    };

    environment.etc."fail2ban/filter.d/webdav.conf".text = ''
      [Definition]
      failregex = ^.+\[webdav::api::identity\]\[ERROR\] Username or password is incorrect. Try again. IP: (<HOST>).+$
      journalmatch = _SYSTEMD_UNIT=webdav.service
    '';
    
  };
}
