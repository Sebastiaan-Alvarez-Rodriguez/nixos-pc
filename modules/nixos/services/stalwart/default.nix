# A more advanced mailserver, with calDAV, cardDAV and integrated RSVP support (so calendars, contacts, and replying yes/no/maybe to events)
{ config, inputs, system, lib, pkgs, ... }: let
  cfg = config.my.services.stalwart;
in {
  options.my.services.stalwart = with lib; {
    enable = mkEnableOption "stalwart mailserver";
    webserver = {
      enable = mkEnableOption "A web interface for stalwart mailserver";
      port = mkOption {
        type = types.port;
        default = 8080;
        description = "Internal port";
      };
    };

    domain-prefix = mkOption {
      type = types.str;
      description = "Prefix to add to config.networking.domain for mail routing";
      example = "mail";
    };

    # TODO: verify how to create passwords 
    admin-password = mkOption {
      type = types.str;
      description = "Path to htpasswd file with admin password. The contents must look like 'user:pass'. Use `htpasswd -nB <user>` to create.";
    };
    dkim-key = mkOption {
      type = types.str;
      description = "Path to htpasswd file with dkim key. The contents must look like 'key'. Use `htpasswd -nB <user>` to create.";
    };

    useACMEHost = mkOption {
      type = types.str;
      example = "my.place";
      description = "The ACME hostname to use certificates from (see also `https://nixos-mailserver.readthedocs.io/en/nixos-26.05/options.html#cmdoption-arg-mailserver.x509.useACMEHost`)";
    };

    extraConfig = mkOption {
      type = with types; attrs;
      example = "Extra configuration to add to mailserver. See for options: https://nixos-mailserver.readthedocs.io/en/latest/options.html";
      default = {};
      description = "List of session names and commands to execute after-login";
    };

    state-version = mkOption {
      type = types.int;
      description = "Stateversion of mailserver. See also: https://nixos-mailserver.readthedocs.io/en/latest/migrations.html";
      example = 1;
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.enable -> builtins.elem 993 config.networking.firewall.allowedTCPPorts;
        message = "Open port `993` in your firewall to allow IMAP communication with clients.";
      }
      {
        assertion = cfg.webserver.enable -> builtins.elem 587 config.networking.firewall.allowedTCPPorts;
        message = "Open port `587` in your firewall to allow mail submissions to the mailserver with STARTTLS.";
      }
      {
        assertion = cfg.webserver.enable -> builtins.elem 465 config.networking.firewall.allowedTCPPorts;
        message = "Open port `465` in your firewall to allow mail submissions to the mailserver with implicit TLS";
      }
    ];
    services.stalwart = (lib.mkMerge [
      {
        enable = true;
        stateVersion = cfg.state-version;
        credentials = {
          admin_pass = cfg.admin-password;
          dkim_key = cfg.dkim-key;
        };

        settings = {
          server = {
            hostname = "${cfg.domain-prefix}.${config.networking.domain}";
            listener.smtp = { bind = [ "[::]:25" ]; protocol = "smtp"; };
            # enable port 465 for SMTP with TLS in wrapper-mode
            listener.submissions = lib.optionalAttrs cfg.webserver.enable { bind = [ "[::]:465" ]; protocol = "smtp"; tls.implicit = true; };
            # enable port 587 for SMTP with STARTTLS
            listener.submission = lib.optionalAttrs cfg.webserver.enable { bind = [ "[::]:587" ]; protocol = "smtp"; };
            listener.imaps = { bind = [ "[::]:993" ]; protocol = "imap"; tls.implicit = true; };

            http = { # for Admin API, calDAV, cardDAV, JMAP etc.
              bind = [ "127.0.0.1:${cfg.webserver.port}" ];
              protocol = "http";
            };
          };
          certificate."mijn-place" = let
            acmeDir = config.security.acme.certs."mijn.place".directory;
          in {
            # TODO: give read permisssion
            # paths are just like with simple-nixos-mailserver: https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/blob/main/mail-server/common.nix?ref_type=heads#L26
            cert = "%{file:${acmeDir}/fullchain.pem}%";
            private-key = "%{file:${acmeDir}/key.pem}%";
            default = true;
          };
          storage = { data = "postgresql"; blob = "postgresql"; fts = "postgresql"; lookup = "postgresql"; };
          store."postgresql" = {
            type = "postgresql";
            host = "/run/postgresql";
            database = "stalwart";
            user = "stalwart";
          };
          # note: This should not be required
          # authentication.fallback-admin = {
          #   user = "admin";
          #   secret = "%{file:/run/credentials/stalwart.service/admin-pw}%";
          # };
        };
      }
      cfg.extraConfig
    ]);

    # give stalwart permission to read /var/lib/acme/<domain> certs
    # TODO: is this needed?
    # users.users.stalwart.extraGroups = [ "acme" ];

    my.services.nginx.acme.extra-domains = lib.mkIf cfg.webserver.enable [ "${cfg.domain-prefix}.${config.networking.domain}" ];
    my.services.nginx.virtualHosts.${cfg.domain-prefix} = {
      useACMEHost = "mijn.place";
      extraConfig = { # Roundcube at /, CalDAV/JMAP endpoints go to Stalwart
        locations."~ ^/(\\.well-known/(caldav|carddav|jmap)|dav|jmap|api)" = {
          proxyPass = "http://127.0.0.1:${cfg.webserver.port}";
        };
      };
    };

    services.roundcube = lib.mkIf cfg.webserver.enable { # a webmail server
      enable = true;
      # this is the url of the vhost, not necessarily the same as the fqdn of the mailserver
      hostName = "${cfg.domain-prefix}.${config.networking.domain}";
      extraConfig = ''
        # starttls needed for authentication, so fqdn is required to match the certificate
        $config['smtp_server'] = "tls://${cfg.domain-prefix}.${config.networking.domain}";
        $config['smtp_user'] = "%u";
        $config['smtp_pass'] = "%p";
        $config['imap_host'] = "ssl://${cfg.domain-prefix}.${config.networking.domain}:993";
      '';
    };
    # seb TODO: check usability of jails with new server.
    # services.fail2ban.jails = {
    #   "postfix-extra" = {
    #     enabled = true;
    #     settings = {
    #       filter = "postfix"; # uses default-available postfix filter (from fail2ban package).
    #       action = "iptables-allports";
    #       mode = "extra";
    #     };
    #   };
    #   "postfix-sasl-custom" = {
    #     enabled = true;
    #     settings = {
    #       filter = "postfix-sasl-custom";
    #       action = "iptables-allports";
    #       findtime = "2h";
    #       bantime = "10m";
    #       bantime-increment = true;
    #       bantime-maxtime = "5w";
    #       maxretry = 2;
    #     };
    #   };
    #   "dovecot" = {
    #     enabled = true;
    #     settings = {
    #       filter = "dovecot"; # uses default-available dovecot filter (from fail2ban package).
    #       action = "iptables-allports";
    #     };
    #   };
    # };
    # environment.etc."fail2ban/filter.d/postfix-sasl-custom.conf".text = ''
    #   [Definition]
    #   failregex = ^(.*)\[\d+\]: warning: unknown\[<HOST>\]: SASL (?:LOGIN|PLAIN) authentication failed:.*$
    #   journalmatch = _SYSTEMD_UNIT=postfix.service _SYSTEMD_UNIT=postfix@-.service
    # '';

    services.fail2ban.jails."roundcube" = lib.mkIf cfg.webserver.enable {
      enabled = true;
      settings = {
        filter = "roundcube-auth"; # uses default-available dovecot filter by Martin Waschbuesh et al (from fail2ban package).
        action = "iptables-allports";
      };
    };
    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ config.mailserver.storage.path config.mailserver.dkim.keyDirectory ]; };
  };
}
