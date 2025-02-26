# Basic nginx abstraction layer
{ config, lib, pkgs, ... }: let
  cfg = config.my.services.nginx;

  domain = config.networking.domain;

  virtualHostOption = with lib; types.submodule ({ name, ... }: {
    options = {
      enableACME = mkEnableOption "Whether to ask Let’s Encrypt to sign a certificate for this vhost. Alternately, you can use an existing certificate through useACMEHost.";
      useACMEHost = mkOption {
        type = with types; nullOr (str);
        default = domain;
        description = "A host of an existing Let’s Encrypt certificate to use. This is useful if you have many subdomains and want to avoid hitting the rate limit. Alternately, you can generate a certificate through enableACME. Note that this option does not create any certificates, nor it does add subdomains to existing ones – you will need to create them manually using security.acme.certs.";
      };

      subdomain = mkOption {
        type = types.str;
        default = name;
        example = "dev";
        description = "Which subdomain, under config.networking.domain, to use for this virtual host.";
      };

      port = mkOption {
        type = with types; nullOr port;
        default = null;
        example = 8080;
        description = "Which port to proxy to, through 127.0.0.1, for this virtual host.";
      };

      redirect = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "https://example.com";
        description = "Which domain to redirect to (301 response), for this virtual host.";
      };

      root = mkOption {
        type = with types; nullOr path;
        default = null;
        example = "/var/www/blog";
        description = "The root folder for this virtual host.";
      };

      socket = mkOption {
        type = with types; nullOr path;
        default = null;
        example = "FIXME";
        description = "The UNIX socket for this virtual host.";
      };

      sso = {
        enable = mkEnableOption "SSO authentication";
      };

      extraConfig = mkOption {
        type = types.attrs; # FIXME: forward type of virtualHosts
        example = litteralExample ''
          {
            locations."/socket" = {
              proxyPass = "http://127.0.0.1:8096/";
              proxyWebsockets = true;
            };
          }
        '';
        default = { };
        description = "Any extra configuration that should be applied to this virtual host.";
      };
    };
  });
in {
  imports = [ ./sso ];

  options.my.services.nginx = with lib; {
    enable = mkEnableOption "Nginx";

    acme = {
      # credentialsFile = mkOption {
      #   type = types.str;
      #   example = "/var/lib/acme/creds.env";
      #   description = "Gandi API key file as an 'EnvironmentFile' (see `systemd.exec(5)`)";
      # };
      default-mail = mkOption {
        type = types.str;
        example = "a@b.com";
        description = "default mail address for acme certification messages.";
      };

      extra-domains = mkOption {
        type = with types; listOf (str);
        example = [ "mail.domain.com" ];
        default = [];
        description = "Extra domain names to get acme certification for";
      };

      backup-routes = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Restic backup routes to use for this data.";
      };
    };

    monitoring = {
      enable = mkEnableOption "monitoring through grafana and prometheus";
    };

    virtualHosts = mkOption {
      type = types.attrsOf virtualHostOption;
      default = { };
      example = litteralExample ''
        {
          gitea = {
            subdomain = "git";
            port = 8080;
          };
          dev = {
            root = "/var/www/dev";
          };
          jellyfin = {
            port = 8096;
            extraConfig = {
              locations."/socket" = {
                proxyPass = "http://127.0.0.1:8096/";
                proxyWebsockets = true;
              };
            };
          };
        }
      '';
      description = "List of virtual hosts to set-up using default settings.";
    };

    sso = {
      enable = mkEnableOption "Nginx single-sign-on support";
      authKeyFile = mkOption {
        type = types.str;
        example = "/var/lib/nginx-sso/auth-key.txt";
        description = "Path to the auth key.";
      };

      subdomain = mkOption {
        type = types.str;
        default = "login";
        example = "auth";
        description = "Which subdomain to use for SSO.";
      };

      port = mkOption {
        type = types.port;
        default = 8082;
        example = 8080;
        description = "Port to use for internal webui.";
      };

      users = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            passwordHashFile = mkOption {
              type = types.str;
              example = "/var/lib/nginx-sso/alice/password-hash.txt";
              description = "Path to file containing the user's password hash.";
            };
            totpSecretFile = mkOption {
              type = types.str;
              example = "/var/lib/nginx-sso/alice/totp-secret.txt";
              description = "Path to file containing the user's TOTP secret.";
            };
          };
        });
        example = litteralExample ''
          {
            alice = {
              passwordHashFile = "/var/lib/nginx-sso/alice/password-hash.txt";
              totpSecretFile = "/var/lib/nginx-sso/alice/totp-secret.txt";
            };
          }
        '';
        description = "Definition of users";
      };

      groups = mkOption {
        type = with types; attrsOf (listOf str);
        example = litteralExample ''
          {
            root = [ "alice" ];
            users = [ "alice" "bob" ];
          }
        '';
        description = "Groups of users";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [ ]
      ++ (lib.flip lib.mapAttrsToList cfg.virtualHosts (_: { subdomain, ... } @ args: let
        conflicts = [ "port" "root" "socket" "redirect" ];
      in {
        assertion = builtins.length (lib.filter lib.id (builtins.map (v: args.${v} != null && args.${v} != false) conflicts))== 1;
        message = ''Subdomain '${subdomain}' must have exactly one of ${ lib.concatStringsSep ", " (builtins.map (v: "'${v}'") conflicts) } configured. Now: {${ lib.concatStringsSep ", " (builtins.map(v: builtins.toString args.${v}) conflicts) }}'';
      }))
      ++ (lib.flip lib.mapAttrsToList cfg.virtualHosts (_: { subdomain, ... } @ args: let
        conflicts = [ "enableACME" "useACMEHost" ];
      in {
        assertion = builtins.length (lib.filter lib.id (builtins.map (v: args.${v} != null && args.${v} != false) conflicts))== 1;
        message = ''Subdomain '${subdomain}' must have exactly one of ${ lib.concatStringsSep ", " (builtins.map (v: "'${v}'") conflicts) } configured. Now: {${ lib.concatStringsSep ", " (builtins.map(v: builtins.toString args.${v}) conflicts) }}'';
      }))
      ++ (
      let
        ports = lib.my.mapFilter (v: v != null) ({ port, ... }: port) (lib.attrValues cfg.virtualHosts);
        portCounts = lib.my.countValues ports;
        nonUniquesCounts = lib.filterAttrs (_: v: v != 1) portCounts;
        nonUniques = builtins.attrNames nonUniquesCounts;
        mkAssertion = port: {
          assertion = false;
          message = "Port ${port} cannot appear in multiple virtual hosts.";
        };
      in
        map mkAssertion nonUniques
    ) ++ (
      let
        subs = lib.mapAttrsToList (_: { subdomain, ... }: subdomain) cfg.virtualHosts;
        subsCounts = lib.my.countValues subs;
        nonUniquesCounts = lib.filterAttrs (_: v: v != 1) subsCounts;
        nonUniques = builtins.attrNames nonUniquesCounts;
        mkAssertion = v: {
          assertion = false;
          message = "Subdomain '${v}' cannot appear in multiple virtual hosts.";
        };
      in
        map mkAssertion nonUniques
    );

    services.nginx = {
      enable = true;
      statusPage = true; # For monitoring scraping.

      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedZstdSettings = true;

      commonHttpConfig = "server_names_hash_bucket_size 64;";
  
      virtualHosts = let
        domain = config.networking.domain;
        mkVHost = ({ subdomain, ... } @ args: lib.nameValuePair "${subdomain}.${domain}" (lib.my.recursiveMerge [
          # Base configuration
          {
            forceSSL = true;
            useACMEHost = lib.mkIf (args.useACMEHost != null) args.useACMEHost; # use certificate from host (a wildcard domain certificate).
            enableACME = args.enableACME;
          }
          (lib.optionalAttrs (args.port != null) { # Proxy to port
            locations."/".proxyPass =
              "http://127.0.0.1:${toString args.port}";
          })
          (lib.optionalAttrs (args.root != null) { # Serve filesystem content
            inherit (args) root;
          })
          (lib.optionalAttrs (args.socket != null) { # Serve to UNIX socket
            locations."/".proxyPass =
              "http://unix:${args.socket}";
          })
          (lib.optionalAttrs (args.redirect != null) { # Redirect to a different domain
            locations."/".return = "301 ${args.redirect}$request_uri";
          })
          args.extraConfig # VHost specific configuration
          (lib.optionalAttrs args.sso.enable { # SSO configuration
            extraConfig = (args.extraConfig.extraConfig or "") + ''
              error_page 401 = @error401;
            '';

            locations."@error401".return = ''
              302 https://${cfg.sso.subdomain}.${domain}/login?go=$scheme://$http_host$request_uri
            '';

            locations."/" = {
              extraConfig = (args.extraConfig.locations."/".extraConfig or "") + ''
                # Use SSO
                auth_request /sso-auth;

                # Set username through header
                auth_request_set $username $upstream_http_x_username;
                proxy_set_header X-User $username;

                # Renew SSO cookie on request
                auth_request_set $cookie $upstream_http_set_cookie;
                add_header Set-Cookie $cookie;
              '';
            };

            locations."/sso-auth" = {
              proxyPass = "http://localhost:${toString cfg.sso.port}/auth";
              extraConfig = ''
                # Do not allow requests from outside
                internal;

                # Do not forward the request body
                proxy_pass_request_body off;
                proxy_set_header Content-Length "";

                # Set X-Application according to subdomain for matching
                proxy_set_header X-Application "${subdomain}";

                # Set origin URI for matching
                proxy_set_header X-Origin-URI $request_uri;
              '';
            };
          })
        ]));
        generatedHosts = lib.my.genAttrs' (lib.attrValues cfg.virtualHosts) mkVHost;
      in
        (lib.mkMerge [
          { # required to make security.acme.certs.${domain} generate certificates using 'webroot' attribute.
            ${domain} = {
              enableACME = true;
              forceSSL = true;
              useACMEHost = null; # This is the host so we cannot use the host-ACME.
            };
            default = { # default virtualhost, which just shows 404.
              default = true;
              locations."/".return = "404";
            };
          }
          generatedHosts
        ]);

      sso = lib.mkIf cfg.sso.enable {
        enable = true;

        configuration = {
          listen = {
            addr = "127.0.0.1";
            inherit (cfg.sso) port;
          };

          audit_log = {
            target = [ "fd://stdout" ];
            events = [ "access_denied" "login_success" "login_failure" "logout" "validate" ];
            headers = [ "x-origin-uri" "x-application" ];
          };

          cookie = {
            domain = ".${domain}";
            secure = true;
            authentication_key = {
              _secret = cfg.sso.authKeyFile;
            };
          };

          login = {
            title = "Simple SSO";
            default_method = "simple";
            hide_mfa_field = false;
            names = {
              simple = "Username / Password";
            };
          };

          providers = {
            simple = let
              applyUsers = lib.flip lib.mapAttrs cfg.sso.users;
            in {
              users = applyUsers (_: v: { _secret = v.passwordHashFile; });
              mfa = applyUsers (_: v: [{
                provider = "totp";
                attributes = {
                  secret = {
                    _secret = v.totpSecretFile;
                  };
                };
              }]);
              inherit (cfg.sso) groups;
            };
          };

          acl = {
            rule_sets = [
              {
                rules = [{ field = "x-application"; present = true; }];
                allow = [ "@root" ];
              }
            ];
          };
        };
      };
    };

    my.services.nginx.virtualHosts = lib.mkIf cfg.sso.enable {
      ${cfg.sso.subdomain} = {
        inherit (cfg.sso) port;
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    users.users.nginx.extraGroups = [ "acme" ]; # Nginx needs to be able to read the certificates

    security.acme = { # this config fetches a certificate for our domain.
      # NOTE: wildcard domains are only supported using dns validation using lego: https://nixos.org/manual/nixos/stable/index.html#module-security-acme-config-dns
      # Easy if your DNS provider is supported by security.acme.certs.<name>.dnsProvider --> use config below.
      # Otherwise, above link provides selfhosted solution (rfc2136).
      # For now, just request certification for each extra domain name.
      defaults.email = cfg.acme.default-mail;
      acceptTerms = true;
      certs = {
        "${domain}" = {
          email = cfg.acme.default-mail;
          # extraDomainNames = [ "*.${domain}" ]; # Use DNS wildcard certificate
          # dnsProvider = "gandiv5"; # NOTE: dnsProvider option would be nice to use, if my dns provider were supported. For now, use webroot.
          extraDomainNames = cfg.acme.extra-domains ++ (builtins.map (subdomain: "${subdomain}.${domain}") (lib.attrNames config.my.services.nginx.virtualHosts)); # seb: TODO filter in only subdomains using 'domain' as ACMEHost... and add a loop for other named domains
          postRun = "systemctl reload nginx.service";
        };
      };
    };

    services.fail2ban.jails."nginx-bad-request.conf" = {
      enabled = true;
      settings = { filter = "nginx-bad-request"; action = "iptables-allports"; };
    };
    services.fail2ban.jails."nginx-botsearch.conf" = {
      enabled = true;
      settings = { filter = "nginx-botsearch"; action = "iptables-allports"; };
    };
    services.fail2ban.jails."nginx-error-common.conf" = {
      enabled = true;
      settings = { filter = "nginx-error-common"; action = "iptables-allports"; };
    };
    # services.fail2ban.jails."nginx-forbidden.conf" = {
    #   enabled = true;
    #   settings = { filter = "nginx-forbidden"; action = "iptables-allports"; };
    # };
    services.fail2ban.jails."nginx-http-auth.conf" = {
      enabled = true;
      settings = { filter = "nginx-http-auth"; action = "iptables-allports"; };
    };
    services.fail2ban.jails."nginx-limit-req.conf" = {
      enabled = true;
      settings = { filter = "nginx-limit-req"; action = "iptables-allports"; };
    };

    # adds certificates into backup
    my.services.backup = {
      global-excludes = [ "/var/lib/acme/acme-challenge" ]; # challenges rotate frequently, no need to backup either.
      routes = lib.my.toAttrsUniform cfg.acme.backup-routes { paths = lib.mapAttrsToList (_: value: value.directory) config.security.acme.certs; };
    };

    services.grafana.provision.dashboards.settings.providers = lib.mkIf cfg.monitoring.enable [
      {
        name = "NGINX";
        options.path = pkgs.nur.repos.alarsyo.grafanaDashboards.nginx;
        disableDeletion = true;
      }
    ];

    services.prometheus = lib.mkIf cfg.monitoring.enable {
      exporters.nginx = {
        enable = true;
        listenAddress = "127.0.0.1";
      };

      scrapeConfigs = [
        {
          job_name = "nginx";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.nginx.port}" ];
              labels = {
                instance = config.networking.hostName;
              };
            }
          ];
        }
      ];
    };
  };
}
