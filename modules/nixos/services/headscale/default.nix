# Tailscale VPN management software
# open source implementation of tailscale control server (which normally is proprietary)
{ config, lib, ... }: let
  cfg = config.my.services.headscale;
  prefix = "vpn";
in {
  options.my.services.headscale = with lib; {
    enable = mkEnableOption "Headscale VPN service";

    media-path = mkOption {
      type = types.path;
      default = "/data/tandoor";
    };
    port = mkOption {
      type = types.port;
      default = 6192;
      example = 8080;
      description = "Internal port";
    };

    backup-path = mkOption {
      type = with types; nullOr path;
      default = "/data/headscale/backup";
    };
    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
    };
  };

  config = let
    addr = "127.0.0.1"; # reverse nginx proxy to talk to this service
    dbpath = "/var/lib/headscale/db.sqlite";
  in lib.mkIf cfg.enable {
    services.headscale = {
      enable = true;
      address = addr;
      port = cfg.port;
      user = "headscale";
      group = "headscale";

      settings = {
        server_url = "https://${prefix}.${config.networking.domain}";
        listen_addr = "${addr}:${builtins.toString cfg.port}";
  
        ip_prefixes = [ # official CGNAT ranges
          "100.64.0.0/10"
          "fd7a:115c:a1e0::/48"
        ];

        database.type = "sqlite"; # postgres is discouraged sadly
        database.sqlite.path = dbpath;

        # Note: could use magicDNS to make devices in VPN network name-resolvable.
        dns.magic_dns = false;
        dns.override_local_dns = false;
      };
    };

    my.services.nginx.virtualHosts.${prefix} = {
      inherit (cfg) port;

      extraConfig = {
        locations."/".proxyWebsockets = true;
        locations."/".extraConfig = ''
          proxy_set_header True-Client-IP $remote_addr;
          proxy_read_timeout 86400;
          proxy_buffering off;
        '';
      };
    };
    # derp = {
    #   enable = mkEnableOption "Headscale derp server (relay)";
    #   port = mkOption {
    #     type = types.port;
    #     default = 6193;
    #     example = 8081;
    #     description = "Public-facing port for the derp server";
    #   };
    # };

        # derp.server = lib.mkIf cfg.derp.enable {
        #   enable = true;
        #   region_id = 999;
        #   region_code = "home";
        #   region_name = "home";
        #   stun_listen_addr = "0.0.0.0:${cfg.derp.port}"; 
        # };
    my.services.backup.global-excludes = [ dbpath ]; # contains a running sqlite3 database, should be backed up only after halting all potential writes (https://www.sqlite.org/howtocorrupt.html)
    # my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.data-dir ]; };
    my.services.sqlite-backup.items = [{
      name = "headscale";
      src = dbpath;
      dst = cfg.backup-path;
      compression = "zstd";
      compressionLevel = 19;
      mkdirIfNeeded = true;
    }];
  };
}
