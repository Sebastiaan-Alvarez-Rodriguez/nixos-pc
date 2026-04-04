{ config, lib, pkgs, ... }: let
  cfg = config.my.services.vaultwarden;
in {
  options.my.services.vaultwarden = with lib; {
    enable = mkEnableOption "vaultwarden configuration";

    port = mkOption {
      type = types.port;
      default = 4567;
      description = "Vaultwarden port";
    };

    mail = {
      enable = mkEnableOption "configure mailserver connection, so vaultwarden can send mails";
      server = mkOption {
        type = types.str;
        description = "mailserver address, e.g. 'smtp.domain.ltd'";
      };
      from = mkOption {
        type = types.str;
        description = "mail-address to be used, e.g. 'vwd@domain.ltd'";
      };
      user = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "mailserver login user (if any), e.g. 'vwd'";
      };
      password-file = mkOption {
        type = with types; nullOr path;
        default = null;
        description = "mailserver login password file (if any), formatted as 'SMTP_PASSWORD=myPasswordIsLonger'";
      };
      security = mkOption {
        type = types.enum [ "starttls" "force_tls" "off"]; # default ports 587, 465, 25
        description = "Authentication type";
      };
      auth-mechanism = mkOption {
        type = with types; nullOr (enum [ "Plain" "Login" ]);
        default = null;
        description = "Explicitly set login type. Should be left alone unless you know what you are doing.";
      };
      port = mkOption {
        type = with types; nullOr port;
        default = null;
        description = "Mailserver login port. Leave empty to use protocol-default port (with protocol definition in `mail.security`)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      config = lib.mkMerge [
        {
          rocketPort = cfg.port;
          domain = "http://127.0.0.1:${toString cfg.port}";
          rocketLog = "critical";
          signupsAllowed = false;
          databaseUrl = "postgresql:///${config.users.users.vaultwarden.name}";
          logLevel = "error";
          extendedLogging = true;
        }

        (lib.mkIf cfg.mail.enable {
          # mail settings
          smtpHost = lib.mkIf (cfg.mail.server != null) cfg.mail.server;
          smtpFrom = cfg.mail.from;
          smtpUsername = lib.mkIf (cfg.mail.user != null) cfg.mail.user;
          smtpSecurity = cfg.mail.security;
          smtpPort = lib.mkIf (cfg.mail.port != null) cfg.mail.port;
          smtpAuthMechanism = lib.mkIf (cfg.mail.auth-mechanism != null) cfg.mail.auth-mechanism;
        })
      ];
      environmentFile = lib.optional (cfg.mail.password-file != null) cfg.mail.password-file;
    };
    my.services.nginx.virtualHosts.vwd = {
      inherit (cfg) port;
    };
    services.fail2ban.jails."vaultwarden" = {
      enabled = true;
      settings = {
        filter = "vaultwarden";
        action = "iptables-allports";
      };
    };

    environment.etc."fail2ban/filter.d/vaultwarden.conf".text = ''
      [Definition]
      failregex = ^.+\[vaultwarden::api::identity\]\[ERROR\] Username or password is incorrect. Try again. IP: (<HOST>).+$
      journalmatch = _SYSTEMD_UNIT=vaultwarden.service
    '';
    
    my.services.postgresql = {
      enable = true;

      # Only allow unix socket authentication for vaultwarden database
      authentication = "local ${config.users.users.vaultwarden.name} ${config.users.users.vaultwarden.name} peer map=vaultwarden_map";
      identMap = "vaultwarden_map ${config.users.users.vaultwarden.name} ${config.users.users.vaultwarden.name}";

      ensureDatabases = [ config.users.users.vaultwarden.name ];
      ensureUsers = [
        {
          inherit (config.users.users.vaultwarden) name;
          ensureDBOwnership = true;
        }
      ];
    };
  };
}
