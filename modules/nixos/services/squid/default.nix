# squid HTTP forward proxy
# see: https://github.com/rustdesk/rustdesk/discussions/984

# this document provides the right way ahead: https://github.com/rustdesk/rustdesk/wiki/Set-up-http-proxy-server
{ config, lib, pkgs, ... }: let
  cfg = config.my.services.squid;
in {
  options.my.services.squid = with lib; {
    enable = mkEnableOption "squid http proxy";

    package = mkOption {
      type = types.package;
      default = pkgs.squid;
      description = "Package for squid";
    };

    listen-address = mkOption {
      type = types.str;
      example = "127.0.0.1/24";
      description = "Listen address interface to listen on";
    };

    port = mkOption {
      type = types.port;
      default = 1182;
      description = "TCP port to listen on.";
    };

    auth = {
      files = mkOption {
        type = with types; listOf str;
        description = "paths to files containing users and hashed passwords. Use `htpasswd -n <username>` to generate file contents.";
      };

      threads = mkOption {
        type = types.int;
        default = 1;
        description = "amount of threads for auth process. Determines the amount of concurrent auth requests that can be handled. If more auth requests than threads are present, they will be queued.";
      };

      realm = mkOption {
        type = types.str;
        default = "nothing-to-see-here";
        description = "Realm name to display to clients";
      };
    };

    allowed-ports = mkOption {
      type = with types; listOf port;
      default = [ 443 ];
      description = "List of allowed ports. Any connection not coming in on one of these ports is dropped. Note: the provided portnumbers are not opened on the firewall. You do that.";
    };

    allowed-hosts = mkOption {
      type = with types; listOf str;
      example = litteralExample ''[ config.networking.domain "www.google.com" ]'';
      description = "List of allowed hosts. Any connection not having this host as destination is dropped. Careful with subdomains. e.g. 'google.com' reroutes to 'www.google.com'. You need to allow the 'www.'-subdomain in this example.";
    };

    extra-config = mkOption {
      type = types.lines;
      default = "";
      description = "Extra config for squid.";
    };
  };

  config = lib.mkIf cfg.enable {
   services.squid = {
     enable = true;
     proxyAddress = cfg.listen-address;
     proxyPort = cfg.port;
     configText = let
       auth-params = lib.concatLines (builtins.map (file: "auth_param basic program ${cfg.package}/libexec/basic_ncsa_auth ${file}") cfg.auth.files);
       allowed-ports = lib.concatLines (builtins.map (port: "acl allowed_ports port ${builtins.toString port}") cfg.allowed-ports);
       allowed-dst-hosts = lib.concatLines (builtins.map (domain: "acl allowed_dst_hosts dstdomain ${domain}") cfg.allowed-hosts);
       # auth tips from: https://www.shaunos.com/squid-username-password-configuration/
     in ''
      # Use Apache's basic_ncsa_auth helper to validate credentials (uses htpasswd)
      # Use `htpasswd -c passFile username`
      ${auth-params}
      # amount of threads for basic auth
      auth_param basic children ${builtins.toString cfg.auth.threads}
      # Define the authentication realm shown to clients
      auth_param basic realm ${cfg.auth.realm}

      # Define an ACL that matches only if the client has successfully authenticated
      acl authenticated proxy_auth REQUIRED

      # Match requests targeting this specific hostname
      ${allowed-dst-hosts}

      # Match requests targeting this IP address
      # acl rustdesk_ip dst 127.0.0.1/32

      # Match requests to a given port
      ${allowed-ports}

      # Match incoming connections from local network
      acl localnet src 192.168.0.0/24

      # Match HTTP CONNECT method (used for tunneling)
      acl CONNECT method CONNECT

      # Deny CONNECT requests to ports not explicitly allowed
      http_access deny CONNECT !allowed_ports

      # Deny any traffic going to localhost. This protects all services behind nginx reverse proxy.
      http_access deny to_localhost

      # allows access to local network clients (debug) # TODO remove
      # http_access allow localnet

      # Allow authenticated users to access the allowed dst hostnames
      http_access allow authenticated allowed_dst_hosts

      # Allow authenticated users to access the RustDesk IP
      # http_access allow authenticated rustdesk_ip


      # Application logs to syslog, access and store logs have specific files
      cache_log       stdio:/var/log/squid/cache.log
      access_log      stdio:/var/log/squid/access.log
      cache_store_log stdio:/var/log/squid/store.log

      # Required by systemd service
      pid_filename    /run/squid.pid

      # Run as user and group squid
      cache_effective_user squid squid

      #
      # INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
      #
      ${cfg.extra-config}

      # Deny everything else by default
      http_access deny all

      # set listen address and port
      http_port ${
        lib.optionalString (cfg.listen-address != null) "${cfg.listen-address}:"
      }${toString cfg.port}

      # set coredump directory
      coredump_dir /var/cache/squid

      # how many seconds to wait before shutting down this server. Allows last queued requests to be processed
      shutdown_lifetime 1 seconds
    '';
     validateConfig = true;
    };
  };
}
