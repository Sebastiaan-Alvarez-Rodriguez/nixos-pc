# A simple mailserver, based on https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/
{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.services.mailserver;
in {
  imports = with inputs.self.nixosModules; [ inputs.simple-nixos-mailserver.nixosModule ];

  options.my.services.mailserver = with lib; {
    enable = mkEnableOption "mailserver";
    webserver = {
      enable = mkEnableOption "A web interface for the mailserver";
    };

    domain-prefix = mkOption {
      type = types.str;
      description = "Prefix to add to config.networking.domain for mail routing";
      example = "mail";
    };

    domains = mkOption {
      type = with types; listOf (str);
      description = "Extra domains to process.";
      example = "test.it";
      default = [ config.networking.domain ];
    };

    certificateScheme = mkOption {
      type = types.enum [ "manual" ];
      description = "How to get a certificate for proving mails sent from this domain are legit";
    };
    certificateFile = mkOption {
      type = with types; nullOr (str);
      default = null;
      description = "Where certificate chainfile is stored";
    };
    keyFile = mkOption {
      type = with types; nullOr (str);
      default = null;
      description = "Where certificate keyfile is stored";
    };

    extraConfig = mkOption {
      type = with types; attrs;
      example = "Extra configuration to add to mailserver. See for options: https://nixos-mailserver.readthedocs.io/en/latest/options.html";
      default = {};
      description = "List of session names and commands to execute after-login";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.enable -> builtins.elem 993 config.networking.firewall.allowedTCPPorts;
        message = "Open port `993` in your firewall to allow the mailserver to communicate with clients.";
      }
      {
        assertion = cfg.webserver.enable -> builtins.elem 587 config.networking.firewall.allowedTCPPorts;
        message = "Open port `587` in your firewall to allow the webserver to communicate.";
      }
    ];
    mailserver = (lib.mkMerge [
      {
        enable = true;
        fqdn = "${cfg.domain-prefix}.${config.networking.domain}";
        domains = cfg.domains;

        # Requires certificate files to exist! Currently provided by acme service in global config.
        certificateScheme = cfg.certificateScheme;
        certificateFile = cfg.certificateFile;
        keyFile = cfg.keyFile;
      }
      cfg.extraConfig
    ]);

    services.fail2ban.jails = {
      "postfix-extra" = {
        enabled = true;
        settings = {
          filter = "postfix"; # uses default-available postfix filter (from fail2ban package).
          action = "iptables-allports";
          mode = "extra";
        };
      };
      "postfix-sasl-custom" = {
        enabled = true;
        settings = {
          filter = "postfix-sasl-custom";
          action = "iptables-allports";
          findtime = "2h";
          bantime = "10m";
          bantime-increment = true;
          bantime-maxtime = "5w";
          maxretry = 2;
        };
      };
      "dovecot" = {
        enabled = true;
        settings = {
          filter = "dovecot"; # uses default-available dovecot filter (from fail2ban package).
          action = "iptables-allports";
        };
      };
    };
    environment.etc."fail2ban/filter.d/postfix-sasl-custom.conf".text = ''
      [Definition]
      failregex = ^(.*)\[\d+\]: warning: unknown\[<HOST>\]: SASL (?:LOGIN|PLAIN) authentication failed:.*$
      journalmatch = _SYSTEMD_UNIT=postfix.service _SYSTEMD_UNIT=postfix@-.service
    '';

    services.roundcube = lib.mkIf cfg.webserver.enable { # a webmail server
      enable = true;
      # this is the url of the vhost, not necessarily the same as the fqdn of the mailserver
      hostName = "${cfg.domain-prefix}.${config.networking.domain}";
      extraConfig = ''
        # starttls needed for authentication, so fqdn is required to match the certificate
        $config['smtp_server'] = "tls://${cfg.domain-prefix}.${config.networking.domain}";
        $config['smtp_user'] = "%u";
        $config['smtp_pass'] = "%p";
        $config['smtp_port'] = 587;
      '';
    };

    services.fail2ban.jails."roundcube" = lib.mkIf cfg.webserver.enable {
      enabled = true;
      settings = {
        filter = "roundcube-auth"; # uses default-available dovecot filter by Martin Waschbuesh et al (from fail2ban package).
        action = "iptables-allports";
      };
    };
  };
}
