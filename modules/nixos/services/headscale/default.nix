# Tailscale VPN management software
# open source implementation of tailscale control server (which normally is proprietary)
# also see the docs/vpn!
{ config, lib, ... }: let
  cfg = config.my.services.headscale;
  prefix = "vpn";
  webui-prefix = "vpnc";
in {
  options.my.services.headscale = with lib; {
    enable = mkEnableOption "Headscale VPN service";
    webui = {
      enable = mkEnableOption "Enable 'headplane' webui for headscale";
      port = mkOption {
        type = types.port;
        default = 6193;
        example = 8081;
        description = "Internal port for webui";
      };
      # just generate secure random 32-char string
      cookie-secret-file = mkOption {
        type = types.path;
        description = "32-char string used as initialization for cookie secrets";
      };
      # can be generated using `sudo headscale apikeys create --expiration 100y`
      # This expiration ensures nixos can rebuild this part of the config without resorting to errors due to expired tokens.
      apikey-file = mkOption {
        type = types.path;
        description = "key file for authenticating webui to headscale";
      };
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
    assertions = [
      { assertion = config.my.services.backup.enable; message = "To use backups, `my.services.backup` must be enabled"; }
      { assertion = config.my.services.sqlite-backup.enable; message = "To use backups, `my.services.sqlite-backup` must be enabled"; }
    ];

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

    services.headplane = lib.mkIf cfg.webui.enable {
      # uses unstable headplane (only because of recently added option `api_key_path`)
      enable = true;
      settings = {
        server = {
          host = "127.0.0.1";
          port = cfg.webui.port;
          base_url = "https://${webui-prefix}.${config.networking.domain}";
          cookie_secure = true;
          cookie_secret_path = cfg.webui.cookie-secret-file;
        };
        headscale = {
          url = "https://${prefix}.${config.networking.domain}";
          public_url = "https://${prefix}.${config.networking.domain}";
          api_key_path = cfg.webui.apikey-file;
        };
        integration.proc.enabled = true;
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
    my.services.nginx.virtualHosts.${webui-prefix} = lib.mkIf cfg.webui.enable {
      inherit (cfg.webui) port;
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
    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ ] ++ lib.optional cfg.webui.enable config.services.headplane.settings.server.data_path; };
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
